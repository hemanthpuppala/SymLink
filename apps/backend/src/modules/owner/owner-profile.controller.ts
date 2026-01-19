import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OwnerGuard } from '../../common/guards/owner.guard';
import { IsString, IsOptional } from 'class-validator';

class UpdateProfileDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  phone?: string;
}

@Controller('v1/owner/profile')
@UseGuards(OwnerGuard)
export class OwnerProfileController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getProfile(@Request() req: any) {
    const owner = await this.prisma.owner.findUnique({
      where: { id: req.user.sub },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
        updatedAt: true,
        _count: {
          select: {
            plants: true,
          },
        },
      },
    });

    return owner;
  }

  @Patch()
  async updateProfile(@Request() req: any, @Body() dto: UpdateProfileDto) {
    const owner = await this.prisma.owner.update({
      where: { id: req.user.sub },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.phone && { phone: dto.phone }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return owner;
  }
}
