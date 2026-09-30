import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SimulatorService } from './simulator.service';

@ApiTags('GPS Simulator (Dev Only)')
@Controller('simulator')
export class SimulatorController {
  constructor(private simulatorService: SimulatorService) {}

  @Get('status')
  @ApiOperation({ summary: '[DEV] Get simulator status and bus positions' })
  getStatus() {
    return this.simulatorService.getStatus();
  }

  @Post('start')
  @ApiOperation({ summary: '[DEV] Start GPS simulator' })
  start() {
    this.simulatorService.start();
    return { message: 'Simulator started' };
  }

  @Post('stop')
  @ApiOperation({ summary: '[DEV] Stop GPS simulator' })
  stop() {
    this.simulatorService.stop();
    return { message: 'Simulator stopped' };
  }

  @Post('pause')
  @ApiOperation({ summary: '[DEV] Pause all simulated buses' })
  pause() {
    this.simulatorService.pause();
    return { message: 'Simulator paused' };
  }

  @Post('resume')
  @ApiOperation({ summary: '[DEV] Resume all simulated buses' })
  resume() {
    this.simulatorService.resume();
    return { message: 'Simulator resumed' };
  }

  @Post('reset')
  @ApiOperation({ summary: '[DEV] Reset all buses to route start' })
  async reset() {
    await this.simulatorService.reset();
    return { message: 'Simulator reset' };
  }

  @Post('speed')
  @ApiOperation({ summary: '[DEV] Set simulation speed in km/h (e.g. 10, 30, 50)' })
  setSpeed(@Body('speedKmh') speedKmh: number) {
    const speed = speedKmh ? Number(speedKmh) : 35;
    this.simulatorService.setSpeed(speed);
    return { message: `Speed set to ${speed} km/h` };
  }

  @Post('bus/:busId/pause')
  @ApiOperation({ summary: '[DEV] Pause a specific bus simulation' })
  pauseBus(@Param('busId') busId: string) {
    const success = this.simulatorService.setBusPaused(busId, true);
    return { success, busId, message: `Bus ${busId} paused` };
  }

  @Post('bus/:busId/resume')
  @ApiOperation({ summary: '[DEV] Resume a specific bus simulation' })
  resumeBus(@Param('busId') busId: string) {
    const success = this.simulatorService.setBusPaused(busId, false);
    return { success, busId, message: `Bus ${busId} resumed` };
  }
}
