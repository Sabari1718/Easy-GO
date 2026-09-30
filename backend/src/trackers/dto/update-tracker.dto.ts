import { IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateTrackerDto {
  @ApiProperty({ example: 'new-device-secret', description: 'Updated device secret', required: false })
  @IsString()
  @IsOptional()
  deviceSecret?: string;

  @ApiProperty({ example: 'TELTONIKA_FMB920', description: 'Device type/model', required: false })
  @IsString()
  @IsOptional()
  deviceType?: string;

  @ApiProperty({ example: '+919876543210', description: 'SIM Number', required: false })
  @IsString()
  @IsOptional()
  simNumber?: string;

  @ApiProperty({ example: 'Jio 4G', description: 'Provider', required: false })
  @IsString()
  @IsOptional()
  provider?: string;

  @ApiProperty({ example: 'BUS_12A', description: 'Assigned Bus ID', required: false })
  @IsString()
  @IsOptional()
  busId?: string;

  @ApiProperty({ example: true, description: 'Is active', required: false })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
