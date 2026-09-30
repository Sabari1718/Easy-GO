import { Module } from '@nestjs/common';
import { JourneysController } from './journeys.controller';
import { JourneysService } from './journeys.service';
import { TrackingModule } from '../tracking/tracking.module';

@Module({
  imports: [TrackingModule],
  controllers: [JourneysController],
  providers: [JourneysService],
  exports: [JourneysService],
})
export class JourneysModule {}
