import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findByMobile(mobileNumber: string) {
    return this.prisma.user.findUnique({ where: { mobileNumber } });
  }

  async updateProfile(id: string, name: string) {
    return this.prisma.user.update({ where: { id }, data: { name } });
  }
}
