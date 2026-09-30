import { Injectable, UnauthorizedException, BadRequestException, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { PrismaService } from '../database/prisma.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {}

  async sendOtp(dto: SendOtpDto): Promise<{ message: string; expiresIn: number }> {
    const { mobileNumber } = dto;

    // Find or create user
    let user = await this.prisma.user.findUnique({ where: { mobileNumber } });
    if (!user) {
      user = await this.prisma.user.create({ data: { mobileNumber } });
      this.logger.log(`New user created: ${mobileNumber}`);
    }

    const mockOtp = this.configService.get<string>('MOCK_OTP', '123456');
    const expirySeconds = this.configService.get<number>('OTP_EXPIRY_SECONDS', 300);
    const expiresAt = new Date(Date.now() + expirySeconds * 1000);

    // Store OTP record (invalidate previous)
    await this.prisma.otpRecord.deleteMany({ where: { userId: user.id, verified: false } });
    await this.prisma.otpRecord.create({
      data: { userId: user.id, otp: mockOtp, expiresAt },
    });

    this.logger.log(`OTP generated for ${mobileNumber} (mock mode: ${mockOtp})`);

    return {
      message: `OTP sent to ${mobileNumber}. (Development: Use ${mockOtp})`,
      expiresIn: expirySeconds,
    };
  }

  async verifyOtp(dto: VerifyOtpDto): Promise<{ accessToken: string; user: any }> {
    const { mobileNumber, otp } = dto;

    const user = await this.prisma.user.findUnique({ where: { mobileNumber } });
    if (!user) {
      throw new UnauthorizedException('User not found. Please send OTP first.');
    }

    const otpRecord = await this.prisma.otpRecord.findFirst({
      where: {
        userId: user.id,
        otp,
        verified: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // Mark OTP as used
    await this.prisma.otpRecord.update({
      where: { id: otpRecord.id },
      data: { verified: true },
    });

    const payload = { sub: user.id, mobileNumber: user.mobileNumber };
    const accessToken = this.jwtService.sign(payload);

    this.logger.log(`User authenticated: ${mobileNumber}`);

    return {
      accessToken,
      user: {
        id: user.id,
        mobileNumber: user.mobileNumber,
        name: user.name,
        createdAt: user.createdAt,
      },
    };
  }
}
