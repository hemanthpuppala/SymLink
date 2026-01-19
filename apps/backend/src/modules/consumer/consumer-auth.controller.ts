import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
  ConflictException,
  Get,
  Query,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import {
  RegisterConsumerDto,
  LoginConsumerDto,
  RefreshTokenDto,
  CheckDisplayNameDto,
} from './dto/consumer-auth.dto';
import { Public } from '../../common/decorators/public.decorator';

@Controller('v1/consumer/auth')
export class ConsumerAuthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authService: AuthService,
  ) {}

  @Public()
  @Get('check-display-name')
  async checkDisplayName(@Query() query: CheckDisplayNameDto) {
    const existing = await this.prisma.consumer.findUnique({
      where: { displayName: query.displayName.toLowerCase() },
    });

    return {
      displayName: query.displayName,
      available: !existing,
    };
  }

  @Public()
  @Post('register')
  async register(@Body() dto: RegisterConsumerDto) {
    // Check email uniqueness
    const existingEmail = await this.prisma.consumer.findUnique({
      where: { email: dto.email },
    });

    if (existingEmail) {
      throw new ConflictException('Email already registered');
    }

    // Check displayName uniqueness (stored as lowercase)
    const existingDisplayName = await this.prisma.consumer.findUnique({
      where: { displayName: dto.displayName.toLowerCase() },
    });

    if (existingDisplayName) {
      throw new ConflictException('Display name already taken');
    }

    const hashedPassword = await this.authService.hashPassword(dto.password);

    const consumer = await this.prisma.consumer.create({
      data: {
        email: dto.email,
        displayName: dto.displayName.toLowerCase(),
        password: hashedPassword,
        name: dto.name,
        phone: dto.phone,
      },
    });

    const tokens = await this.authService.generateTokens({
      sub: consumer.id,
      email: consumer.email,
      type: 'consumer',
    });

    return {
      consumer: {
        id: consumer.id,
        email: consumer.email,
        displayName: consumer.displayName,
        name: consumer.name,
        phone: consumer.phone,
      },
      tokens,
    };
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginConsumerDto) {
    const consumer = await this.prisma.consumer.findUnique({
      where: { email: dto.email },
    });

    if (!consumer) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await this.authService.comparePasswords(
      dto.password,
      consumer.password,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.authService.generateTokens({
      sub: consumer.id,
      email: consumer.email,
      type: 'consumer',
    });

    return {
      consumer: {
        id: consumer.id,
        email: consumer.email,
        displayName: consumer.displayName,
        name: consumer.name,
        phone: consumer.phone,
      },
      tokens,
    };
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto) {
    const payload = await this.authService.verifyToken(dto.refreshToken);

    if (!payload || payload.type !== 'consumer') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const consumer = await this.prisma.consumer.findUnique({
      where: { id: payload.sub },
    });

    if (!consumer) {
      throw new UnauthorizedException('Consumer not found');
    }

    const tokens = await this.authService.generateTokens({
      sub: consumer.id,
      email: consumer.email,
      type: 'consumer',
    });

    return { tokens };
  }
}
