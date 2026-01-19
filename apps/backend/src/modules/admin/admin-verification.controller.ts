import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncGateway } from '../sync/sync.gateway';
import { AdminGuard } from '../../common/guards/admin.guard';
import { UpdateVerificationDto } from './dto/admin-verification.dto';
import { RequestStatus } from '@prisma/client';

@Controller('v1/admin/verification-requests')
@UseGuards(AdminGuard)
export class AdminVerificationController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly syncGateway: SyncGateway,
  ) {}

  @Get()
  async getVerificationRequests(
    @Query('status') status?: RequestStatus,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const skip = (pageNum - 1) * limitNum;

    const where = status ? { status } : {};

    const [requests, total] = await Promise.all([
      this.prisma.verificationRequest.findMany({
        where,
        include: {
          plant: {
            include: {
              owner: {
                select: {
                  id: true,
                  name: true,
                  email: true,
                  phone: true,
                },
              },
            },
          },
          reviewer: {
            select: {
              id: true,
              name: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limitNum,
      }),
      this.prisma.verificationRequest.count({ where }),
    ]);

    return {
      requests,
      meta: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  @Get(':id')
  async getVerificationRequest(@Param('id') id: string) {
    const request = await this.prisma.verificationRequest.findUnique({
      where: { id },
      include: {
        plant: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
              },
            },
          },
        },
        reviewer: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Verification request not found');
    }

    return request;
  }

  @Patch(':id')
  async updateVerificationRequest(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateVerificationDto,
  ) {
    const existingRequest = await this.prisma.verificationRequest.findUnique({
      where: { id },
      include: { plant: true },
    });

    if (!existingRequest) {
      throw new NotFoundException('Verification request not found');
    }

    // Update the verification request
    const request = await this.prisma.verificationRequest.update({
      where: { id },
      data: {
        status: dto.status,
        rejectionReason: dto.rejectionReason,
        reviewedAt: new Date(),
        reviewerId: req.user.sub,
      },
      include: {
        plant: {
          include: {
            owner: true,
          },
        },
      },
    });

    // If approved, update plant verification status
    if (dto.status === RequestStatus.APPROVED) {
      await this.prisma.plant.update({
        where: { id: existingRequest.plantId },
        data: { isVerified: true },
      });
    }

    // Create notification for owner
    const notificationMessage =
      dto.status === RequestStatus.APPROVED
        ? `Your plant "${existingRequest.plant.name}" has been verified!`
        : `Your verification request for "${existingRequest.plant.name}" has been rejected. ${dto.rejectionReason || ''}`;

    await this.prisma.notification.create({
      data: {
        type: dto.status === RequestStatus.APPROVED ? 'VERIFICATION_APPROVED' : 'VERIFICATION_REJECTED',
        title: dto.status === RequestStatus.APPROVED ? 'Verification Approved' : 'Verification Rejected',
        message: notificationMessage,
        ownerId: existingRequest.plant.ownerId,
      },
    });

    // Real-time notification via WebSocket
    this.syncGateway.notifyVerificationUpdated({
      ...request,
      ownerId: existingRequest.plant.ownerId,
      plantId: existingRequest.plantId,
    });

    // If approved, also notify about plant update
    if (dto.status === RequestStatus.APPROVED) {
      const updatedPlant = await this.prisma.plant.findUnique({
        where: { id: existingRequest.plantId },
      });
      if (updatedPlant) {
        this.syncGateway.notifyPlantUpdated(updatedPlant);
      }
    }

    return request;
  }
}
