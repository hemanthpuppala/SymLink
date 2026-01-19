import {
  Controller,
  Get,
  Param,
  Query,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Public } from '../../common/decorators/public.decorator';
import {
  NearbyPlantsQueryDto,
  SearchPlantsQueryDto,
} from './dto/consumer-plant.dto';

// Helper to parse photos JSON string to array
function parsePhotos(photos: string): string[] {
  try {
    return JSON.parse(photos);
  } catch {
    return [];
  }
}

@Controller('v1/consumer/plants')
export class ConsumerPlantController {
  constructor(private readonly prisma: PrismaService) {}

  @Public()
  @Get('nearby')
  async getNearbyPlants(@Query() query: NearbyPlantsQueryDto) {
    const { latitude, longitude, radiusKm = 10, limit = 50 } = query;

    // Calculate bounding box for initial filter
    const latDelta = radiusKm / 111; // ~111km per degree latitude
    const lonDelta = radiusKm / (111 * Math.cos((latitude * Math.PI) / 180));

    // Use Prisma query with bounding box filter
    const plants = await this.prisma.plant.findMany({
      where: {
        isActive: true,
        latitude: {
          gte: latitude - latDelta,
          lte: latitude + latDelta,
        },
        longitude: {
          gte: longitude - lonDelta,
          lte: longitude + lonDelta,
        },
      },
      take: limit,
      select: {
        id: true,
        name: true,
        address: true,
        latitude: true,
        longitude: true,
        phone: true,
        description: true,
        tdsLevel: true,
        pricePerLiter: true,
        operatingHours: true,
        photos: true,
        isVerified: true,
        isActive: true,
      },
    });

    // Calculate distance and filter by radius
    const plantsWithDistance = plants
      .map((plant) => ({
        ...plant,
        photos: parsePhotos(plant.photos),
        distance: this.calculateDistance(latitude, longitude, plant.latitude, plant.longitude),
      }))
      .filter((plant) => plant.distance <= radiusKm)
      .sort((a, b) => a.distance - b.distance);

    return plantsWithDistance;
  }

  @Public()
  @Get('search')
  async searchPlants(@Query() query: SearchPlantsQueryDto) {
    const { query: searchQuery, latitude, longitude, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where: any = {
      isActive: true,
    };

    if (searchQuery) {
      // SQLite doesn't support mode: 'insensitive', use contains only
      where.OR = [
        { name: { contains: searchQuery } },
        { address: { contains: searchQuery } },
      ];
    }

    const [plants, total] = await Promise.all([
      this.prisma.plant.findMany({
        where,
        skip,
        take: limit,
        orderBy: { name: 'asc' },
        select: {
          id: true,
          name: true,
          address: true,
          latitude: true,
          longitude: true,
          phone: true,
          description: true,
          tdsLevel: true,
          pricePerLiter: true,
          operatingHours: true,
          photos: true,
          isVerified: true,
          isActive: true,
        },
      }),
      this.prisma.plant.count({ where }),
    ]);

    // Calculate distance if coordinates provided
    const plantsWithDistance = plants.map((plant) => {
      const plantWithPhotos = { ...plant, photos: parsePhotos(plant.photos) };
      if (latitude !== undefined && longitude !== undefined) {
        const distance = this.calculateDistance(
          latitude,
          longitude,
          plant.latitude,
          plant.longitude,
        );
        return { ...plantWithPhotos, distance };
      }
      return plantWithPhotos;
    });

    // Sort by distance if coordinates provided
    if (latitude !== undefined && longitude !== undefined) {
      plantsWithDistance.sort((a: any, b: any) => (a.distance || 0) - (b.distance || 0));
    }

    return {
      plants: plantsWithDistance,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  @Public()
  @Get(':id')
  async getPlantDetails(@Param('id') id: string, @Request() req: any) {
    const plant = await this.prisma.plant.findFirst({
      where: {
        id,
        isActive: true,
      },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Log view if user is authenticated
    if (req.user?.sub && req.user?.type === 'consumer') {
      await this.prisma.viewLog.create({
        data: {
          plantId: id,
          consumerId: req.user.sub,
        },
      }).catch(() => {
        // Ignore errors from view logging
      });
    }

    return {
      ...plant,
      photos: parsePhotos(plant.photos),
    };
  }

  private calculateDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(R * c * 100) / 100; // Distance in km, rounded to 2 decimals
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
