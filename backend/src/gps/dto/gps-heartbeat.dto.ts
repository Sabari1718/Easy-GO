import { IsString, IsDateString, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GpsHeartbeatDto {
  @ApiProperty({ example: 'TRK001', description: 'GPS Tracker Device ID', required: false })
  @IsString()
  @IsOptional()
  trackerId?: string;

  @ApiProperty({ example: '2026-09-30T10:00:00Z', description: 'ISO 8601 Heartbeat Timestamp' })
  @IsDateString()
  timestamp: string;
}
