import { Module } from '@nestjs/common';
import { GpsController } from './gps.controller';
import { GpsService } from './gps.service';
import { TrackingModule } from '../tracking/tracking.module';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [TrackingModule, RealtimeModule],
  controllers: [GpsController],
  providers: [GpsService],
  exports: [GpsService],
})
export class GpsModule {}
