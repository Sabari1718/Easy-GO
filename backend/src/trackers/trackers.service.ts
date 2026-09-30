import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { PrismaService } from '../database/prisma.service';
import { CreateTrackerDto } from './dto/create-tracker.dto';
import { UpdateTrackerDto } from './dto/update-tracker.dto';

@Injectable()
export class TrackersService {
  private readonly logger = new Logger(TrackersService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Determine device status based on last seen telemetry.
   * ONLINE  <= 60s
   * RECENT  <= 5m
   * STALE   <= 30m
   * OFFLINE > 30m or never
   */
  private computeStatus(tracker: any): 'ONLINE' | 'RECENT' | 'STALE' | 'OFFLINE' {
    if (!tracker.isActive || tracker.status === 'INACTIVE') {
      return 'OFFLINE';
    }

    const lastActive = tracker.lastLocationAt || tracker.lastHeartbeatAt || tracker.lastSeenAt;
    if (!lastActive) return 'OFFLINE';

    const ageMs = Date.now() - new Date(lastActive).getTime();
    if (ageMs <= 60 * 1000) return 'ONLINE';
    if (ageMs <= 5 * 60 * 1000) return 'RECENT';
    if (ageMs <= 30 * 60 * 1000) return 'STALE';
    return 'OFFLINE';
  }

  private formatTracker(tracker: any, includeSecret = false) {
    if (!tracker) return null;
    const { deviceSecret, bus, ...safe } = tracker;
    const computedStatus = this.computeStatus(tracker);

    const lastLocation = tracker.bus?.locations?.[0]
      ? {
          latitude: tracker.bus.locations[0].latitude,
          longitude: tracker.bus.locations[0].longitude,
          speed: tracker.bus.locations[0].speed,
          heading: tracker.bus.locations[0].heading,
          accuracy: tracker.bus.locations[0].accuracy,
          timestamp: tracker.bus.locations[0].timestamp,
        }
      : null;

    const formatted: any = {
      ...safe,
      status: computedStatus,
      deviceStatus: computedStatus,
      busId: bus?.id || tracker.busId || null,
      bus: bus
        ? {
            id: bus.id,
            busNumber: bus.busNumber,
            vehicleNumber: bus.vehicleNumber,
            operator: bus.operator,
            route: bus.route
              ? {
                  id: bus.route.id,
                  name: bus.route.name,
                  source: bus.route.source,
                  destination: bus.route.destination,
                }
              : null,
          }
        : null,
      lastLocation,
      lastHeartbeat: tracker.lastHeartbeatAt,
      lastHeartbeatAt: tracker.lastHeartbeatAt,
      lastLocationAt: tracker.lastLocationAt,
      lastSeenAt: tracker.lastSeenAt,
      hasSecret: !!deviceSecret,
    };

    if (includeSecret) {
      formatted.deviceSecret = deviceSecret;
    }

    return formatted;
  }

  async findAll() {
    const trackers = await this.prisma.busTracker.findMany({
      include: {
        bus: {
          include: {
            route: true,
            locations: {
              take: 1,
              orderBy: { timestamp: 'desc' },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    return trackers.map((t) => this.formatTracker(t));
  }

  async findOne(trackerId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId }, { deviceId: trackerId }, { id: trackerId }],
      },
      include: {
        bus: {
          include: {
            route: true,
            locations: {
              take: 1,
              orderBy: { timestamp: 'desc' },
            },
          },
        },
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    return this.formatTracker(tracker);
  }

  async create(dto: CreateTrackerDto) {
    const targetDeviceId = dto.deviceId || dto.trackerId;

    // Check if trackerId or deviceId already exists
    const existing = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId: dto.trackerId }, { deviceId: targetDeviceId }],
      },
    });

    if (existing) {
      throw new ConflictException(
        `Tracker with ID '${dto.trackerId}' or deviceId '${targetDeviceId}' already exists`,
      );
    }

    // Resolve bus if busId passed
    let busRecord: any = null;
    if (dto.busId) {
      busRecord = await this.prisma.bus.findFirst({
        where: {
          OR: [
            { id: dto.busId },
            { busNumber: dto.busId },
            { busNumber: dto.busId.replace(/^bus_/i, '').toUpperCase() },
          ],
        },
        include: { route: true },
      });
      if (!busRecord) throw new BadRequestException(`Bus '${dto.busId}' not found`);

      // Unassign any tracker currently attached to this bus
      await this.prisma.busTracker.updateMany({
        where: { busId: busRecord.id },
        data: { busId: null },
      });
    }

    // Generate secure device credentials if omitted
    const generatedSecret =
      dto.deviceSecret || `trk_sec_${crypto.randomBytes(16).toString('hex')}`;

    const tracker = await this.prisma.busTracker.create({
      data: {
        id: `trk_${dto.trackerId.toLowerCase()}`,
        trackerId: dto.trackerId,
        deviceName: dto.deviceName || `${dto.trackerId} GPS Device`,
        deviceId: targetDeviceId,
        deviceSecret: generatedSecret,
        deviceType: dto.deviceType || '4G_GPS_TRACKER',
        simNumber: dto.simNumber,
        provider: dto.provider,
        busId: busRecord?.id || null,
        isActive: dto.isActive ?? true,
        status: dto.isActive === false ? 'INACTIVE' : 'ACTIVE',
      },
      include: {
        bus: {
          include: {
            route: true,
            locations: { take: 1, orderBy: { timestamp: 'desc' } },
          },
        },
      },
    });

    this.logger.log(`Created new GPS tracker: ${tracker.trackerId} (Assigned bus: ${busRecord?.busNumber || 'None'})`);
    // Return credentials once upon creation so the installer can configure the tracker hardware
    return this.formatTracker(tracker, true);
  }

  async update(trackerId: string, dto: UpdateTrackerDto) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId }, { deviceId: trackerId }, { id: trackerId }],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    const updateData: any = {};
    if (dto.deviceName !== undefined) updateData.deviceName = dto.deviceName;
    if (dto.deviceSecret !== undefined) updateData.deviceSecret = dto.deviceSecret;
    if (dto.deviceType !== undefined) updateData.deviceType = dto.deviceType;
    if (dto.simNumber !== undefined) updateData.simNumber = dto.simNumber;
    if (dto.provider !== undefined) updateData.provider = dto.provider;
    if (dto.isActive !== undefined) {
      updateData.isActive = dto.isActive;
      updateData.status = dto.isActive ? 'ACTIVE' : 'INACTIVE';
    }
    if (dto.busId !== undefined) {
      if (dto.busId === null || dto.busId === '') {
        updateData.busId = null;
      } else {
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

        // Unassign any tracker previously attached to this bus
        await this.prisma.busTracker.updateMany({
          where: { busId: bus.id, id: { not: tracker.id } },
          data: { busId: null },
        });

        updateData.busId = bus.id;
      }
    }

    const updated = await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: updateData,
      include: {
        bus: {
          include: {
            route: true,
            locations: { take: 1, orderBy: { timestamp: 'desc' } },
          },
        },
      },
    });

    return this.formatTracker(updated);
  }

  async activate(trackerId: string) {
    return this.update(trackerId, { isActive: true });
  }

  async deactivate(trackerId: string) {
    return this.update(trackerId, { isActive: false });
  }

  async assignBus(trackerId: string, busId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId }, { deviceId: trackerId }, { id: trackerId }],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

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

    // Unassign previous tracker from this bus (Requirement 5)
    await this.prisma.busTracker.updateMany({
      where: { busId: bus.id, id: { not: tracker.id } },
      data: { busId: null },
    });

    const updated = await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: { busId: bus.id },
      include: {
        bus: {
          include: {
            route: true,
            locations: { take: 1, orderBy: { timestamp: 'desc' } },
          },
        },
      },
    });

    this.logger.log(`Assigned tracker ${tracker.trackerId} to bus ${bus.busNumber}`);
    return this.formatTracker(updated);
  }

  async unassignBus(trackerId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId }, { deviceId: trackerId }, { id: trackerId }],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    const updated = await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: { busId: null },
      include: {
        bus: {
          include: {
            route: true,
            locations: { take: 1, orderBy: { timestamp: 'desc' } },
          },
        },
      },
    });

    this.logger.log(`Unassigned tracker ${tracker.trackerId} from bus`);
    return this.formatTracker(updated);
  }

  async rotateKey(trackerId: string) {
    const tracker = await this.prisma.busTracker.findFirst({
      where: {
        OR: [{ trackerId }, { deviceId: trackerId }, { id: trackerId }],
      },
    });

    if (!tracker) {
      throw new NotFoundException(`Tracker '${trackerId}' not found`);
    }

    const newSecret = `trk_sec_${crypto.randomBytes(16).toString('hex')}`;

    await this.prisma.busTracker.update({
      where: { id: tracker.id },
      data: { deviceSecret: newSecret },
    });

    this.logger.log(`Rotated API secret key for tracker ${tracker.trackerId}`);

    return {
      success: true,
      trackerId: tracker.trackerId,
      newDeviceSecret: newSecret,
      rotatedAt: new Date().toISOString(),
      message: 'New device secret generated. Update tracker hardware configuration immediately.',
    };
  }
}
