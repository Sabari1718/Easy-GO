import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { HomeService } from './home.service';

@ApiTags('Home')
@Controller('home')
export class HomeController {
  constructor(private homeService: HomeService) {}

  @Get()
  @ApiOperation({
    summary: 'Location-aware home data (nearby buses, stops, routes)',
  })
  @ApiQuery({ name: 'latitude', type: Number, required: false })
  @ApiQuery({ name: 'longitude', type: Number, required: false })
  getHomeData(
    @Query('latitude') latitude?: number,
    @Query('longitude') longitude?: number,
  ) {
    return this.homeService.getHomeData(
      latitude !== undefined ? +latitude : undefined,
      longitude !== undefined ? +longitude : undefined,
    );
  }
}
