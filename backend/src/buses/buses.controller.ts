import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { BusesService } from './buses.service';

@ApiTags('Buses')
@Controller('buses')
export class BusesController {
  constructor(private busesService: BusesService) {}

  @Get('nearby')
  @ApiOperation({ summary: 'Find nearby buses by location (within radius)' })
  @ApiQuery({ name: 'latitude', type: Number })
  @ApiQuery({ name: 'longitude', type: Number })
  @ApiQuery({ name: 'radius', type: Number, required: false })
  @ApiQuery({ name: 'radiusKm', type: Number, required: false })
  findNearby(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
    @Query('radius') radius?: number,
    @Query('radiusKm') radiusKm?: number,
  ) {
    const r = radius !== undefined ? +radius : radiusKm !== undefined ? +radiusKm : 5;
    return this.busesService.findNearbyBuses(+latitude, +longitude, r);
  }

  @Get()
  @ApiOperation({ summary: 'Get all buses' })
  findAll() {
    return this.busesService.findAll();
  }

  @Get(':busId')
  @ApiOperation({ summary: 'Get bus details with live state' })
  findOne(@Param('busId') busId: string) {
    return this.busesService.findOne(busId);
  }

  @Get(':busId/live')
  @ApiOperation({ summary: 'Get current live state of a bus' })
  getLiveState(@Param('busId') busId: string) {
    return this.busesService.getLiveState(busId);
  }

  @Get(':busId/schedule')
  @ApiOperation({ summary: 'Get schedule and live vs scheduled timings for a bus' })
  getSchedule(@Param('busId') busId: string) {
    return this.busesService.getSchedule(busId);
  }
}
