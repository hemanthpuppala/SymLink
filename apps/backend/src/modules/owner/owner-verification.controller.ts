import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  NotFoundException,
  BadRequestException,
  UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SyncGateway } from '../sync/sync.gateway';
import { OwnerGuard } from '../../common/guards/owner.guard';
import { IsString, IsOptional } from 'class-validator';

class SubmitVerificationDto {
  @IsString()
  plantId: string;

  @IsString()
  @IsOptional()
  notes?: string;
}

@Controller('v1/owner/verification')
@UseGuards(OwnerGuard)
export class OwnerVerificationController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly syncGateway: SyncGateway,
  ) {}

  // Simple endpoint without file uploads for mobile apps
  @Post('simple')
  async submitVerificationSimple(
    @Request() req: any,
    @Body() dto: SubmitVerificationDto,
  ) {
    // Verify plant ownership
    const plant = await this.prisma.plant.findFirst({
      where: {
        id: dto.plantId,
        ownerId: req.user.sub,
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Check for existing pending request
    const existingRequest = await this.prisma.verificationRequest.findFirst({
      where: {
        plantId: dto.plantId,
        status: 'PENDING',
      },
    });

    if (existingRequest) {
      throw new BadRequestException(
        'A pending verification request already exists for this plant',
      );
    }

    // Create verification request without documents
    const verificationRequest = await this.prisma.verificationRequest.create({
      data: {
        plantId: dto.plantId,
        documents: JSON.stringify([]),
        notes: dto.notes,
        status: 'PENDING',
      },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        },
      },
    });

    // Notify admins via WebSocket for real-time updates
    this.syncGateway.notifyVerificationCreated({
      ...verificationRequest,
      ownerId: req.user.sub,
    });

    return verificationRequest;
  }

  @Get()
  async getVerificationRequests(@Request() req: any) {
    const requests = await this.prisma.verificationRequest.findMany({
      where: {
        plant: {
          ownerId: req.user.sub,
        },
      },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
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
    });

    return requests;
  }

  @Get(':id')
  async getVerificationRequest(@Request() req: any, @Param('id') id: string) {
    const request = await this.prisma.verificationRequest.findFirst({
      where: {
        id,
        plant: {
          ownerId: req.user.sub,
        },
      },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
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

  @Post()
  @UseInterceptors(FilesInterceptor('documents', 10))
  async submitVerification(
    @Request() req: any,
    @Body() dto: SubmitVerificationDto,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    // Verify plant ownership
    const plant = await this.prisma.plant.findFirst({
      where: {
        id: dto.plantId,
        ownerId: req.user.sub,
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Check for existing pending request
    const existingRequest = await this.prisma.verificationRequest.findFirst({
      where: {
        plantId: dto.plantId,
        status: 'PENDING',
      },
    });

    if (existingRequest) {
      throw new BadRequestException(
        'A pending verification request already exists for this plant',
      );
    }

    // Upload documents if provided
    const documentUrls: string[] = [];
    if (files && files.length > 0) {
      for (const file of files) {
        const result = await this.storage.uploadDocument(
          file.buffer,
          file.originalname,
          file.mimetype,
        );
        documentUrls.push(result.url);
      }
    }

    // Create verification request
    const verificationRequest = await this.prisma.verificationRequest.create({
      data: {
        plantId: dto.plantId,
        documents: JSON.stringify(documentUrls),
        notes: dto.notes,
        status: 'PENDING',
      },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        },
      },
    });

    // Notify admins via WebSocket for real-time updates
    this.syncGateway.notifyVerificationCreated({
      ...verificationRequest,
      ownerId: req.user.sub,
    });

    return verificationRequest;
  }
}
