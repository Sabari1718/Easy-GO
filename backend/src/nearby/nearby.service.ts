import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';
import { haversineDistance } from '../common/utils/geo.utils';

@Injectable()
export class NearbyService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async findNearbyBuses(latitude: number, longitude: number, radiusKm: number) {
    // Get all active live states from Redis (no PostgreSQL query)
    const allStates = await this.trackingService.getAllActiveBusStates();

    const nearby = allStates
      .map((state) => ({
        ...state,
        distanceKm: Math.round(haversineDistance(latitude, longitude, state.latitude, state.longitude) * 100) / 100,
      }))
      .filter((s) => s.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm);

    return nearby.map((s) => ({
      busId: s.busId,
      busNumber: s.busNumber,
      route: s.routeName,
      destination: s.nextStopName,
      latitude: s.latitude,
      longitude: s.longitude,
      distanceKm: s.distanceKm,
      etaMinutes: s.etaMinutes,
      status: s.status,
      currentStop: s.currentStopName,
      nextStop: s.nextStopName,
      speed: s.speed,
      progressPercentage: s.progressPercentage,
    }));
  }

  async findNearbyStops(latitude: number, longitude: number, radiusKm: number) {
    const stops = await this.prisma.busStop.findMany({
      include: {
        routes: {
          include: {
            route: {
              include: {
                buses: { where: { status: 'ACTIVE' }, select: { id: true, busNumber: true } },
              },
            },
          },
        },
      },
    });

    const nearby = stops
      .map((stop) => ({
        stopId: stop.id,
        name: stop.name,
        latitude: stop.latitude,
        longitude: stop.longitude,
        distanceKm: Math.round(haversineDistance(latitude, longitude, stop.latitude, stop.longitude) * 100) / 100,
        routes: stop.routes.map((rs) => ({
          routeId: rs.routeId,
          routeName: rs.route.name,
          busCount: rs.route.buses.length,
        })),
      }))
      .filter((s) => s.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, 15);

    return nearby;
  }
}
