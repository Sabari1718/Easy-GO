import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';
import { haversineDistance } from '../common/utils/geo.utils';

@Injectable()
export class HomeService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async getHomeData(latitude?: number, longitude?: number) {
    // If coordinates not provided, default to Gandhipuram coordinates
    const userLat = latitude !== undefined && !isNaN(latitude) ? latitude : 11.0168;
    const userLng = longitude !== undefined && !isNaN(longitude) ? longitude : 76.9558;

    // 1. Get all bus stops from DB
    const dbStops = await this.prisma.busStop.findMany({
      include: {
        routes: {
          include: {
            route: {
              include: {
                buses: { where: { status: 'ACTIVE' } },
              },
            },
          },
        },
      },
    });

    // Score stops by distance
    const scoredStops = dbStops
      .map((stop) => {
        const distKm =
          Math.round(
            haversineDistance(userLat, userLng, stop.latitude, stop.longitude) *
              100,
          ) / 100;
        return { stop, distKm };
      })
      .sort((a, b) => a.distKm - b.distKm);

    // Preferred radius 500m (0.5km), fallback up to 2.5km
    let nearbyStopEntries = scoredStops.filter((s) => s.distKm <= 0.5);
    if (nearbyStopEntries.length === 0) {
      nearbyStopEntries = scoredStops.filter((s) => s.distKm <= 2.5);
    }
    if (nearbyStopEntries.length === 0) {
      nearbyStopEntries = scoredStops.slice(0, 3);
    }

    const nearestStop = nearbyStopEntries[0]?.stop;
    const locationSummary = nearestStop
      ? `${nearestStop.name}, Coimbatore`
      : 'Gandhipuram, Coimbatore';

    // 2. Build nearbyStops with upcoming next buses
    const nearbyStops = nearbyStopEntries.slice(0, 5).map((entry) => {
      const s = entry.stop;
      const routesServing = s.routes.map((rs) => rs.route);
      const nextBuses = routesServing.flatMap((r) =>
        r.buses.map((b, idx) => ({
          busId: b.id,
          busNumber: b.busNumber,
          destination: r.destination,
          etaMinutes: (idx + 1) * 4 + 1,
          status: idx === 0 ? 'Approaching' : 'On Time',
        })),
      );

      return {
        id: s.id,
        name: s.name,
        latitude: s.latitude,
        longitude: s.longitude,
        distanceKm: entry.distKm,
        distanceMeters: Math.round(entry.distKm * 1000),
        address: `${s.name}, Coimbatore District`,
        arrivingBuses: nextBuses.slice(0, 4),
        routes: routesServing.map((r) => ({
          id: r.id,
          name: r.name,
          source: r.source,
          destination: r.destination,
        })),
      };
    });

    // 3. Find nearby active buses (within 5 km radius)
    const allLiveStates = await this.trackingService.getAllActiveBusStates();
    const allActiveBuses = await this.prisma.bus.findMany({
      where: { status: 'ACTIVE' },
      include: {
        route: {
          include: {
            stops: { include: { stop: true }, orderBy: { sequence: 'asc' } },
          },
        },
      },
    });

    const nearbyBusesList: any[] = [];
    const nearbyRouteIds = new Set<string>();

    for (const bus of allActiveBuses) {
      const live = allLiveStates.find((s) => s.busId === bus.id);
      let bLat = live?.latitude;
      let bLng = live?.longitude;
      const isLive = live !== null && live !== undefined && live.status !== 'OFFLINE';

      if (bLat === undefined || bLng === undefined) {
        if (bus.route.stops.length > 0) {
          bLat = bus.route.stops[0].stop.latitude;
          bLng = bus.route.stops[0].stop.longitude;
        } else {
          continue;
        }
      }

      const distKm =
        Math.round(haversineDistance(userLat, userLng, bLat, bLng) * 100) / 100;

      // Filter: ONLY buses within 5 km that are relevant to this location
      // Check if user is near the bus or route passes near the user
      const isRouteNearUser = bus.route.stops.some(
        (rs) =>
          haversineDistance(userLat, userLng, rs.stop.latitude, rs.stop.longitude) <= 3.5,
      );

      if (distKm <= 5.0 || isRouteNearUser) {
        nearbyRouteIds.add(bus.route.id);
        const eta = live?.etaMinutes ?? Math.max(3, Math.round(distKm * 3.2));
        nearbyBusesList.push({
          busId: bus.id,
          busNumber: bus.busNumber,
          routeId: bus.routeId,
          routeName: bus.route.name,
          origin: bus.route.source,
          destination: bus.route.destination,
          distanceKm: distKm,
          etaMinutes: eta,
          isLive,
          status: live?.status ?? (isLive ? 'ACTIVE' : 'SCHEDULED'),
          currentStop: live?.currentStopName ?? bus.route.stops[0]?.stop.name ?? bus.route.source,
          nextStop: live?.nextStopName ?? bus.route.stops[1]?.stop.name ?? bus.route.destination,
          speed: live?.speed ?? (isLive ? 28 : 0),
          progressPercentage: live?.progressPercentage ?? 15,
        });
      }
    }

    // Sort nearby buses nearest first, prioritizing live buses
    nearbyBusesList.sort((a, b) => {
      if (a.isLive !== b.isLive) return a.isLive ? -1 : 1;
      return a.distanceKm - b.distanceKm;
    });

    // 4. Build nearbyRoutes - ONLY routes serving the user's nearby area
    const nearbyRoutesList = allActiveBuses
      .filter((b) => nearbyRouteIds.has(b.route.id))
      .map((b) => ({
        id: b.route.id,
        routeId: b.route.id,
        routeNumber: b.busNumber,
        routeName: b.route.name,
        source: b.route.source,
        destination: b.route.destination,
        activeBusCount: 1,
      }))
      .filter(
        (value, index, self) =>
          index === self.findIndex((t) => t.routeId === value.routeId),
      );

    return {
      locationSummary,
      latitude: userLat,
      longitude: userLng,
      nearbyStops,
      nearbyBuses: nearbyBusesList,
      nearbyRoutes: nearbyRoutesList,
    };
  }
}
