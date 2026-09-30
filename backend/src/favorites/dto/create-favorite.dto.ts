import { IsString, IsNotEmpty, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum FavoriteType {
  BUS = 'BUS',
  ROUTE = 'ROUTE',
  STOP = 'STOP',
}

export class CreateFavoriteDto {
  @ApiProperty({ enum: FavoriteType, example: FavoriteType.ROUTE })
  @IsEnum(FavoriteType)
  type: FavoriteType;

  @ApiProperty({ example: 'route-uuid', description: 'ID of the bus, route, or stop' })
  @IsString()
  @IsNotEmpty()
  referenceId: string;

  @ApiProperty({ example: 'Ukkadam → Pollachi' })
  @IsString()
  @IsNotEmpty()
  referenceName: string;
}
