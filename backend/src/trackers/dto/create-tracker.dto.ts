import { IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTrackerDto {
  @ApiProperty({ example: 'TRK001', description: 'Logical Tracker ID' })
  @IsString()
  trackerId: string;

  @ApiProperty({ example: 'IMEI-864209041234567', description: 'Hardware IMEI or Device Identifier' })
  @IsString()
  deviceId: string;

  @ApiProperty({ example: 'trk001-secret-key', description: 'Device specific authentication secret' })
  @IsString()
  deviceSecret: string;

  @ApiProperty({ example: 'TELTONIKA_FMB920', description: 'Device hardware model/type', required: false })
  @IsString()
  @IsOptional()
  deviceType?: string;

  @ApiProperty({ example: '+919876543210', description: 'SIM Card phone number', required: false })
  @IsString()
  @IsOptional()
  simNumber?: string;

  @ApiProperty({ example: 'Airtel IoT', description: 'Cellular network provider', required: false })
  @IsString()
  @IsOptional()
  provider?: string;

  @ApiProperty({ example: 'BUS_12A', description: 'Assigned Bus ID or Bus Number', required: false })
  @IsString()
  @IsOptional()
  busId?: string;

  @ApiProperty({ example: true, description: 'Whether the tracker is currently active', required: false })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
