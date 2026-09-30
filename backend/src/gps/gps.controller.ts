import { Controller, Post, Body, Headers, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse, ApiHeader } from '@nestjs/swagger';
import { GpsService } from './gps.service';
import { GpsLocationDto } from './dto/gps-location.dto';
import { GpsHeartbeatDto } from './dto/gps-heartbeat.dto';
import { TrackerAuthGuard } from '../auth/guards/tracker-auth.guard';

@ApiTags('GPS Tracker')
@ApiSecurity('tracker-auth')
@UseGuards(TrackerAuthGuard)
@Controller('gps')
export class GpsController {
  constructor(private gpsService: GpsService) {}

  @Post('location')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Submit GPS location from physical/mock tracker device',
    description: 'Hardware GPS endpoint. Authenticated via x-tracker-key header. Optionally accepts x-tracker-id header.',
  })
  @ApiHeader({ name: 'x-tracker-key', required: true, description: 'Secret device API key' })
  @ApiHeader({ name: 'x-tracker-id', required: false, description: 'Optional Tracker ID (e.g. TRK001)' })
  @ApiResponse({ status: 200, description: 'Location processed successfully' })
  @ApiResponse({ status: 400, description: 'Invalid coordinates or stale/future timestamp' })
  @ApiResponse({ status: 401, description: 'Invalid tracker API key' })
  @ApiResponse({ status: 403, description: 'Tracker device is inactive or suspended' })
  processLocation(
    @Body() dto: GpsLocationDto,
    @Headers('x-tracker-id') headerTrackerId?: string,
  ) {
    return this.gpsService.processLocation(dto, headerTrackerId);
  }

  @Post('heartbeat')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Send device heartbeat / liveness ping from physical GPS tracker',
    description: 'Updates device lastSeenAt status without sending coordinate telemetry.',
  })
  @ApiHeader({ name: 'x-tracker-key', required: true, description: 'Secret device API key' })
  @ApiHeader({ name: 'x-tracker-id', required: false, description: 'Optional Tracker ID (e.g. TRK001)' })
  @ApiResponse({ status: 200, description: 'Heartbeat acknowledged' })
  @ApiResponse({ status: 401, description: 'Invalid tracker API key' })
  @ApiResponse({ status: 403, description: 'Tracker device is inactive' })
  processHeartbeat(
    @Body() dto: GpsHeartbeatDto,
    @Headers('x-tracker-id') headerTrackerId?: string,
  ) {
    return this.gpsService.processHeartbeat(dto, headerTrackerId);
  }
}
