import { Module } from '@nestjs/common';
import { SimulatorController } from './simulator.controller';
import { SimulatorService } from './simulator.service';
import { GpsModule } from '../gps/gps.module';

@Module({
  imports: [GpsModule],
  controllers: [SimulatorController],
  providers: [SimulatorService],
})
export class SimulatorModule {}
