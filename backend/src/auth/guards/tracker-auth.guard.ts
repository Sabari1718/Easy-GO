import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class TrackerAuthGuard implements CanActivate {
  private readonly logger = new Logger(TrackerAuthGuard.name);

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    // 1. Extract API key / device secret from headers
    const apiKey =
      request.headers['x-tracker-key'] ||
      request.headers['x-tracker-secret'] ||
      request.headers['authorization']?.replace(/^ApiKey\s+/i, '').replace(/^Bearer\s+/i, '');

    // 2. Extract tracker identifier from header or body
    const trackerId =
      request.headers['x-tracker-id'] ||
      request.body?.trackerId ||
      request.body?.deviceId;

    const globalValidKey =
      this.configService.get<string>('TRACKER_API_KEY') ||
      process.env.TRACKER_API_KEY ||
      'dev-tracker-secret-key-001';

    if (!apiKey) {
      this.logger.warn(`Missing tracker API key from IP ${request.ip}`);
      throw new UnauthorizedException('Missing tracker API key. Provide x-tracker-key header.');
    }

    // 3. If trackerId is present, check specific tracker credentials and state
    if (trackerId) {
      let tracker: any = null;
      try {
        tracker = await this.prisma.busTracker.findFirst({
          where: {
            OR: [
              { trackerId: String(trackerId) },
              { deviceId: String(trackerId) },
              { id: String(trackerId) },
            ],
          },
          include: { bus: true },
        });
      } catch (e) {
        this.logger.warn(`Database lookup failed in TrackerAuthGuard: ${e.message}`);
      }

      if (tracker) {
        // Check if tracker is deactivated
        if (tracker.isActive === false || tracker.status === 'INACTIVE' || tracker.status === 'LOST') {
          this.logger.warn(`Rejected GPS update from inactive tracker ${trackerId}`);
          throw new ForbiddenException(`Tracker device '${trackerId}' is inactive or suspended.`);
        }

        // Validate device secret: matches device-specific secret OR global secret
        const deviceSecret = tracker.deviceSecret;
        const isValid = (deviceSecret && apiKey === deviceSecret) || apiKey === globalValidKey;
        if (!isValid) {
          this.logger.warn(`Invalid secret for tracker ${trackerId}`);
          throw new UnauthorizedException(`Invalid API key for tracker '${trackerId}'.`);
        }

        request.tracker = tracker;
        return true;
      }
    }

    // 4. If no specific tracker record exists, allow if apiKey matches global key (for simulator or new tracker provisioning)
    if (apiKey === globalValidKey) {
      return true;
    }

    this.logger.warn(`Tracker auth rejected: invalid key from IP ${request.ip}`);
    throw new UnauthorizedException('Invalid tracker API key');
  }
}
