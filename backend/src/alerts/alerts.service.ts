import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class AlertsService {
  constructor(private prisma: PrismaService) {}

  async findAll(routeId?: string, busId?: string, stopId?: string) {
    return this.prisma.alert.findMany({
      where: {
        AND: [
          routeId ? { routeId } : {},
          busId ? { busId } : {},
          stopId ? { stopId } : {},
          {
            OR: [
              { expiresAt: null },
              { expiresAt: { gt: new Date() } },
            ],
          },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
