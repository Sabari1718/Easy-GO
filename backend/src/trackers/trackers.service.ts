import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateTrackerDto } from './dto/create-tracker.dto';
import { UpdateTrackerDto } from './dto/update-tracker.dto';

@Injectable()
export class TrackersService {
  constructor(private prisma: PrismaService) {}

  private sanitize(tracker: any) {
    if (!tracker) return null;
    const { deviceSecret, ...safe } = tracker;
    return {
      ...safe,
      hasSecret: !!deviceSecret,
    };
  }

  async findAll() {
    const trackers = await this.prisma.busTracker.findMany({
      include: { bus: { include: { route: true } } },
    });
    return trackers.map((t) => this.sanitize(t));
  }

  async findOne(trackerId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [
          { trackerId },
          { deviceId: trackerId },
          { id: trackerId },
        ],
      },
      include: { bus: { include: { route: true } } },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    return this.sanitize(tracker);
  }

  async create(dto: CreateTrackerDto) {
    // Check if trackerId or deviceId already exists
    const existing = await this.prisma.busTracker.findFirst({
      where: {
        OR: [
          { trackerId: dto.trackerId },
          { deviceId: dto.deviceId },
        ],
      },
    });

    if (existing) {
      throw new ConflictException(`Tracker with ID '${dto.trackerId}' or deviceId '${dto.deviceId}' already exists`);
    }

    // Resolve bus if busId passed
    let busId = dto.busId;
    if (busId) {
      const bus = await this.prisma.bus.findFirst({
        where: {
          OR: [
            { id: busId },
            { busNumber: busId },
            { busNumber: busId.replace(/^bus_/i, '').toUpperCase() },
          ],
        },
      });
      if (!bus) throw new BadRequestException(`Bus '${dto.busId}' not found`);
      busId = bus.id;
    }

    const tracker = await this.prisma.busTracker.create({
      data: {
        id: `trk_${dto.trackerId.toLowerCase()}`,
        trackerId: dto.trackerId,
        deviceId: dto.deviceId,
        deviceSecret: dto.deviceSecret,
        deviceType: dto.deviceType || '4G_GPS_TRACKER',
        simNumber: dto.simNumber,
        provider: dto.provider,
        busId,
        isActive: dto.isActive ?? true,
        status: dto.isActive === false ? 'INACTIVE' : 'ACTIVE',
      },
    });

    return this.sanitize(tracker);
  }

  async update(trackerId: string, dto: UpdateTrackerDto) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [
          { trackerId },
          { deviceId: trackerId },
          { id: trackerId },
        ],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    const updateData: any = {};
    if (dto.deviceSecret !== undefined) updateData.deviceSecret = dto.deviceSecret;
    if (dto.deviceType !== undefined) updateData.deviceType = dto.deviceType;
    if (dto.simNumber !== undefined) updateData.simNumber = dto.simNumber;
    if (dto.provider !== undefined) updateData.provider = dto.provider;
    if (dto.isActive !== undefined) {
      updateData.isActive = dto.isActive;
      updateData.status = dto.isActive ? 'ACTIVE' : 'INACTIVE';
    }
    if (dto.busId !== undefined) {
      const bus = await this.prisma.bus.findFirst({
        where: {
          OR: [
            { id: dto.busId },
            { busNumber: dto.busId },
            { busNumber: dto.busId.replace(/^bus_/i, '').toUpperCase() },
          ],
        },
      });
      if (!bus) throw new BadRequestException(`Bus '${dto.busId}' not found`);
      updateData.busId = bus.id;
    }

    const updated = await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: updateData,
    });

    return this.sanitize(updated);
  }

  async activate(trackerId: string) {
    return this.update(trackerId, { isActive: true });
  }

  async deactivate(trackerId: string) {
    return this.update(trackerId, { isActive: false });
  }

  async assignBus(trackerId: string, busId: string) {
    const bus = await this.prisma.bus.findFirst({
      where: {
        OR: [
          { id: busId },
          { busNumber: busId },
          { busNumber: busId.replace(/^bus_/i, '').toUpperCase() },
        ],
      },
    });

    if (!bus) {
      throw new NotFoundException(`Bus '${busId}' not found`);
    }

    return this.update(trackerId, { busId: bus.id });
  }

  async unassignBus(trackerId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [
          { trackerId },
          { deviceId: trackerId },
          { id: trackerId },
        ],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    const updated = await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: { busId: null },
    });

    return this.sanitize(updated);
  }
}
