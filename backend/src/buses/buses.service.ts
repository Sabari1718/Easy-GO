import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';
import { haversineDistance } from '../common/utils/geo.utils';

export interface BusScheduleItem {
  id: string;
  routeId: string;
  busNumber: string;
  departureTime: string;
  arrivalTime: string;
  daysOfWeek: string[];
  status: string; // 'SCHEDULED' | 'LIVE_NOW' | 'COMPLETED'
  isLive: boolean;
  currentStop?: string;
  nextStop?: string;
  etaMinutes?: number;
}

@Injectable()
export class BusesService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async findAll() {
    return this.prisma.bus.findMany({
      include: {
        route: true,
        tracker: {
          select: { deviceId: true, status: true, lastSeenAt: true },
        },
      },
    });
  }

  async findOne(id: string) {
    const bus = await this.prisma.bus.findUnique({
      where: { id },
      include: {
        route: {
          include: { stops: { include: { stop: true }, orderBy: { sequence: 'asc' } } },
        },
        tracker: {
          select: { deviceId: true, status: true, lastSeenAt: true },
        },
      },
    });

    if (!bus) throw new NotFoundException(`Bus ${id} not found`);

    const liveState = await this.trackingService.getLiveBusState(id);

    return { ...bus, liveState };
  }

  async getLiveState(id: string) {
    const cleanNumber = id.replace(/^bus_/i, '').replace(/^bus-/i, '');
    let bus: any = null;

    try {
      bus = await this.prisma.bus.findFirst({
        where: {
          OR: [
            { id },
            { busNumber: id },
            { busNumber: cleanNumber },
            { busNumber: cleanNumber.toUpperCase() },
          ],
        },
        include: { route: { select: { name: true, source: true, destination: true } } },
      });
    } catch {}

    const liveState = await this.trackingService.getLiveBusState(bus?.id || id);

    if (!liveState || liveState.status === 'OFFLINE' || liveState.locationStatus === 'OFFLINE') {
      const lastUpdate = liveState?.lastUpdated ? new Date(liveState.lastUpdated).getTime() : 0;
      const secondsSinceUpdate = lastUpdate ? Math.max(0, Math.round((Date.now() - lastUpdate) / 1000)) : 999999;
      return {
        busId: bus?.id || id,
        busNumber: bus?.busNumber || cleanNumber.toUpperCase(),
        route: bus?.route || { name: 'Route not available' },
        status: 'OFFLINE',
        locationStatus: 'OFFLINE',
        message: 'No live GPS data currently active for this bus',
        lastUpdatedAt: liveState?.lastUpdated || null,
        secondsSinceUpdate,
        trackerOnline: false,
      };
    }

    const totalDist = liveState.totalRouteDistanceKm > 0 ? liveState.totalRouteDistanceKm : 42.5;
    const estStops = Math.max(1, Math.round((liveState.distanceRemainingKm / totalDist) * 7));

    return {
      busId: liveState.busId,
      busNumber: liveState.busNumber,
      status: liveState.status === 'STOPPED_AT_STOP' || liveState.status === 'MOVING' || liveState.status === 'APPROACHING_STOP' ? 'LIVE' : liveState.status,
      locationStatus: liveState.locationStatus || 'LIVE',
      route: { name: liveState.routeName },
      latitude: liveState.latitude,
      longitude: liveState.longitude,
      speed: liveState.speed,
      heading: liveState.heading,
      currentStop: liveState.currentStopName,
      nextStop: liveState.nextStopName,
      distanceToNextStop: liveState.distanceToNextStop,
      distanceTravelledKm: liveState.distanceTravelledKm,
      distanceRemainingKm: liveState.distanceRemainingKm,
      stopsRemaining: estStops,
      etaMinutes: liveState.etaMinutes,
      progressPercentage: liveState.progressPercentage,
      lastUpdatedAt: liveState.lastUpdated,
      lastUpdated: liveState.lastUpdated,
      secondsSinceUpdate: liveState.secondsSinceUpdate ?? 0,
      trackerOnline: liveState.trackerOnline ?? true,
    };
  }

  async getSchedule(id: string) {
    const bus = await this.prisma.bus.findUnique({
      where: { id },
      include: {
        route: {
          include: {
            stops: { include: { stop: true }, orderBy: { sequence: 'asc' } },
          },
        },
      },
    });

    if (!bus) throw new NotFoundException(`Bus ${id} not found`);

    const liveState = await this.trackingService.getLiveBusState(id);
    const isLive = liveState !== null && liveState.status !== 'OFFLINE';

    // Standard schedule time slots
    const standardSlots = [
      { dep: '06:30 AM', arr: '07:45 AM' },
      { dep: '08:00 AM', arr: '09:15 AM' },
      { dep: '09:30 AM', arr: '10:45 AM' },
      { dep: '11:00 AM', arr: '12:15 PM' },
      { dep: '01:30 PM', arr: '02:45 PM' },
      { dep: '03:15 PM', arr: '04:30 PM' },
      { dep: '05:00 PM', arr: '06:15 PM' },
      { dep: '06:45 PM', arr: '08:00 PM' },
      { dep: '08:30 PM', arr: '09:45 PM' },
    ];

    const schedules: BusScheduleItem[] = standardSlots.map((slot, index) => {
      const isCurrentLiveSlot = isLive && index === 2; // e.g. slot currently on route
      return {
        id: `sched_${bus.id}_${index + 1}`,
        routeId: bus.routeId,
        busNumber: bus.busNumber,
        departureTime: slot.dep,
        arrivalTime: slot.arr,
        daysOfWeek: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        status: isCurrentLiveSlot ? 'LIVE_NOW' : 'SCHEDULED',
        isLive: isCurrentLiveSlot,
        currentStop: isCurrentLiveSlot ? liveState?.currentStopName : undefined,
        nextStop: isCurrentLiveSlot ? liveState?.nextStopName : undefined,
        etaMinutes: isCurrentLiveSlot ? liveState?.etaMinutes : (index + 1) * 20,
      };
    });

    return {
      busId: bus.id,
      busNumber: bus.busNumber,
      route: {
        id: bus.route.id,
        name: bus.route.name,
        source: bus.route.source,
        destination: bus.route.destination,
        estimatedDurationMinutes: bus.route.estimatedDurationMinutes,
      },
      isLiveNow: isLive,
      currentLiveStatus: isLive ? liveState : null,
      schedules,
    };
  }

  async findNearbyBuses(latitude: number, longitude: number, radiusKm = 10) {
    const allStates = await this.trackingService.getAllActiveBusStates();
    const results: any[] = [];
    const seenBuses = new Set<string>();

    // 1. Process all live buses currently in Redis
    for (const live of allStates) {
      if (live.status === 'OFFLINE') continue;
      const distKm = Math.round(haversineDistance(latitude, longitude, live.latitude, live.longitude) * 100) / 100;
      if (distKm <= radiusKm) {
        seenBuses.add(live.busId);
        seenBuses.add(live.busNumber);
        results.push({
          busId: live.busId,
          busNumber: live.busNumber,
          routeId: live.routeId || 'r12a',
          routeName: live.routeName || `Route ${live.busNumber}`,
          origin: live.routeName?.split('→')[0]?.trim() || 'Origin',
          destination: live.routeName?.split('→')[1]?.trim() || 'Destination',
          distanceKm: distKm,
          etaMinutes: live.etaMinutes ?? Math.max(2, Math.round(distKm * 2.5)),
          isLive: true,
          status: 'LIVE',
          latitude: live.latitude,
          longitude: live.longitude,
          speed: live.speed,
          heading: live.heading,
          currentStop: live.currentStopName,
          nextStop: live.nextStopName,
          lastUpdated: live.lastUpdated,
        });
      }
    }

    // 2. Also check scheduled DB buses if not already included
    try {
      const dbBuses = await this.prisma.bus.findMany({ where: { status: 'ACTIVE' } });
      for (const b of dbBuses) {
        if (seenBuses.has(b.id) || seenBuses.has(b.busNumber)) continue;
        results.push({
          busId: b.id,
          busNumber: b.busNumber,
          routeId: b.routeId,
          routeName: `Route ${b.busNumber}`,
          origin: 'Origin',
          destination: 'Destination',
          distanceKm: 2.5,
          etaMinutes: 12,
          isLive: false,
          status: 'SCHEDULED',
        });
      }
    } catch {}

    results.sort((a, b) => a.distanceKm - b.distanceKm);
    return results;
  }
}
