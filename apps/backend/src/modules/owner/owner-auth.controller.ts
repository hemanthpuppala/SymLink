import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import {
  RegisterOwnerDto,
  LoginOwnerDto,
  RefreshTokenDto,
  PasswordResetRequestDto,
  PasswordResetConfirmDto,
} from './dto/owner-auth.dto';
import { Public } from '../../common/decorators/public.decorator';

@Controller('v1/owner/auth')
export class OwnerAuthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authService: AuthService,
  ) {}

  @Public()
  @Post('register')
  async register(@Body() dto: RegisterOwnerDto) {
    const existingOwner = await this.prisma.owner.findUnique({
      where: { email: dto.email },
    });

    if (existingOwner) {
      throw new ConflictException('Email already registered');
    }

    const hashedPassword = await this.authService.hashPassword(dto.password);

    const owner = await this.prisma.owner.create({
      data: {
        email: dto.email,
        password: hashedPassword,
        name: dto.name,
        phone: dto.phone,
      },
    });

    const tokens = await this.authService.generateTokens({
      sub: owner.id,
      email: owner.email,
      type: 'owner',
    });

    return {
      owner: {
        id: owner.id,
        email: owner.email,
        name: owner.name,
        phone: owner.phone,
      },
      tokens,
    };
  }

  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginOwnerDto) {
    const owner = await this.prisma.owner.findUnique({
      where: { email: dto.email },
    });

    if (!owner) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await this.authService.comparePasswords(
      dto.password,
      owner.password,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.authService.generateTokens({
      sub: owner.id,
      email: owner.email,
      type: 'owner',
    });

    return {
      owner: {
        id: owner.id,
        email: owner.email,
        name: owner.name,
        phone: owner.phone,
      },
      tokens,
    };
  }

  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto) {
    const payload = await this.authService.verifyToken(dto.refreshToken);

    if (!payload || payload.type !== 'owner') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const owner = await this.prisma.owner.findUnique({
      where: { id: payload.sub },
    });

    if (!owner) {
      throw new UnauthorizedException('Owner not found');
    }

    const tokens = await this.authService.generateTokens({
      sub: owner.id,
      email: owner.email,
      type: 'owner',
    });

    return { tokens };
  }

  @Public()
  @Post('password/reset')
  @HttpCode(HttpStatus.OK)
  async requestPasswordReset(@Body() dto: PasswordResetRequestDto) {
    const owner = await this.prisma.owner.findUnique({
      where: { email: dto.email },
    });

    if (!owner) {
      // Don't reveal if email exists
      return { message: 'If the email exists, a reset link has been sent' };
    }

    // In production, generate a reset token and send email
    // For now, just return success
    return { message: 'If the email exists, a reset link has been sent' };
  }

  @Public()
  @Post('password/confirm')
  @HttpCode(HttpStatus.OK)
  async confirmPasswordReset(@Body() dto: PasswordResetConfirmDto) {
    // In production, verify the reset token from email
    // For now, throw not found
    throw new NotFoundException('Invalid or expired reset token');
  }
}
