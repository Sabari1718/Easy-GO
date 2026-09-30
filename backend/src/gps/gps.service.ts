import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { TrackingService } from '../tracking/tracking.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { PrismaService } from '../database/prisma.service';
import { GpsAdapterService } from './gps-adapter.service';
import { GpsLocationDto } from './dto/gps-location.dto';
import { GpsHeartbeatDto } from './dto/gps-heartbeat.dto';

@Injectable()
export class GpsService {
  private readonly logger = new Logger(GpsService.name);

  constructor(
    private trackingService: TrackingService,
    private realtimeGateway: RealtimeGateway,
    private prisma: PrismaService,
    private gpsAdapterService: GpsAdapterService,
  ) {}

  async processLocation(dto: GpsLocationDto, headerTrackerId?: string) {
    // 1. Ingest via GPS Adapter Layer (hardware-independent normalization)
    const normalized = this.gpsAdapterService.adapt(dto, {
      'x-tracker-id': headerTrackerId,
    });

    // 2. Validate timestamp freshness
    const timeMs = new Date(normalized.timestamp).getTime();
    const now = Date.now();
    if (isNaN(timeMs)) {
      this.logger.warn(`GPS rejected: Invalid timestamp format from tracker ${normalized.trackerId}`);
      throw new BadRequestException('Invalid timestamp format. Expected ISO 8601.');
    }
    if (now - timeMs > 24 * 60 * 60 * 1000) {
      this.logger.warn(`GPS rejected: Stale timestamp (>24h) from tracker ${normalized.trackerId}`);
      throw new BadRequestException('GPS timestamp is excessively old (> 24 hours).');
    }
    if (timeMs - now > 5 * 60 * 1000) {
      this.logger.warn(`GPS rejected: Future timestamp (>5m) from tracker ${normalized.trackerId}`);
      throw new BadRequestException('GPS timestamp is in the future (> 5 minutes).');
    }

    // 3. Location Quality & Accuracy Filter (Requirement 12)
    const maxAccuracy = Number(process.env.GPS_MAX_ACCURACY_METERS || 100);
    if (normalized.accuracy > maxAccuracy) {
      this.logger.warn(
        `GPS rejected: Low accuracy (${normalized.accuracy}m > ${maxAccuracy}m threshold) for tracker ${normalized.trackerId}`,
      );
      return {
        success: false,
        reason: 'POOR_ACCURACY',
        accuracy: normalized.accuracy,
        threshold: maxAccuracy,
        trackerId: normalized.trackerId,
        receivedAt: new Date().toISOString(),
      };
    }

    this.logger.log(
      `GPS received: trackerId=${normalized.trackerId}, lat=${normalized.latitude}, lng=${normalized.longitude}, speed=${normalized.speed}km/h, acc=${normalized.accuracy}m`,
    );

    // 4. Send to Core Tracking Service
    const liveState = await this.trackingService.processGpsUpdate(normalized);

    // 5. Handle out-of-order or duplicate packets (Requirement 11)
    if (liveState && (liveState as any).outOfOrderRejected) {
      return {
        success: false,
        reason: 'OUT_OF_ORDER_PACKET',
        message: 'Packet timestamp is older than current live position; discarded to prevent regression',
        receivedAt: new Date().toISOString(),
        currentLiveState: liveState,
      };
    }

    if (liveState && (liveState as any).duplicateIgnored) {
      return {
        success: true,
        ignored: true,
        reason: 'DUPLICATE_PACKET',
        message: 'Duplicate GPS timestamp ignored',
        receivedAt: new Date().toISOString(),
        liveState,
      };
    }

    // 6. Update Tracker records in PostgreSQL
    try {
      await this.prisma.busTracker.updateMany({
        where: {
          OR: [
            { trackerId: normalized.trackerId },
            { deviceId: normalized.trackerId },
          ],
        },
        data: {
          lastSeenAt: new Date(),
          lastLocationAt: new Date(normalized.timestamp),
        },
      });
    } catch (e) {
      // quiet log for fallback mock buses
    }

    // 7. Broadcast live update to Flutter & Web clients over WebSocket
    if (liveState) {
      this.realtimeGateway.broadcastBusUpdate(liveState);
    }

    return {
      success: true,
      busId: liveState?.busId || normalized.busId || 'UNKNOWN',
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
          data: {
            lastSeenAt: new Date(),
            lastHeartbeatAt: new Date(),
          },
        });
        this.logger.log(`Tracker heartbeat acknowledged: trackerId=${trkId}, busId=${tracker.bus?.busNumber || 'UNASSIGNED'}`);
      }
    } catch (e) {
      this.logger.warn(`Failed to update tracker heartbeat in DB: ${e.message}`);
    }

    return {
      success: true,
      trackerId: trkId,
      busId: tracker?.bus?.id || tracker?.busId || null,
      deviceStatus: 'ONLINE',
      lastSeenAt: new Date().toISOString(),
    };
  }
}
