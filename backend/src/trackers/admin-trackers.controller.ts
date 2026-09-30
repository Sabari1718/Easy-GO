import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiHeader, ApiSecurity } from '@nestjs/swagger';
import { TrackersService } from './trackers.service';
import { CreateTrackerDto } from './dto/create-tracker.dto';
import { UpdateTrackerDto } from './dto/update-tracker.dto';
import { AssignBusDto } from './dto/assign-bus.dto';
import { AdminAuthGuard } from '../auth/guards/admin-auth.guard';

@ApiTags('Admin Tracker Management')
@ApiSecurity('admin-key')
@UseGuards(AdminAuthGuard)
@Controller('admin/trackers')
export class AdminTrackersController {
  constructor(private readonly trackersService: TrackersService) {}

  @Get()
  @ApiOperation({ summary: 'List all GPS trackers with device status & bus assignment' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'List of all trackers with online/recent/stale/offline status' })
  findAll() {
    return this.trackersService.findAll();
  }

  @Get(':trackerId')
  @ApiOperation({ summary: 'Get details for a specific GPS tracker' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker details' })
  @ApiResponse({ status: 404, description: 'Tracker not found' })
  findOne(@Param('trackerId') trackerId: string) {
    return this.trackersService.findOne(trackerId);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Register and onboard a physical GPS tracker',
    description: 'Generates secure credentials for the physical tracker. Credentials returned once upon creation.',
  })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 201, description: 'Tracker created and credentials generated' })
  create(@Body() dto: CreateTrackerDto) {
    return this.trackersService.create(dto);
  }

  @Patch(':trackerId')
  @ApiOperation({ summary: 'Update tracker parameters (name, sim, type, active)' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker updated successfully' })
  update(@Param('trackerId') trackerId: string, @Body() dto: UpdateTrackerDto) {
    return this.trackersService.update(trackerId, dto);
  }

  @Post(':trackerId/assign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Assign tracker to a bus (replaces previous tracker if assigned)' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker assigned to bus' })
  assign(@Param('trackerId') trackerId: string, @Body() dto: AssignBusDto) {
    return this.trackersService.assignBus(trackerId, dto.busId);
  }

  @Post(':trackerId/unassign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unassign tracker from its bus' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker unassigned from bus' })
  unassign(@Param('trackerId') trackerId: string) {
    return this.trackersService.unassignBus(trackerId);
  }

  @Post(':trackerId/activate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Activate tracker (enables GPS ingestion)' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker activated' })
  activate(@Param('trackerId') trackerId: string) {
    return this.trackersService.activate(trackerId);
  }

  @Post(':trackerId/deactivate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Deactivate tracker (immediately blocks GPS ingestion)' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'Tracker deactivated' })
  deactivate(@Param('trackerId') trackerId: string) {
    return this.trackersService.deactivate(trackerId);
  }

  @Post(':trackerId/rotate-key')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate secret API key for tracker' })
  @ApiHeader({ name: 'x-admin-key', required: true, description: 'Admin authentication API key' })
  @ApiResponse({ status: 200, description: 'New device secret generated' })
  rotateKey(@Param('trackerId') trackerId: string) {
    return this.trackersService.rotateKey(trackerId);
  }
}
