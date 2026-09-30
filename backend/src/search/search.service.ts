import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';

@Injectable()
export class SearchService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async search(query: string) {
    if (!query || query.trim().length === 0) {
      return { buses: [], routes: [], stops: [], total: 0 };
    }

    const q = query.trim();

    const [buses, routes, stops] = await Promise.all([
      this.prisma.bus.findMany({
        where: {
          OR: [
            { busNumber: { contains: q, mode: 'insensitive' } },
            { vehicleNumber: { contains: q, mode: 'insensitive' } },
            { route: { name: { contains: q, mode: 'insensitive' } } },
            { route: { source: { contains: q, mode: 'insensitive' } } },
            { route: { destination: { contains: q, mode: 'insensitive' } } },
          ],
        },
        include: {
          route: {
            include: {
              stops: { include: { stop: true }, orderBy: { sequence: 'asc' } },
            },
          },
        },
        take: 10,
      }),
      this.prisma.route.findMany({
        where: {
          OR: [
            { name: { contains: q, mode: 'insensitive' } },
            { source: { contains: q, mode: 'insensitive' } },
            { destination: { contains: q, mode: 'insensitive' } },
          ],
        },
        include: {
          buses: { where: { status: 'ACTIVE' } },
          _count: { select: { buses: true, stops: true } },
        },
        take: 10,
      }),
      this.prisma.busStop.findMany({
        where: { name: { contains: q, mode: 'insensitive' } },
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
        take: 10,
      }),
    ]);

    // Add live state to buses
    const busesWithLive = await Promise.all(
      buses.map(async (b) => {
        const liveState = await this.trackingService.getLiveBusState(b.id);
        const isLive = liveState !== null && liveState.status !== 'OFFLINE';
        return {
          id: b.id,
          busId: b.id,
          busNumber: b.busNumber,
          vehicleNumber: b.vehicleNumber,
          routeId: b.routeId,
          routeName: b.route.name,
          origin: b.route.source,
          destination: b.route.destination,
          status: liveState?.status ?? (isLive ? 'ACTIVE' : 'SCHEDULED'),
          isLive,
          currentStop: liveState?.currentStopName ?? b.route.stops[0]?.stop.name ?? b.route.source,
          nextStop: liveState?.nextStopName ?? b.route.stops[1]?.stop.name ?? b.route.destination,
          etaMinutes: liveState?.etaMinutes ?? 8,
          liveState,
        };
      }),
    );

    // Enhance stops with upcoming buses and routes
    const stopsEnhanced = stops.map((stop) => {
      const routesServing = stop.routes.map((rs) => rs.route);
      const nextBuses = routesServing.flatMap((r) =>
        r.buses.map((b, idx) => ({
          busId: b.id,
          busNumber: b.busNumber,
          destination: r.destination,
          etaMinutes: (idx + 1) * 5,
          status: idx === 0 ? 'Approaching' : 'On Time',
        })),
      );

      return {
        id: stop.id,
        name: stop.name,
        latitude: stop.latitude,
        longitude: stop.longitude,
        address: `${stop.name}, Coimbatore District`,
        arrivingBuses: nextBuses.slice(0, 4),
        routes: routesServing.map((r) => ({
          id: r.id,
          name: r.name,
          source: r.source,
          destination: r.destination,
        })),
      };
    });

    return {
      buses: busesWithLive,
      routes,
      stops: stopsEnhanced,
      total: busesWithLive.length + routes.length + stopsEnhanced.length,
    };
  }
}
