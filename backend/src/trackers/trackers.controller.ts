import { Controller, Get, Post, Patch, Param, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TrackersService } from './trackers.service';
import { CreateTrackerDto } from './dto/create-tracker.dto';
import { UpdateTrackerDto } from './dto/update-tracker.dto';
import { AssignBusDto } from './dto/assign-bus.dto';

@ApiTags('Tracker Management')
@Controller('trackers')
export class TrackersController {
  constructor(private readonly trackersService: TrackersService) {}

  @Get()
  @ApiOperation({ summary: 'List all GPS trackers' })
  @ApiResponse({ status: 200, description: 'List of all trackers with bus assignment' })
  findAll() {
    return this.trackersService.findAll();
  }

  @Get(':trackerId')
  @ApiOperation({ summary: 'Get details for a specific GPS tracker' })
  @ApiResponse({ status: 200, description: 'Tracker details' })
  @ApiResponse({ status: 404, description: 'Tracker not found' })
  findOne(@Param('trackerId') trackerId: string) {
    return this.trackersService.findOne(trackerId);
  }

  @Post()
  @ApiOperation({ summary: 'Register a new physical GPS tracker' })
  @ApiResponse({ status: 201, description: 'Tracker registered' })
  create(@Body() dto: CreateTrackerDto) {
    return this.trackersService.create(dto);
  }

  @Patch(':trackerId')
  @ApiOperation({ summary: 'Update tracker parameters' })
  @ApiResponse({ status: 200, description: 'Tracker updated' })
  update(@Param('trackerId') trackerId: string, @Body() dto: UpdateTrackerDto) {
    return this.trackersService.update(trackerId, dto);
  }

  @Post(':trackerId/activate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Activate a GPS tracker' })
  activate(@Param('trackerId') trackerId: string) {
    return this.trackersService.activate(trackerId);
  }

  @Post(':trackerId/deactivate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Deactivate a GPS tracker (blocks GPS ingestion)' })
  deactivate(@Param('trackerId') trackerId: string) {
    return this.trackersService.deactivate(trackerId);
  }

  @Post(':trackerId/assign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign a GPS tracker to a bus' })
  assign(@Param('trackerId') trackerId: string, @Body() dto: AssignBusDto) {
    return this.trackersService.assignBus(trackerId, dto.busId);
  }

  @Post(':trackerId/assign-bus')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign a GPS tracker to a bus (alias)' })
  assignBus(@Param('trackerId') trackerId: string, @Body() dto: AssignBusDto) {
    return this.trackersService.assignBus(trackerId, dto.busId);
  }

  @Post(':trackerId/unassign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unassign a GPS tracker from its bus' })
  unassign(@Param('trackerId') trackerId: string) {
    return this.trackersService.unassignBus(trackerId);
  }

  @Post(':trackerId/unassign-bus')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unassign a GPS tracker from its bus (alias)' })
  unassignBus(@Param('trackerId') trackerId: string) {
    return this.trackersService.unassignBus(trackerId);
  }

  @Post(':trackerId/rotate-key')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate secret API key for tracker' })
  rotateKey(@Param('trackerId') trackerId: string) {
    return this.trackersService.rotateKey(trackerId);
  }
}
