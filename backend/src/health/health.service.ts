import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class HealthService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  async check() {
    let dbStatus = 'healthy';
    let redisStatus = 'healthy';

    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = 'unhealthy';
    }

    try {
      const healthy = await this.redis.isHealthy();
      redisStatus = healthy ? 'healthy' : 'unhealthy';
    } catch {
      redisStatus = 'unhealthy';
    }

    const overall = dbStatus === 'healthy' && redisStatus === 'healthy' ? 'healthy' : 'degraded';

    return {
      status: overall,
      timestamp: new Date().toISOString(),
      services: {
        api: 'healthy',
        database: dbStatus,
        redis: redisStatus,
      },
    };
  }
}
