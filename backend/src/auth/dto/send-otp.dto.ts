import { IsString, IsNotEmpty, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SendOtpDto {
  @ApiProperty({ example: '+919876543210', description: 'Mobile number with country code' })
  @IsString()
  @IsNotEmpty()
  mobileNumber: string;
}
