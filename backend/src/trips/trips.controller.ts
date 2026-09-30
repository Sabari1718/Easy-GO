import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TripsService } from './trips.service';

@ApiTags('Trips')
@Controller('trips')
export class TripsController {
  constructor(private tripsService: TripsService) {}

  @Get('active')
  @ApiOperation({ summary: 'Get all currently active trips' })
  findActive() {
    return this.tripsService.findActive();
  }

  @Get(':tripId')
  @ApiOperation({ summary: 'Get trip by ID' })
  findOne(@Param('tripId') tripId: string) {
    return this.tripsService.findOne(tripId);
  }
}
