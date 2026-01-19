import {
  Controller,
  Get,
  Patch,
  Body,
  Request,
  UseGuards,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConsumerGuard } from '../../common/guards/consumer.guard';
import { IsString, IsOptional, MinLength, MaxLength, Matches } from 'class-validator';

class UpdateProfileDto {
  @IsString()
  @IsOptional()
  @MinLength(2)
  name?: string;

  @IsString()
  @IsOptional()
  @MinLength(3)
  @MaxLength(20)
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'Display name can only contain letters, numbers, and underscores',
  })
  displayName?: string;

  @IsString()
  @IsOptional()
  phone?: string;
}

@Controller('v1/consumer/profile')
@UseGuards(ConsumerGuard)
export class ConsumerProfileController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getProfile(@Request() req: any) {
    const consumer = await this.prisma.consumer.findUnique({
      where: { id: req.user.sub },
      select: {
        id: true,
        email: true,
        displayName: true,
        name: true,
        phone: true,
        createdAt: true,
      },
    });

    return consumer;
  }

  @Patch()
  async updateProfile(@Request() req: any, @Body() dto: UpdateProfileDto) {
    // If displayName is being changed, check uniqueness
    if (dto.displayName) {
      const existingDisplayName = await this.prisma.consumer.findUnique({
        where: { displayName: dto.displayName.toLowerCase() },
      });

      if (existingDisplayName && existingDisplayName.id !== req.user.sub) {
        throw new ConflictException('Display name already taken');
      }
    }

    const consumer = await this.prisma.consumer.update({
      where: { id: req.user.sub },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.displayName && { displayName: dto.displayName.toLowerCase() }),
        ...(dto.phone && { phone: dto.phone }),
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        name: true,
        phone: true,
        createdAt: true,
      },
    });

    return consumer;
  }
}
