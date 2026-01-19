import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  NotFoundException,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SyncGateway } from '../sync/sync.gateway';
import { OwnerGuard } from '../../common/guards/owner.guard';
import {
  CreatePlantDto,
  UpdatePlantDto,
  UpdatePlantStatusDto,
} from './dto/owner-plant.dto';

// Helper to parse photos JSON string to array
function parsePhotos(photos: string): string[] {
  try {
    return JSON.parse(photos);
  } catch {
    return [];
  }
}

@Controller('v1/owner/plant')
@UseGuards(OwnerGuard)
export class OwnerPlantController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly syncGateway: SyncGateway,
  ) {}

  @Get()
  async getPlants(@Request() req: any) {
    const plants = await this.prisma.plant.findMany({
      where: { ownerId: req.user.sub },
      include: {
        verificationRequests: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    return plants.map((p) => ({ ...p, photos: parsePhotos(p.photos) }));
  }

  @Get(':id')
  async getPlant(@Request() req: any, @Param('id') id: string) {
    const plant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
      include: {
        verificationRequests: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    return { ...plant, photos: parsePhotos(plant.photos) };
  }

  @Post()
  async createPlant(@Request() req: any, @Body() dto: CreatePlantDto) {
    const plant = await this.prisma.plant.create({
      data: {
        name: dto.name,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        phone: dto.phone,
        description: dto.description,
        tdsLevel: dto.tdsLevel,
        pricePerLiter: dto.pricePerLiter,
        operatingHours: dto.operatingHours,
        photos: JSON.stringify(dto.photos || []),
        ownerId: req.user.sub,
      },
    });

    const result = { ...plant, photos: parsePhotos(plant.photos) };

    // Notify all clients about new plant
    this.syncGateway.notifyPlantCreated(result);

    return result;
  }

  @Patch(':id')
  async updatePlant(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdatePlantDto,
  ) {
    const existingPlant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!existingPlant) {
      throw new NotFoundException('Plant not found');
    }

    const plant = await this.prisma.plant.update({
      where: { id },
      data: dto,
    });

    const result = { ...plant, photos: parsePhotos(plant.photos) };

    // Notify all clients about plant update
    this.syncGateway.notifyPlantUpdated(result);

    return result;
  }

  @Patch(':id/status')
  async updatePlantStatus(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdatePlantStatusDto,
  ) {
    const existingPlant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!existingPlant) {
      throw new NotFoundException('Plant not found');
    }

    const plant = await this.prisma.plant.update({
      where: { id },
      data: { isActive: dto.isActive },
    });

    return { ...plant, photos: parsePhotos(plant.photos) };
  }

  @Post(':id/photos')
  @UseInterceptors(FileInterceptor('file'))
  async uploadPhoto(
    @Request() req: any,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }

    const existingPlant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!existingPlant) {
      throw new NotFoundException('Plant not found');
    }

    const result = await this.storage.uploadPhoto(
      file.buffer,
      file.originalname,
      file.mimetype,
    );

    const currentPhotos = parsePhotos(existingPlant.photos);
    currentPhotos.push(result.url);

    const updatedPlant = await this.prisma.plant.update({
      where: { id },
      data: {
        photos: JSON.stringify(currentPhotos),
      },
    });

    return {
      url: result.url,
      photos: parsePhotos(updatedPlant.photos),
    };
  }

  @Delete(':id/photos/:photoIndex')
  async deletePhoto(
    @Request() req: any,
    @Param('id') id: string,
    @Param('photoIndex') photoIndex: string,
  ) {
    const existingPlant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!existingPlant) {
      throw new NotFoundException('Plant not found');
    }

    const photos = parsePhotos(existingPlant.photos);
    const index = parseInt(photoIndex, 10);
    if (isNaN(index) || index < 0 || index >= photos.length) {
      throw new BadRequestException('Invalid photo index');
    }

    const photoUrl = photos[index];
    const newPhotos = photos.filter((_, i) => i !== index);

    // Extract key from URL and delete from storage
    try {
      const urlParts = photoUrl.split('/');
      const key = urlParts[urlParts.length - 1];
      const bucket = urlParts[urlParts.length - 2];
      await this.storage.deleteFile(bucket, key);
    } catch (error) {
      console.error('Failed to delete file from storage:', error);
    }

    const updatedPlant = await this.prisma.plant.update({
      where: { id },
      data: { photos: JSON.stringify(newPhotos) },
    });

    return { photos: parsePhotos(updatedPlant.photos) };
  }

  @Get(':id/share')
  async getShareInfo(@Request() req: any, @Param('id') id: string) {
    const plant = await this.prisma.plant.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Generate share URLs - these would be the public profile URLs
    const baseUrl = process.env.PUBLIC_URL || 'https://flowgrid.app';
    const shareUrl = `${baseUrl}/p/${plant.id}`;

    // Generate a simple data URL for QR code (can be rendered client-side)
    // The actual QR code generation can be done client-side using the shareUrl
    const qrData = shareUrl;

    return {
      plantId: plant.id,
      plantName: plant.name,
      shareUrl,
      qrData,
      deepLink: `flowgrid://plant/${plant.id}`,
      message: `Check out ${plant.name} on FlowGrid: ${shareUrl}`,
    };
  }
}
