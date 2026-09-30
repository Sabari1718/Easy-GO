import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateFavoriteDto } from './dto/create-favorite.dto';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateFavoriteDto) {
    const existing = await this.prisma.favorite.findUnique({
      where: { userId_type_referenceId: { userId, type: dto.type, referenceId: dto.referenceId } },
    });
    if (existing) throw new ConflictException('Already in favorites');

    return this.prisma.favorite.create({
      data: { userId, type: dto.type, referenceId: dto.referenceId, referenceName: dto.referenceName },
    });
  }

  async findAll(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async remove(userId: string, id: string) {
    const fav = await this.prisma.favorite.findFirst({ where: { id, userId } });
    if (!fav) throw new NotFoundException('Favorite not found');
    return this.prisma.favorite.delete({ where: { id } });
  }
}
