import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { StopsService } from './stops.service';

@ApiTags('Stops')
@Controller('stops')
export class StopsController {
  constructor(private stopsService: StopsService) {}

  @Get('nearby')
  @ApiOperation({ summary: 'Find nearby bus stops' })
  @ApiQuery({ name: 'latitude', type: Number })
  @ApiQuery({ name: 'longitude', type: Number })
  @ApiQuery({ name: 'radiusKm', type: Number, required: false })
  findNearby(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
    @Query('radiusKm') radiusKm: number = 2,
  ) {
    return this.stopsService.findNearby(+latitude, +longitude, +radiusKm);
  }

  @Get()
  @ApiOperation({ summary: 'Get all bus stops' })
  findAll() {
    return this.stopsService.findAll();
  }

  @Get(':stopId')
  @ApiOperation({ summary: 'Get bus stop details with upcoming buses' })
  findOne(@Param('stopId') stopId: string) {
    return this.stopsService.findOne(stopId);
  }
}
