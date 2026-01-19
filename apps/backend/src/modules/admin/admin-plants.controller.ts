import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  NotFoundException,
  Patch,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AdminGuard } from '../../common/guards/admin.guard';
import { PrismaService } from '../prisma/prisma.service';

// Helper to parse photos JSON string to array
function parsePhotos(photos: string): string[] {
  try {
    return JSON.parse(photos);
  } catch {
    return [];
  }
}

class ListPlantsQueryDto {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  verified?: string;
}

class UpdatePlantStatusDto {
  isActive?: boolean;
  isVerified?: boolean;
}

@Controller('v1/admin/plants')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminPlantsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async listPlants(@Query() query: ListPlantsQueryDto) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {};

    // Search filter
    if (query.search) {
      where.OR = [
        { name: { contains: query.search } },
        { address: { contains: query.search } },
      ];
    }

    // Status filter (open/closed)
    if (query.status === 'open') {
      where.isActive = true;
    } else if (query.status === 'closed') {
      where.isActive = false;
    }

    // Verification filter
    if (query.verified === 'verified') {
      where.isVerified = true;
    } else if (query.verified === 'unverified') {
      where.isVerified = false;
    }

    const [plants, total] = await Promise.all([
      this.prisma.plant.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              phone: true,
              email: true,
            },
          },
          viewLogs: {
            select: { id: true },
          },
        },
      }),
      this.prisma.plant.count({ where }),
    ]);

    return {
      data: plants.map((plant) => ({
        id: plant.id,
        name: plant.name,
        address: plant.address,
        operatingHours: plant.operatingHours,
        tdsReading: plant.tdsLevel,
        pricePerLiter: plant.pricePerLiter ? Number(plant.pricePerLiter) : null,
        description: plant.description,
        photos: parsePhotos(plant.photos),
        verificationStatus: plant.isVerified ? 'verified' : 'unverified',
        isOpen: plant.isActive,
        viewCount: plant.viewLogs.length,
        createdAt: plant.createdAt,
        updatedAt: plant.updatedAt,
        owner: plant.owner,
      })),
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  @Get(':id')
  async getPlantDetails(@Param('id') id: string) {
    const plant = await this.prisma.plant.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            phone: true,
            email: true,
            createdAt: true,
          },
        },
        conversations: {
          select: {
            id: true,
            createdAt: true,
            lastMessageAt: true,
          },
          orderBy: { lastMessageAt: 'desc' },
          take: 5,
        },
        viewLogs: {
          select: { id: true },
        },
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Get verification request if any
    const verificationRequest = await this.prisma.verificationRequest.findFirst({
      where: { plantId: plant.id },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        status: true,
        createdAt: true,
        reviewedAt: true,
        rejectionReason: true,
      },
    });

    // Get view statistics
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    const [totalViews, weeklyViews] = await Promise.all([
      this.prisma.viewLog.count({ where: { plantId: id } }),
      this.prisma.viewLog.count({
        where: {
          plantId: id,
          viewedAt: { gte: weekAgo },
        },
      }),
    ]);

    return {
      id: plant.id,
      name: plant.name,
      address: plant.address,
      operatingHours: plant.operatingHours,
      tdsReading: plant.tdsLevel,
      pricePerLiter: plant.pricePerLiter ? Number(plant.pricePerLiter) : null,
      description: plant.description,
      photos: parsePhotos(plant.photos),
      verificationStatus: plant.isVerified ? 'verified' : 'unverified',
      isOpen: plant.isActive,
      viewCount: plant.viewLogs.length,
      createdAt: plant.createdAt,
      updatedAt: plant.updatedAt,
      owner: plant.owner,
      verificationRequest: verificationRequest
        ? {
            id: verificationRequest.id,
            status: verificationRequest.status,
            submittedAt: verificationRequest.createdAt,
            decidedAt: verificationRequest.reviewedAt,
            rejectionReason: verificationRequest.rejectionReason,
          }
        : null,
      conversationCount: plant.conversations.length,
      recentConversations: plant.conversations,
      analytics: {
        totalViews,
        weeklyViews,
      },
    };
  }

  @Patch(':id')
  async updatePlant(
    @Param('id') id: string,
    @Body() dto: UpdatePlantStatusDto,
  ) {
    const plant = await this.prisma.plant.findUnique({
      where: { id },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    const updateData: any = {};

    if (dto.isActive !== undefined) {
      updateData.isActive = dto.isActive;
    }

    if (dto.isVerified !== undefined) {
      updateData.isVerified = dto.isVerified;
    }

    const updated = await this.prisma.plant.update({
      where: { id },
      data: updateData,
    });

    return {
      id: updated.id,
      name: updated.name,
      verificationStatus: updated.isVerified ? 'verified' : 'unverified',
      isOpen: updated.isActive,
      updatedAt: updated.updatedAt,
    };
  }
}
