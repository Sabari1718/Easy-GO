import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class TripsService {
  constructor(private prisma: PrismaService) {}

  async findActive() {
    return this.prisma.trip.findMany({
      where: { status: 'RUNNING' },
      include: { bus: true, route: true },
    });
  }

  async findByBus(busId: string) {
    return this.prisma.trip.findMany({
      where: { busId },
      include: { route: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
  }

  async findOne(id: string) {
    const trip = await this.prisma.trip.findUnique({
      where: { id },
      include: { bus: true, route: true },
    });
    if (!trip) throw new NotFoundException(`Trip ${id} not found`);
    return trip;
  }
}
