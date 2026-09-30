import { Module } from '@nestjs/common';
import { StopsController } from './stops.controller';
import { StopsService } from './stops.service';
import { TrackingModule } from '../tracking/tracking.module';

@Module({
  imports: [TrackingModule],
  controllers: [StopsController],
  providers: [StopsService],
  exports: [StopsService],
})
export class StopsModule {}
