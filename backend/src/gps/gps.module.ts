import { Module } from '@nestjs/common';
import { GpsController } from './gps.controller';
import { GpsService } from './gps.service';
import { GpsAdapterService } from './gps-adapter.service';
import { StandardHttpAdapter } from './adapters/standard-http.adapter';
import { TrackingModule } from '../tracking/tracking.module';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [TrackingModule, RealtimeModule],
  controllers: [GpsController],
  providers: [GpsService, GpsAdapterService, StandardHttpAdapter],
  exports: [GpsService, GpsAdapterService],
})
export class GpsModule {}
