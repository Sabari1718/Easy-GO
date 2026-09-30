import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AdminAuthGuard implements CanActivate {
  private readonly logger = new Logger(AdminAuthGuard.name);

  constructor(private configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();

    const adminKey =
      request.headers['x-admin-key'] ||
      request.headers['x-api-key'] ||
      request.headers['authorization']?.replace(/^ApiKey\s+/i, '').replace(/^Bearer\s+/i, '');

    const expectedAdminKey =
      this.configService.get<string>('ADMIN_API_KEY') ||
      process.env.ADMIN_API_KEY ||
      'easygo-admin-secret-key-2026';

    if (!adminKey || adminKey !== expectedAdminKey) {
      this.logger.warn(`Unauthorized admin API access attempt from IP: ${request.ip}`);
      throw new UnauthorizedException('Invalid or missing admin API key. Provide x-admin-key header.');
    }

    return true;
  }
}
