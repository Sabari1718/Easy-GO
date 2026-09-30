import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AssignBusDto {
  @ApiProperty({ example: 'BUS_12A', description: 'Bus ID or Bus Number to assign this tracker to' })
  @IsString()
  busId: string;
}
