import { Module } from '@nestjs/common';
import { TrackersController } from './trackers.controller';
import { AdminTrackersController } from './admin-trackers.controller';
import { TrackersService } from './trackers.service';

@Module({
  controllers: [TrackersController, AdminTrackersController],
  providers: [TrackersService],
  exports: [TrackersService],
})
export class TrackersModule {}
