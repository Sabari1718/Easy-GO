import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';

@Injectable()
export class RoutesService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async findAll() {
    return this.prisma.route.findMany({
      include: {
        _count: { select: { stops: true, buses: true } },
      },
    });
  }

  async findOne(id: string) {
    const route = await this.prisma.route.findUnique({
      where: { id },
      include: {
        stops: {
          include: { stop: true },
          orderBy: { sequence: 'asc' },
        },
        buses: {
          select: { id: true, busNumber: true, status: true },
        },
      },
    });
    if (!route) throw new NotFoundException(`Route ${id} not found`);
    return route;
  }

  async findRouteStops(routeId: string) {
    const stops = await this.prisma.routeStop.findMany({
      where: { routeId },
      include: { stop: true },
      orderBy: { sequence: 'asc' },
    });
    if (!stops.length) throw new NotFoundException(`No stops found for route ${routeId}`);
    return stops.map((rs) => ({
      sequence: rs.sequence,
      distanceFromStartKm: rs.distanceFromStartKm,
      estimatedMinutesFromPreviousStop: rs.estimatedMinutesFromPreviousStop,
      stop: rs.stop,
    }));
  }

  async findRouteBuses(routeId: string) {
    const buses = await this.prisma.bus.findMany({
      where: { routeId, status: 'ACTIVE' },
      select: { id: true, busNumber: true, vehicleNumber: true, status: true },
    });

    const busesWithLive = await Promise.all(
      buses.map(async (b) => {
        const liveState = await this.trackingService.getLiveBusState(b.id);
        return { ...b, liveState };
      }),
    );

    return busesWithLive;
  }

  async searchRoutes(from?: string, to?: string) {
    const routes = await this.prisma.route.findMany({
      where: {
        AND: [
          from ? { OR: [{ source: { contains: from, mode: 'insensitive' } }, { name: { contains: from, mode: 'insensitive' } }] } : {},
          to ? { OR: [{ destination: { contains: to, mode: 'insensitive' } }, { name: { contains: to, mode: 'insensitive' } }] } : {},
        ],
      },
      include: {
        buses: { where: { status: 'ACTIVE' }, select: { id: true, busNumber: true } },
        _count: { select: { stops: true } },
      },
    });

    return Promise.all(
      routes.map(async (route) => {
        const busesWithLive = await Promise.all(
          route.buses.map(async (b) => {
            const liveState = await this.trackingService.getLiveBusState(b.id);
            return { ...b, liveState };
          }),
        );
        return { ...route, buses: busesWithLive };
      }),
    );
  }
}
