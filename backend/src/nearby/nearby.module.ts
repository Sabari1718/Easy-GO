import { Module } from '@nestjs/common';
import { NearbyController } from './nearby.controller';
import { NearbyService } from './nearby.service';
import { TrackingModule } from '../tracking/tracking.module';

@Module({
  imports: [TrackingModule],
  controllers: [NearbyController],
  providers: [NearbyService],
})
export class NearbyModule {}
