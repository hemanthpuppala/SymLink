import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CacheService } from '../cache/cache.service';

export interface HealthCheckResult {
  status: 'healthy' | 'unhealthy' | 'degraded';
  timestamp: string;
  version: string;
  checks: {
    database: { status: string; latency?: number };
    cache: { status: string; latency?: number };
  };
}

@Injectable()
export class HealthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: CacheService,
  ) {}

  async check(): Promise<HealthCheckResult> {
    const timestamp = new Date().toISOString();
    const version = process.env.npm_package_version || '1.0.0';

    const [dbCheck, cacheCheck] = await Promise.all([
      this.checkDatabase(),
      this.checkCache(),
    ]);

    const allHealthy =
      dbCheck.status === 'healthy' && cacheCheck.status === 'healthy';
    const allUnhealthy =
      dbCheck.status === 'unhealthy' && cacheCheck.status === 'unhealthy';

    let status: 'healthy' | 'unhealthy' | 'degraded';
    if (allHealthy) {
      status = 'healthy';
    } else if (allUnhealthy) {
      status = 'unhealthy';
    } else {
      status = 'degraded';
    }

    return {
      status,
      timestamp,
      version,
      checks: {
        database: dbCheck,
        cache: cacheCheck,
      },
    };
  }

  async readiness(): Promise<{ ready: boolean }> {
    const health = await this.check();
    return { ready: health.status !== 'unhealthy' };
  }

  async liveness(): Promise<{ alive: boolean }> {
    return { alive: true };
  }

  private async checkDatabase(): Promise<{ status: string; latency?: number }> {
    const start = Date.now();
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'healthy', latency: Date.now() - start };
    } catch {
      return { status: 'unhealthy' };
    }
  }

  private async checkCache(): Promise<{ status: string; latency?: number }> {
    const start = Date.now();
    try {
      await this.cache.set('health-check', 'ok', 10);
      const result = await this.cache.get<string>('health-check');
      if (result === 'ok') {
        return { status: 'healthy', latency: Date.now() - start };
      }
      return { status: 'unhealthy' };
    } catch {
      return { status: 'unhealthy' };
    }
  }
}
