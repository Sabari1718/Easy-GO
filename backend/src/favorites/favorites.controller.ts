import { Controller, Get, Post, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { FavoritesService } from './favorites.service';
import { CreateFavoriteDto } from './dto/create-favorite.dto';

@ApiTags('Favorites')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('favorites')
export class FavoritesController {
  constructor(private favoritesService: FavoritesService) {}

  @Get()
  @ApiOperation({ summary: 'Get user favorites' })
  findAll(@CurrentUser() user: any) {
    return this.favoritesService.findAll(user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Add a favorite (bus, route, or stop)' })
  create(@CurrentUser() user: any, @Body() dto: CreateFavoriteDto) {
    return this.favoritesService.create(user.id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Remove a favorite' })
  remove(@CurrentUser() user: any, @Param('id') id: string) {
    return this.favoritesService.remove(user.id, id);
  }
}
