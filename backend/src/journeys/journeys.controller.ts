import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { JourneysService } from './journeys.service';

@ApiTags('Journeys')
@Controller('journeys')
export class JourneysController {
  constructor(private journeysService: JourneysService) {}

  @Get('search')
  @ApiOperation({ summary: 'Intelligent journey discovery and trip-planning' })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  @ApiQuery({ name: 'fromLat', type: Number, required: false })
  @ApiQuery({ name: 'fromLng', type: Number, required: false })
  @ApiQuery({ name: 'toLat', type: Number, required: false })
  @ApiQuery({ name: 'toLng', type: Number, required: false })
  searchJourneys(
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('fromLat') fromLat?: number,
    @Query('fromLng') fromLng?: number,
    @Query('toLat') toLat?: number,
    @Query('toLng') toLng?: number,
  ) {
    return this.journeysService.searchJourneys({
      from,
      to,
      fromLat: fromLat !== undefined ? +fromLat : undefined,
      fromLng: fromLng !== undefined ? +fromLng : undefined,
      toLat: toLat !== undefined ? +toLat : undefined,
      toLng: toLng !== undefined ? +toLng : undefined,
    });
  }
}
