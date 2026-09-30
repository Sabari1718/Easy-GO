import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { NearbyService } from './nearby.service';

@ApiTags('Nearby')
@Controller('buses')
export class NearbyController {
  constructor(private nearbyService: NearbyService) {}

  @Get('nearby')
  @ApiOperation({ summary: 'Find nearby active buses from Redis live state' })
  @ApiQuery({ name: 'latitude', type: Number })
  @ApiQuery({ name: 'longitude', type: Number })
  @ApiQuery({ name: 'radiusKm', type: Number, required: false })
  findNearbyBuses(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
    @Query('radiusKm') radiusKm: number = 5,
  ) {
    return this.nearbyService.findNearbyBuses(+latitude, +longitude, +radiusKm);
  }
}
