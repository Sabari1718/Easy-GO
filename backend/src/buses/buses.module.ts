import { Module } from '@nestjs/common';
import { BusesController } from './buses.controller';
import { BusesService } from './buses.service';
import { TrackingModule } from '../tracking/tracking.module';

@Module({
  imports: [TrackingModule],
  controllers: [BusesController],
  providers: [BusesService],
  exports: [BusesService],
})
export class BusesModule {}
