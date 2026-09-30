import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { GpsDeviceAdapter, NormalizedGpsPoint } from './adapters/gps-adapter.interface';
import { StandardHttpAdapter } from './adapters/standard-http.adapter';

@Injectable()
export class GpsAdapterService {
  private readonly logger = new Logger(GpsAdapterService.name);
  private adapters: GpsDeviceAdapter[] = [];

  constructor(private readonly standardHttpAdapter: StandardHttpAdapter) {
    this.registerAdapter(this.standardHttpAdapter);
  }

  registerAdapter(adapter: GpsDeviceAdapter) {
    this.adapters.push(adapter);
    this.logger.log(`Registered GPS Adapter: ${adapter.name} (${adapter.protocol})`);
  }

  adapt(payload: any, headers?: Record<string, any>): NormalizedGpsPoint {
    // 1. Find matching adapter
    for (const adapter of this.adapters) {
      if (adapter.supports(payload, headers)) {
        return adapter.adapt(payload, headers);
      }
    }

    // Fallback to standard HTTP adapter if basic payload
    if (this.standardHttpAdapter.supports(payload, headers)) {
      return this.standardHttpAdapter.adapt(payload, headers);
    }

    throw new BadRequestException('Unsupported GPS payload format. No compatible adapter found.');
  }
}
