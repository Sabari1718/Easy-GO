import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';
import { haversineDistance } from '../common/utils/geo.utils';

@Injectable()
export class StopsService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async findOne(id: string) {
    const stop = await this.prisma.busStop.findUnique({
      where: { id },
      include: {
        routes: {
          include: { route: { include: { buses: { where: { status: 'ACTIVE' } } } } },
        },
      },
    });
    if (!stop) throw new NotFoundException(`Stop ${id} not found`);

    const upcomingBuses = await Promise.all(
      stop.routes.flatMap((rs) => rs.route.buses).map(async (bus) => {
        const liveState = await this.trackingService.getLiveBusState(bus.id);
        return {
          busId: bus.id,
          busNumber: bus.busNumber,
          liveState,
          etaMinutes: liveState?.etaMinutes ?? 10,
          status: liveState?.status ?? 'SCHEDULED',
        };
      }),
    );

    return { ...stop, upcomingBuses };
  }

  async findNearby(latitude: number, longitude: number, radiusKm: number) {
    const stops = await this.prisma.busStop.findMany({
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

    const nearby = stops
      .map((stop) => {
        const distKm =
          Math.round(
            haversineDistance(latitude, longitude, stop.latitude, stop.longitude) *
              100,
          ) / 100;
        const distMeters = Math.round(distKm * 1000);
        const walkMin = Math.max(1, Math.round(distMeters / 80));

        const upcomingBuses = stop.routes
          .flatMap((rs) =>
            rs.route.buses.map((bus, idx) => ({
              busId: bus.id,
              busNumber: bus.busNumber,
              destination: rs.route.destination,
              etaMinutes: (idx + 1) * 4 + 2,
              status: idx === 0 ? 'Approaching' : 'On Time',
            })),
          )
          .slice(0, 4);

        return {
          id: stop.id,
          name: stop.name,
          latitude: stop.latitude,
          longitude: stop.longitude,
          distanceKm: distKm,
          distanceMeters: distMeters,
          walkMinutes: walkMin,
          address: `${stop.name}, Coimbatore District`,
          upcomingBuses,
          arrivingBuses: upcomingBuses,
          routes: stop.routes.map((rs) => ({
            id: rs.route.id,
            name: rs.route.name,
            source: rs.route.source,
            destination: rs.route.destination,
          })),
        };
      })
      .filter((s) => s.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, 20);

    return nearby;
  }

  async findAll() {
    return this.prisma.busStop.findMany();
  }
}
