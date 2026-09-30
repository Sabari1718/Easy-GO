import { Module } from '@nestjs/common';
import { TrackingService } from './tracking.service';
import { EtaService } from './eta.service';
import { StopEngineService } from './stop-engine.service';
import { RouteProgressService } from './route-progress.service';

@Module({
  providers: [TrackingService, EtaService, StopEngineService, RouteProgressService],
  exports: [TrackingService, EtaService, StopEngineService, RouteProgressService],
})
export class TrackingModule {}
