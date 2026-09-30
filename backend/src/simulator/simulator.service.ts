import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../database/prisma.service';
import { GpsService } from '../gps/gps.service';
import { calculateBearing, haversineDistance, interpolatePoint } from '../common/utils/geo.utils';

interface SimulatedBus {
  deviceId: string;
  busId: string;
  busNumber: string;
  routePoints: Array<{ lat: number; lng: number }>;
  currentPointIndex: number;
  progress: number; // 0.0 to 1.0 between currentPointIndex and next
  speedKmh: number;
  isAtStop: boolean;
  dwellCountdown: number; // seconds remaining at stop
  stopIndices: number[]; // route point indices near stops
  active: boolean;
  paused: boolean;
}

const DEFAULT_ROUTE_12A = [
  { lat: 10.9601, lng: 76.9502 }, // Ukkadam
  { lat: 10.9558, lng: 76.9471 },
  { lat: 10.9467, lng: 76.9421 },
  { lat: 10.9362, lng: 76.9375 }, // Sundakkamuthur
  { lat: 10.9256, lng: 76.9330 },
  { lat: 10.9095, lng: 76.9261 },
  { lat: 10.8952, lng: 76.9192 }, // Madukkarai
  { lat: 10.8810, lng: 76.9120 },
  { lat: 10.8618, lng: 76.9015 }, // Ettimadai
  { lat: 10.8420, lng: 76.8901 }, // Karpagam
  { lat: 10.8164, lng: 76.8749 }, // Kinathukadavu
  { lat: 10.7844, lng: 76.8550 },
  { lat: 10.7450, lng: 76.8291 },
  { lat: 10.6970, lng: 76.7950 }, // Pollachi
];

const DEFAULT_ROUTE_21 = [
  { lat: 10.6970, lng: 76.7950 }, // Pollachi
  { lat: 10.7210, lng: 76.8128 },
  { lat: 10.7605, lng: 76.8400 }, // Kinathukadavu
  { lat: 10.8191, lng: 76.8768 }, // Karpagam
  { lat: 10.8521, lng: 76.8957 }, // Ettimadai
  { lat: 10.8941, lng: 76.9180 }, // Madukkarai
  { lat: 10.9262, lng: 76.9338 }, // Sundakkamuthur
  { lat: 10.9592, lng: 76.9485 }, // Gandhipuram
  { lat: 10.9710, lng: 76.9536 }, // Coimbatore Junction
];

@Injectable()
export class SimulatorService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SimulatorService.name);
  private buses = new Map<string, SimulatedBus>();
  private intervalHandle: NodeJS.Timer | null = null;
  private isRunning = false;

  private readonly INTERVAL_MS: number;
  private BASE_SPEED_KMPH = 35;
  private readonly STOP_DWELL_SECONDS = 18;

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
    private gpsService: GpsService,
  ) {
    this.INTERVAL_MS = this.configService.get<number>('SIMULATOR_INTERVAL_MS', 3000);
  }

  async onModuleInit() {
    const enabled = this.configService.get<string>('SIMULATOR_ENABLED', 'true');
    if (enabled === 'true') {
      await this.initializeBuses();
      this.start();
    }
  }

  onModuleDestroy() {
    this.stop();
  }

  private async initializeBuses() {
    try {
      // Get all active buses that have trackers
      const trackers = await this.prisma.busTracker.findMany({
        where: { status: 'ACTIVE' },
        include: {
          bus: {
            include: {
              route: { select: { id: true, name: true, routeGeometry: true } },
            },
          },
        },
      });

      for (const tracker of trackers) {
        if (!tracker.bus || !tracker.bus.route) continue;

        const routeGeometry = tracker.bus.route.routeGeometry as any[];
        if (!routeGeometry || routeGeometry.length < 2) continue;

        // Find stop indices in route geometry
        const routeStops = await this.prisma.routeStop.findMany({
          where: { routeId: tracker.bus.routeId },
          include: { stop: true },
          orderBy: { sequence: 'asc' },
        });

        const stopIndices = routeStops.map((rs) => {
          let minDist = Infinity;
          let nearestIdx = 0;
          routeGeometry.forEach((pt, idx) => {
            const d = haversineDistance(rs.stop.latitude, rs.stop.longitude, pt.lat, pt.lng);
            if (d < minDist) {
              minDist = d;
              nearestIdx = idx;
            }
          });
          return nearestIdx;
        });

        const startOffset = Math.floor(Math.random() * Math.floor(routeGeometry.length * 0.5));

        this.buses.set(tracker.deviceId, {
          deviceId: tracker.deviceId,
          busId: tracker.bus.id,
          busNumber: tracker.bus.busNumber,
          routePoints: routeGeometry,
          currentPointIndex: startOffset,
          progress: 0,
          speedKmh: this.BASE_SPEED_KMPH + (Math.random() * 10 - 5),
          isAtStop: false,
          dwellCountdown: 0,
          stopIndices,
          active: true,
          paused: false,
        });

        this.logger.log(
          `🚌 Simulator initialized bus ${tracker.bus.busNumber} (${tracker.deviceId}) starting at point ${startOffset}/${routeGeometry.length}`,
        );
      }
    } catch (e) {
      this.logger.warn(`Simulator DB query failed: ${e.message}`);
    }

    // Ensure BUS_12A is present
    if (!this.buses.has('TRK001') && !Array.from(this.buses.values()).some((b) => b.busNumber === '12A')) {
      this.buses.set('TRK001', {
        deviceId: 'TRK001',
        busId: 'BUS_12A',
        busNumber: '12A',
        routePoints: DEFAULT_ROUTE_12A,
        currentPointIndex: 4, // Near Madukkarai
        progress: 0.2,
        speedKmh: this.BASE_SPEED_KMPH,
        isAtStop: false,
        dwellCountdown: 0,
        stopIndices: [0, 3, 6, 8, 9, 10, 13],
        active: true,
        paused: false,
      });
      this.logger.log('🚌 Simulator added default BUS_12A (Ukkadam → Pollachi)');
    }

    // Ensure BUS_21 is present
    if (!this.buses.has('TRK002') && !Array.from(this.buses.values()).some((b) => b.busNumber === '21')) {
      this.buses.set('TRK002', {
        deviceId: 'TRK002',
        busId: 'BUS_21',
        busNumber: '21',
        routePoints: DEFAULT_ROUTE_21,
        currentPointIndex: 2, // Near Kinathukadavu
        progress: 0.1,
        speedKmh: this.BASE_SPEED_KMPH,
        isAtStop: false,
        dwellCountdown: 0,
        stopIndices: [0, 2, 3, 4, 5, 6, 7, 8],
        active: true,
        paused: false,
      });
      this.logger.log('🚌 Simulator added default BUS_21 (Pollachi → Coimbatore)');
    }

    this.logger.log(`✅ Simulator ready with ${this.buses.size} buses`);
  }

  start() {
    if (this.isRunning) return;
    this.isRunning = true;
    this.intervalHandle = setInterval(() => this.tick(), this.INTERVAL_MS);
    this.logger.log(`▶️  GPS Simulator started (interval: ${this.INTERVAL_MS}ms)`);
  }

  stop() {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle as any);
      this.intervalHandle = null;
    }
    this.isRunning = false;
    this.logger.log('⏹️  GPS Simulator stopped');
  }

  pause() {
    this.buses.forEach((bus) => (bus.paused = true));
    this.logger.log('⏸️  GPS Simulator paused');
  }

  resume() {
    this.buses.forEach((bus) => (bus.paused = false));
    this.logger.log('▶️  GPS Simulator resumed');
  }

  async reset() {
    this.stop();
    this.buses.clear();
    await this.initializeBuses();
    this.start();
    this.logger.log('🔄 GPS Simulator reset');
  }

  private async tick() {
    for (const [deviceId, bus] of this.buses) {
      if (!bus.active || bus.paused) continue;
      await this.moveBus(bus);
    }
  }

  private async moveBus(bus: SimulatedBus) {
    const points = bus.routePoints;
    const intervalSec = this.INTERVAL_MS / 1000;

    // Handle dwell at stop
    if (bus.isAtStop) {
      bus.dwellCountdown -= intervalSec;
      if (bus.dwellCountdown <= 0) {
        bus.isAtStop = false;
        bus.currentPointIndex = Math.min(bus.currentPointIndex + 1, points.length - 1);
        this.logger.log(`🚌 Bus ${bus.busNumber} departed stop`);
      }
      // Send location with speed 0 while at stop
      const pt = points[bus.currentPointIndex];
      await this.sendGpsUpdate(bus, pt.lat, pt.lng, 0, 0);
      return;
    }

    // Check if at last point → reset to beginning (loop)
    if (bus.currentPointIndex >= points.length - 1) {
      this.logger.log(`🏁 Bus ${bus.busNumber} completed route, resetting`);
      bus.currentPointIndex = 0;
      bus.progress = 0;
      
      // Mark current trip as completed and create new one
      await this.prisma.trip.updateMany({
        where: { busId: bus.busId, status: 'RUNNING' },
        data: { status: 'COMPLETED', completedAt: new Date() },
      });
      return;
    }

    const current = points[bus.currentPointIndex];
    const next = points[bus.currentPointIndex + 1];

    // Distance from current to next point in km
    const segmentDist = haversineDistance(current.lat, current.lng, next.lat, next.lng);

    // How much to advance per interval
    const distancePerInterval = (bus.speedKmh / 3600) * intervalSec; // km per interval
    const progressStep = segmentDist > 0 ? distancePerInterval / segmentDist : 1;

    bus.progress += progressStep;

    let lat: number;
    let lng: number;
    let heading: number;

    if (bus.progress >= 1.0) {
      // Advance to next point
      bus.currentPointIndex++;
      bus.progress = 0;

      if (bus.currentPointIndex >= points.length) {
        bus.currentPointIndex = points.length - 1;
      }

      lat = points[bus.currentPointIndex].lat;
      lng = points[bus.currentPointIndex].lng;
      heading = bus.currentPointIndex > 0
        ? calculateBearing(
            points[bus.currentPointIndex - 1].lat,
            points[bus.currentPointIndex - 1].lng,
            lat,
            lng,
          )
        : 0;

      // Check if this is a stop point
      const isStopPoint = bus.stopIndices.some(
        (idx) => Math.abs(idx - bus.currentPointIndex) <= 2,
      );

      if (isStopPoint && bus.currentPointIndex < points.length - 2) {
        bus.isAtStop = true;
        bus.dwellCountdown = this.STOP_DWELL_SECONDS;
        this.logger.log(`🛑 Bus ${bus.busNumber} stopped at route point ${bus.currentPointIndex}`);
      }
    } else {
      // Interpolate between current and next
      const interpolated = interpolatePoint(current.lat, current.lng, next.lat, next.lng, bus.progress);
      lat = interpolated.lat;
      lng = interpolated.lng;
      heading = calculateBearing(current.lat, current.lng, next.lat, next.lng);
    }

    // Add slight speed variation
    const speed = bus.isAtStop ? 0 : bus.speedKmh + (Math.random() * 6 - 3);

    await this.sendGpsUpdate(bus, lat, lng, Math.max(0, speed), heading);
  }

  private async sendGpsUpdate(
    bus: SimulatedBus,
    lat: number,
    lng: number,
    speed: number,
    heading: number,
  ) {
    try {
      await this.gpsService.processLocation({
        deviceId: bus.deviceId,
        trackerId: bus.deviceId,
        busId: bus.busId,
        latitude: lat,
        longitude: lng,
        speed,
        heading,
        accuracy: 5,
        timestamp: new Date().toISOString(),
      });
    } catch (e) {
      this.logger.warn(`Simulator GPS send failed for ${bus.busNumber}: ${e.message}`);
    }
  }

  setSpeed(speedKmh: number) {
    this.BASE_SPEED_KMPH = speedKmh;
    this.buses.forEach((bus) => (bus.speedKmh = speedKmh));
    this.logger.log(`⚙️ Simulator speed set to ${speedKmh} km/h for all buses`);
  }

  setBusPaused(busId: string, paused: boolean): boolean {
    const clean = busId.replace(/^bus_/i, '').toUpperCase();
    for (const bus of this.buses.values()) {
      if (
        bus.busId.toLowerCase() === busId.toLowerCase() ||
        bus.busNumber.toUpperCase() === clean ||
        bus.deviceId.toLowerCase() === busId.toLowerCase()
      ) {
        bus.paused = paused;
        this.logger.log(`Bus ${bus.busNumber} paused state set to: ${paused}`);
        return true;
      }
    }
    return false;
  }

  getStatus() {
    const busStatuses = Array.from(this.buses.values()).map((b) => ({
      deviceId: b.deviceId,
      busId: b.busId,
      busNumber: b.busNumber,
      active: b.active,
      paused: b.paused,
      speedKmh: Math.round(b.speedKmh),
      currentPointIndex: b.currentPointIndex,
      totalPoints: b.routePoints.length,
      progress: `${((b.currentPointIndex / b.routePoints.length) * 100).toFixed(1)}%`,
      isAtStop: b.isAtStop,
      dwellCountdown: b.dwellCountdown,
    }));

    return {
      isRunning: this.isRunning,
      intervalMs: this.INTERVAL_MS,
      baseSpeedKmph: this.BASE_SPEED_KMPH,
      busCount: this.buses.size,
      buses: busStatuses,
    };
  }
}
