import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { TrackingService } from '../tracking/tracking.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { PrismaService } from '../database/prisma.service';
import { GpsLocationDto } from './dto/gps-location.dto';
import { GpsHeartbeatDto } from './dto/gps-heartbeat.dto';

@Injectable()
export class GpsService {
  private readonly logger = new Logger(GpsService.name);

  constructor(
    private trackingService: TrackingService,
    private realtimeGateway: RealtimeGateway,
    private prisma: PrismaService,
  ) {}

  async processLocation(dto: GpsLocationDto, headerTrackerId?: string) {
    // 1. Validate timestamp freshness
    const timeMs = new Date(dto.timestamp).getTime();
    const now = Date.now();
    if (isNaN(timeMs)) {
      throw new BadRequestException('Invalid timestamp format. Expected ISO 8601.');
    }
    if (now - timeMs > 24 * 60 * 60 * 1000) {
      throw new BadRequestException('GPS timestamp is excessively old (> 24 hours).');
    }
    if (timeMs - now > 5 * 60 * 1000) {
      throw new BadRequestException('GPS timestamp is in the future (> 5 minutes).');
    }

    const trackerId = dto.trackerId || dto.deviceId || headerTrackerId;

    const liveState = await this.trackingService.processGpsUpdate({
      deviceId: dto.deviceId,
      trackerId,
      busId: dto.busId,
      latitude: dto.latitude,
      longitude: dto.longitude,
      speed: dto.speed ?? 0,
      heading: dto.heading ?? 0,
      accuracy: dto.accuracy ?? 5,
      timestamp: dto.timestamp,
    });

    if (liveState) {
      // Broadcast to subscribed WebSocket clients
      this.realtimeGateway.broadcastBusUpdate(liveState);
    }

    return {
      success: true,
      busId: liveState?.busId || dto.busId || 'UNKNOWN',
      receivedAt: new Date().toISOString(),
      liveState,
    };
  }

  async processHeartbeat(dto: GpsHeartbeatDto, headerTrackerId?: string) {
    const trkId = dto.trackerId || headerTrackerId;
    if (!trkId) {
      throw new BadRequestException('trackerId is required in body or X-Tracker-Id header.');
    }

    let tracker: any = null;
    try {
      tracker = await this.prisma.busTracker.findFirst({
        where: {
          OR: [{ trackerId: trkId }, { deviceId: trkId }, { id: trkId }],
        },
        include: { bus: true },
      });

      if (tracker) {
        await this.prisma.busTracker.update({
          where: { id: tracker.id },
          data: { lastSeenAt: new Date() },
        });
      }
    } catch (e) {
      this.logger.warn(`Failed to update tracker lastSeenAt: ${e.message}`);
    }

    return {
      success: true,
      trackerId: trkId,
      busId: tracker?.busId || tracker?.bus?.id || null,
      deviceStatus: 'ONLINE',
      lastSeenAt: new Date().toISOString(),
    };
  }
}
