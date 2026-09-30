import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis;
  private memoryCache = new Map<string, { value: string; expiresAt?: number }>();

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.client = new Redis({
      host: this.configService.get<string>('REDIS_HOST', 'localhost'),
      port: this.configService.get<number>('REDIS_PORT', 6379),
      password: this.configService.get<string>('REDIS_PASSWORD') || undefined,
      retryStrategy: () => null,
      lazyConnect: true,
      enableOfflineQueue: false,
    });

    this.client.on('connect', () => this.logger.log('✅ Redis connected'));
    this.client.on('error', (err) => {
      // Quietly log only if not connection refused
      if (!err.message?.includes('ECONNREFUSED')) {
        this.logger.warn(`Redis notice: ${err.message}`);
      }
    });

    try {
      await this.client.connect();
    } catch (e) {
      this.logger.warn(`Redis connection failed: ${e.message}. Using in-memory live cache fallback.`);
    }
  }

  async onModuleDestroy() {
    await this.client?.quit();
  }

  async get(key: string): Promise<string | null> {
    try {
      const val = await this.client.get(key);
      if (val !== null) return val;
    } catch {}

    const cached = this.memoryCache.get(key);
    if (!cached) return null;
    if (cached.expiresAt && Date.now() > cached.expiresAt) {
      this.memoryCache.delete(key);
      return null;
    }
    return cached.value;
  }

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    this.memoryCache.set(key, {
      value,
      expiresAt: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined,
    });

    try {
      if (ttlSeconds) {
        await this.client.setex(key, ttlSeconds, value);
      } else {
        await this.client.set(key, value);
      }
    } catch (e) {
      // Handled by in-memory cache
    }
  }

  async del(key: string): Promise<void> {
    this.memoryCache.delete(key);
    try {
      await this.client.del(key);
    } catch {}
  }

  async keys(pattern: string): Promise<string[]> {
    const keySet = new Set<string>();

    try {
      const redisKeys = await this.client.keys(pattern);
      redisKeys.forEach((k) => keySet.add(k));
    } catch {}

    // Match memory keys
    const regexPattern = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
    const now = Date.now();
    for (const [k, v] of this.memoryCache.entries()) {
      if (v.expiresAt && now > v.expiresAt) {
        this.memoryCache.delete(k);
        continue;
      }
      if (regexPattern.test(k)) {
        keySet.add(k);
      }
    }

    return Array.from(keySet);
  }

  async hset(key: string, field: string, value: string): Promise<void> {
    try {
      await this.client.hset(key, field, value);
    } catch {}
  }

  async hget(key: string, field: string): Promise<string | null> {
    try {
      return await this.client.hget(key, field);
    } catch {
      return null;
    }
  }

  async hgetall(key: string): Promise<Record<string, string>> {
    try {
      return await this.client.hgetall(key) || {};
    } catch {
      return {};
    }
  }

  async setJson(key: string, value: any, ttlSeconds?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttlSeconds);
  }

  async getJson<T>(key: string): Promise<T | null> {
    const raw = await this.get(key);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async isHealthy(): Promise<boolean> {
    try {
      const result = await this.client.ping();
      return result === 'PONG';
    } catch {
      return false;
    }
  }
}
