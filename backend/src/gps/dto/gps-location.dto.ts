import { IsString, IsNumber, Min, Max, IsDateString, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GpsLocationDto {
  @ApiProperty({ example: 'TRK001', description: 'GPS tracker device ID', required: false })
  @IsString()
  @IsOptional()
  trackerId?: string;

  @ApiProperty({ example: 'tracker-001', description: 'Alternative alias for tracker device ID', required: false })
  @IsString()
  @IsOptional()
  deviceId?: string;

  @ApiProperty({ example: 'BUS_12A', description: 'Bus ID or bus number', required: false })
  @IsString()
  @IsOptional()
  busId?: string;

  @ApiProperty({ example: 10.9601, description: 'Latitude' })
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ example: 76.9502, description: 'Longitude' })
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiProperty({ example: 32, description: 'Speed in km/h', required: false })
  @IsNumber()
  @Min(0)
  @IsOptional()
  speed?: number;

  @ApiProperty({ example: 85, description: 'Heading in degrees (0-360)', required: false })
  @IsNumber()
  @Min(0)
  @Max(360)
  @IsOptional()
  heading?: number;

  @ApiProperty({ example: 5, description: 'GPS accuracy in meters', required: false })
  @IsNumber()
  @IsOptional()
  accuracy?: number;

  @ApiProperty({ example: '2026-09-29T15:30:00Z', description: 'ISO 8601 timestamp' })
  @IsDateString()
  timestamp: string;
}
