import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { AlertsService } from './alerts.service';

@ApiTags('Alerts')
@Controller('alerts')
export class AlertsController {
  constructor(private alertsService: AlertsService) {}

  @Get()
  @ApiOperation({ summary: 'Get service alerts (route, bus, stop, general)' })
  @ApiQuery({ name: 'routeId', required: false })
  @ApiQuery({ name: 'busId', required: false })
  @ApiQuery({ name: 'stopId', required: false })
  findAll(
    @Query('routeId') routeId?: string,
    @Query('busId') busId?: string,
    @Query('stopId') stopId?: string,
  ) {
    return this.alertsService.findAll(routeId, busId, stopId);
  }
}
