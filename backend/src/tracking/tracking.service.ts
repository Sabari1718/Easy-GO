import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../redis/redis.service';
import { StopEngineService } from './stop-engine.service';
import { RouteProgressService } from './route-progress.service';
import { EtaService } from './eta.service';
import { BusLiveState, BusRealtimeStatus, GpsUpdate, StopInfo } from '../common/interfaces/bus-live-state.interface';

@Injectable()
export class TrackingService {
  private readonly logger = new Logger(TrackingService.name);
  private readonly REDIS_BUS_PREFIX = 'bus:live:';
  private readonly OFFLINE_THRESHOLD_MS = 60000;

  // In-memory cache of sequence indexes for active buses
  private busSequenceIndexes = new Map<string, number>();
  private busPointIndexes = new Map<string, number>();

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private stopEngine: StopEngineService,
    private routeProgress: RouteProgressService,
    private etaService: EtaService,
  ) {}

  /**
   * Process a GPS update from a tracker device.
   * This is the core pipeline: GPS → Analysis → Redis → PostgreSQL
   */
  async processGpsUpdate(update: GpsUpdate): Promise<BusLiveState | null> {
    const trackerId = update.trackerId || update.deviceId;
    let tracker: any = null;

    // 1. Try finding tracker by trackerId or deviceId
    if (trackerId) {
      try {
        tracker = await this.prisma.busTracker.findFirst({
          where: {
            OR: [
              { trackerId: String(trackerId) },
              { deviceId: String(trackerId) },
              { id: String(trackerId) },
            ],
          },
          include: { bus: { include: { route: true } } },
        });
      } catch (e) {
        this.logger.warn(`Error querying busTracker: ${e.message}`);
      }

      // Check tracker active status
      if (tracker && (tracker.isActive === false || tracker.status === 'INACTIVE' || tracker.status === 'LOST')) {
        throw new ForbiddenException(`Tracker device '${trackerId}' is inactive or suspended.`);
      }

      // Check cross-bus protection: tracker cannot send for another bus
      if (tracker && tracker.bus && update.busId) {
        const reqBusClean = update.busId.replace(/^bus_/i, '').replace(/^bus-/i, '').toUpperCase();
        const actualBusClean = tracker.bus.busNumber.replace(/^bus_/i, '').replace(/^bus-/i, '').toUpperCase();
        if (update.busId !== tracker.bus.id && reqBusClean !== actualBusClean) {
          throw new ForbiddenException(
            `Tracker '${trackerId}' is assigned to Bus ${tracker.bus.busNumber}, cannot send data for ${update.busId}`,
          );
        }
      }
    }

    // 2. If tracker not found by deviceId, try finding by busId or busNumber
    if ((!tracker || !tracker.bus) && update.busId) {
      try {
        const cleanBusNumber = update.busId.replace(/^bus_/i, '').replace(/^bus-/i, '');
        const bus = await this.prisma.bus.findFirst({
          where: {
            OR: [
              { id: update.busId },
              { busNumber: update.busId },
              { busNumber: cleanBusNumber },
              { busNumber: cleanBusNumber.toUpperCase() },
            ],
          },
          include: { tracker: true, route: true },
        });

        if (bus && bus.route) {
          tracker = {
            id: bus.tracker?.id || 'trk-' + bus.id,
            deviceId: bus.tracker?.deviceId || trackerId || 'TRK-' + bus.busNumber,
            bus,
          };
        }
      } catch (e) {
        this.logger.warn(`Error querying bus by busId: ${e.message}`);
      }
    }

    // 3. If still no tracker/bus in DB, provide fallback for dev/simulator for 12A & 21
    if (!tracker || !tracker.bus) {
      const busNum = (update.busId || trackerId || '12A').replace(/^bus_/i, '').toUpperCase();
      this.logger.log(`Using mock route association for unregistered bus: ${busNum}`);
      const mockRouteName = busNum.includes('21') || busNum.includes('24')
        ? 'Route 24 - Pollachi → Coimbatore'
        : 'Route 12A - Ukkadam → Pollachi';
      
      const liveState: BusLiveState = {
        busId: update.busId || `BUS_${busNum}`,
        tripId: `trip_${busNum.toLowerCase()}`,
        busNumber: busNum,
        routeId: busNum.includes('21') || busNum.includes('24') ? 'r24' : 'r12a',
        routeName: mockRouteName,
        latitude: update.latitude,
        longitude: update.longitude,
        speed: update.speed,
        heading: update.heading,
        currentStopId: 'stop_1',
        currentStopName: 'Madukkarai',
        nextStopId: 'stop_2',
        nextStopName: 'Ettimadai',
        distanceToNextStop: 1.8,
        distanceTravelledKm: 14.5,
        distanceRemainingKm: 28.0,
        totalRouteDistanceKm: 42.5,
        etaMinutes: Math.max(1, Math.round((28.0 / (update.speed > 10 ? update.speed : 30)) * 60)),
        progressPercentage: 35.0,
        status: update.speed < 2 ? BusRealtimeStatus.STOPPED_AT_STOP : BusRealtimeStatus.MOVING,
        lastUpdated: update.timestamp || new Date().toISOString(),
        locationStatus: 'LIVE',
        secondsSinceUpdate: 0,
        trackerOnline: true,
      };

      // Save in Redis / memory
      await this.redis.setJson(`${this.REDIS_BUS_PREFIX}${liveState.busId}`, liveState, 300);
      await this.redis.setJson(`${this.REDIS_BUS_PREFIX}${liveState.busNumber}`, liveState, 300);

      return liveState;
    }

    const bus = tracker.bus;
    let route = bus.route;
    if (!route && bus.routeId) {
      try {
        route = await this.prisma.route.findUnique({ where: { id: bus.routeId } });
      } catch {}
    }
    if (!route) {
      route = {
        id: bus.routeId || 'r12a',
        name: bus.busNumber.includes('21') ? 'Route 24 - Pollachi → Coimbatore' : 'Route 12A - Ukkadam → Pollachi',
        distanceKm: bus.busNumber.includes('21') ? 40.2 : 43.5,
      };
    }

    // 2. Update tracker last seen
    try {
      if (tracker.id && !tracker.id.startsWith('trk-')) {
        await this.prisma.busTracker.update({
          where: { id: tracker.id },
          data: { lastSeenAt: new Date() },
        });
      }
    } catch {}

    // 3. Find active trip
    let trip: any = null;
    try {
      trip = await this.prisma.trip.findFirst({
        where: { busId: bus.id, status: 'RUNNING' },
      });

      if (!trip) {
        trip = await this.prisma.trip.create({
          data: {
            busId: bus.id,
            routeId: route.id,
            status: 'RUNNING',
            startedAt: new Date(),
          },
        });
        this.logger.log(`Auto-started trip for bus ${bus.busNumber}`);
      }
    } catch {}

    // 4. Save location history to PostgreSQL
    try {
      await this.prisma.busLocation.create({
        data: {
          busId: bus.id,
          tripId: trip?.id || null,
          latitude: update.latitude,
          longitude: update.longitude,
          speed: update.speed,
          heading: update.heading,
          accuracy: update.accuracy ?? 5,
          timestamp: new Date(update.timestamp),
        },
      });
    } catch {}

    // 5. Get route stops
    let routeStops: any[] = [];
    try {
      routeStops = await this.prisma.routeStop.findMany({
        where: { routeId: route.id },
        include: { stop: true },
        orderBy: { sequence: 'asc' },
      });
    } catch {}

    const stops: StopInfo[] = routeStops.map((rs) => ({
      stopId: rs.stop?.id || rs.stopId,
      name: rs.stop?.name || rs.name || 'Stop',
      latitude: rs.stop?.latitude ?? rs.latitude ?? 0,
      longitude: rs.stop?.longitude ?? rs.longitude ?? 0,
      sequence: rs.sequence,
      distanceFromStartKm: rs.distanceFromStartKm || 0,
      estimatedMinutesFromPreviousStop: rs.estimatedMinutesFromPreviousStop || 0,
    }));

    // 6. Determine current stop / next stop
    const seqIdx = this.busSequenceIndexes.get(bus.id) || 0;
    const stopResult = this.stopEngine.determineStops(
      update.latitude,
      update.longitude,
      stops,
      seqIdx,
    );
    this.busSequenceIndexes.set(bus.id, stopResult.currentSequenceIndex);

    // 7. Calculate route progress
    const routeGeometry = route.routeGeometry as any[];
    const ptIdx = this.busPointIndexes.get(bus.id) || 0;
    const progressResult = this.routeProgress.calculateProgress(
      update.latitude,
      update.longitude,
      routeGeometry,
      ptIdx,
    );
    this.busPointIndexes.set(bus.id, progressResult.nearestPointIndex);

    // 8. Remaining stops count
    const remainingStops = Math.max(0, stops.length - stopResult.currentSequenceIndex - 1);

    // 9. Calculate ETA
    const etaMinutes = this.etaService.calculateEta(
      progressResult.distanceRemainingKm,
      update.speed,
      stopResult.isAtStop,
      remainingStops,
    );

    // 10. Determine bus status
    const status = this.determineBusStatus(
      update.speed,
      stopResult.isAtStop,
      stopResult.isApproaching,
      progressResult.progressPercentage,
    );

    // 11. Build live state
    const liveState: BusLiveState = {
      busId: bus.id,
      tripId: trip.id,
      busNumber: bus.busNumber,
      routeId: route.id,
      routeName: route.name,
      latitude: update.latitude,
      longitude: update.longitude,
      speed: update.speed,
      heading: update.heading,
      currentStopId: stopResult.currentStopId,
      currentStopName: stopResult.currentStopName,
      nextStopId: stopResult.nextStopId,
      nextStopName: stopResult.nextStopName,
      distanceToNextStop: Math.round(stopResult.distanceToNextStop * 100) / 100,
      distanceTravelledKm: progressResult.distanceTravelledKm,
      distanceRemainingKm: progressResult.distanceRemainingKm,
      totalRouteDistanceKm: route.distanceKm,
      etaMinutes,
      progressPercentage: progressResult.progressPercentage,
      status,
      lastUpdated: new Date().toISOString(),
      locationStatus: 'LIVE',
      secondsSinceUpdate: 0,
      trackerOnline: true,
    };

    // 12. Update Redis live state
    await this.redis.setJson(
      `${this.REDIS_BUS_PREFIX}${bus.id}`,
      liveState,
      300, // 5 min TTL
    );

    this.logger.log(
      `🚌 Bus ${bus.busNumber}: ${status} @ (${update.latitude.toFixed(4)}, ${update.longitude.toFixed(4)}) → ${stopResult.nextStopName} in ${etaMinutes}min`,
    );

    // 13. Handle trip completion
    if (progressResult.progressPercentage >= 99) {
      await this.completeTrip(bus.id, trip.id);
    }

    return liveState;
  }

  private determineBusStatus(
    speed: number,
    isAtStop: boolean,
    isApproaching: boolean,
    progress: number,
  ): BusRealtimeStatus {
    if (progress >= 99) return BusRealtimeStatus.COMPLETED;
    if (isAtStop && speed < 2) return BusRealtimeStatus.STOPPED_AT_STOP;
    if (isApproaching) return BusRealtimeStatus.APPROACHING_STOP;
    if (speed >= 2) return BusRealtimeStatus.MOVING;
    return BusRealtimeStatus.NOT_STARTED;
  }

  private async completeTrip(busId: string, tripId: string) {
    await this.prisma.trip.update({
      where: { id: tripId },
      data: { status: 'COMPLETED', completedAt: new Date() },
    });
    this.busSequenceIndexes.delete(busId);
    this.busPointIndexes.delete(busId);
    this.logger.log(`Trip ${tripId} completed for bus ${busId}`);
  }

  async getLiveBusState(busId: string): Promise<BusLiveState | null> {
    let state = await this.redis.getJson<BusLiveState>(`${this.REDIS_BUS_PREFIX}${busId}`);

    if (!state) {
      const clean = busId.replace(/^bus_/i, '').replace(/^bus-/i, '');
      state = await this.redis.getJson<BusLiveState>(`${this.REDIS_BUS_PREFIX}${clean}`);
      if (!state) {
        state = await this.redis.getJson<BusLiveState>(`${this.REDIS_BUS_PREFIX}BUS_${clean.toUpperCase()}`);
      }
      if (!state) {
        state = await this.redis.getJson<BusLiveState>(`${this.REDIS_BUS_PREFIX}${clean.toUpperCase()}`);
      }
    }

    if (!state) {
      // Search active states for matching busNumber or id
      const all = await this.getAllActiveBusStates();
      state = all.find(
        (s) =>
          s.busId.toLowerCase() === busId.toLowerCase() ||
          s.busNumber.toLowerCase() === busId.toLowerCase() ||
          s.busNumber.toLowerCase() === busId.replace(/^bus_/i, '').toLowerCase(),
      ) || null;
    }

    if (state) {
      const lastUpdate = new Date(state.lastUpdated).getTime();
      const secondsSinceUpdate = Math.max(0, Math.round((Date.now() - lastUpdate) / 1000));
      state.secondsSinceUpdate = secondsSinceUpdate;

      if (secondsSinceUpdate <= 15) {
        state.locationStatus = 'LIVE';
        state.trackerOnline = true;
      } else if (secondsSinceUpdate <= 60) {
        state.locationStatus = 'RECENT';
        state.trackerOnline = true;
      } else if (secondsSinceUpdate <= 300) {
        state.locationStatus = 'STALE';
        state.trackerOnline = false;
        state.status = BusRealtimeStatus.OFFLINE;
      } else {
        state.locationStatus = 'OFFLINE';
        state.trackerOnline = false;
        state.status = BusRealtimeStatus.OFFLINE;
      }
    }
    return state;
  }

  async getAllActiveBusStates(): Promise<BusLiveState[]> {
    const keys = await this.redis.keys(`${this.REDIS_BUS_PREFIX}*`);
    const states: BusLiveState[] = [];
    const seen = new Set<string>();

    for (const key of keys) {
      const state = await this.redis.getJson<BusLiveState>(key);
      if (state && !seen.has(state.busId)) {
        seen.add(state.busId);
        const lastUpdate = new Date(state.lastUpdated).getTime();
        const secondsSinceUpdate = Math.max(0, Math.round((Date.now() - lastUpdate) / 1000));
        state.secondsSinceUpdate = secondsSinceUpdate;

        if (secondsSinceUpdate <= 15) {
          state.locationStatus = 'LIVE';
          state.trackerOnline = true;
        } else if (secondsSinceUpdate <= 60) {
          state.locationStatus = 'RECENT';
          state.trackerOnline = true;
        } else if (secondsSinceUpdate <= 300) {
          state.locationStatus = 'STALE';
          state.trackerOnline = false;
          state.status = BusRealtimeStatus.OFFLINE;
        } else {
          state.locationStatus = 'OFFLINE';
          state.trackerOnline = false;
          state.status = BusRealtimeStatus.OFFLINE;
        }

        states.push(state);
      }
    }
    return states;
  }

  resetBusSequence(busId: string) {
    this.busSequenceIndexes.delete(busId);
    this.busPointIndexes.delete(busId);
  }
}
