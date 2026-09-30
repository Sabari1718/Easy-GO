import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { RoutesService } from './routes.service';

@ApiTags('Routes')
@Controller('routes')
export class RoutesController {
  constructor(private routesService: RoutesService) {}

  @Get('search')
  @ApiOperation({ summary: 'Search routes by source and destination' })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'to', required: false })
  searchRoutes(@Query('from') from?: string, @Query('to') to?: string) {
    return this.routesService.searchRoutes(from, to);
  }

  @Get()
  @ApiOperation({ summary: 'Get all routes' })
  findAll() {
    return this.routesService.findAll();
  }

  @Get(':routeId')
  @ApiOperation({ summary: 'Get route details' })
  findOne(@Param('routeId') routeId: string) {
    return this.routesService.findOne(routeId);
  }

  @Get(':routeId/stops')
  @ApiOperation({ summary: 'Get all stops on a route in sequence' })
  findRouteStops(@Param('routeId') routeId: string) {
    return this.routesService.findRouteStops(routeId);
  }

  @Get(':routeId/buses')
  @ApiOperation({ summary: 'Get active buses on a route with live state' })
  findRouteBuses(@Param('routeId') routeId: string) {
    return this.routesService.findRouteBuses(routeId);
  }
}
