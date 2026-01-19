import {
  Controller,
  Get,
  Post,
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
  SortBy,
  SortOrder,
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
    const {
      latitude,
      longitude,
      radiusKm = 10,
      limit = 50,
      verifiedOnly,
      sortBy = SortBy.DISTANCE,
      sortOrder = SortOrder.ASC,
      minTds,
      maxTds,
      minPrice,
      maxPrice,
    } = query;

    // Calculate bounding box for initial filter
    const latDelta = radiusKm / 111; // ~111km per degree latitude
    const lonDelta = radiusKm / (111 * Math.cos((latitude * Math.PI) / 180));

    // Build where clause
    const where: any = {
      isActive: true,
      latitude: {
        gte: latitude - latDelta,
        lte: latitude + latDelta,
      },
      longitude: {
        gte: longitude - lonDelta,
        lte: longitude + lonDelta,
      },
    };

    // Apply filters
    if (verifiedOnly) {
      where.isVerified = true;
    }
    if (minTds !== undefined || maxTds !== undefined) {
      where.tdsLevel = {};
      if (minTds !== undefined) where.tdsLevel.gte = minTds;
      if (maxTds !== undefined) where.tdsLevel.lte = maxTds;
    }
    if (minPrice !== undefined || maxPrice !== undefined) {
      where.pricePerLiter = {};
      if (minPrice !== undefined) where.pricePerLiter.gte = minPrice;
      if (maxPrice !== undefined) where.pricePerLiter.lte = maxPrice;
    }

    // Use Prisma query with bounding box filter
    const plants = await this.prisma.plant.findMany({
      where,
      take: limit * 2, // Fetch more to account for radius filtering
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
    let plantsWithDistance = plants
      .map((plant) => ({
        ...plant,
        photos: parsePhotos(plant.photos),
        distance: this.calculateDistance(latitude, longitude, plant.latitude, plant.longitude),
      }))
      .filter((plant) => plant.distance <= radiusKm);

    // Apply sorting
    plantsWithDistance = this.sortPlants(plantsWithDistance, sortBy, sortOrder);

    // Apply limit after sorting
    return plantsWithDistance.slice(0, limit);
  }

  @Public()
  @Get('search')
  async searchPlants(@Query() query: SearchPlantsQueryDto) {
    const {
      query: searchQuery,
      latitude,
      longitude,
      page = 1,
      limit = 20,
      verifiedOnly,
      sortBy = SortBy.DISTANCE,
      sortOrder = SortOrder.ASC,
      minTds,
      maxTds,
      minPrice,
      maxPrice,
    } = query;
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

    // Apply filters
    if (verifiedOnly) {
      where.isVerified = true;
    }
    if (minTds !== undefined || maxTds !== undefined) {
      where.tdsLevel = {};
      if (minTds !== undefined) where.tdsLevel.gte = minTds;
      if (maxTds !== undefined) where.tdsLevel.lte = maxTds;
    }
    if (minPrice !== undefined || maxPrice !== undefined) {
      where.pricePerLiter = {};
      if (minPrice !== undefined) where.pricePerLiter.gte = minPrice;
      if (maxPrice !== undefined) where.pricePerLiter.lte = maxPrice;
    }

    // Build orderBy for database-level sorting (when distance not needed)
    let orderBy: any = { name: 'asc' };
    if (sortBy === SortBy.TDS) {
      orderBy = { tdsLevel: sortOrder };
    } else if (sortBy === SortBy.PRICE) {
      orderBy = { pricePerLiter: sortOrder };
    } else if (sortBy === SortBy.NAME) {
      orderBy = { name: sortOrder };
    }

    const [plants, total] = await Promise.all([
      this.prisma.plant.findMany({
        where,
        skip,
        take: limit,
        orderBy,
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
    let plantsWithDistance = plants.map((plant) => {
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

    // Sort by distance in-memory if sorting by distance and coordinates provided
    if (sortBy === SortBy.DISTANCE && latitude !== undefined && longitude !== undefined) {
      plantsWithDistance = this.sortPlants(plantsWithDistance, sortBy, sortOrder);
    }

    return {
      plants: plantsWithDistance,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        filters: {
          verifiedOnly,
          minTds,
          maxTds,
          minPrice,
          maxPrice,
        },
        sort: {
          by: sortBy,
          order: sortOrder,
        },
      },
    };
  }

  @Public()
  @Get('share/:id')
  async getPublicProfile(@Param('id') id: string) {
    const plant = await this.prisma.plant.findFirst({
      where: {
        id,
        isActive: true,
      },
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
        owner: {
          select: {
            name: true,
          },
        },
      },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    return {
      ...plant,
      photos: parsePhotos(plant.photos),
      ownerName: plant.owner?.name ?? 'Unknown',
      shareUrl: `/plants/share/${plant.id}`,
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

    // Get view count
    const viewCount = await this.prisma.viewLog.count({
      where: { plantId: id },
    });

    return {
      ...plant,
      photos: parsePhotos(plant.photos),
      viewCount,
    };
  }

  @Public()
  @Post(':id/view')
  async recordView(@Param('id') id: string, @Request() req: any) {
    // Verify plant exists
    const plant = await this.prisma.plant.findFirst({
      where: { id, isActive: true },
    });

    if (!plant) {
      throw new NotFoundException('Plant not found');
    }

    // Record the view
    const consumerId = req.user?.sub && req.user?.type === 'consumer' ? req.user.sub : null;

    await this.prisma.viewLog.create({
      data: {
        plantId: id,
        consumerId,
      },
    });

    // Get updated view count
    const viewCount = await this.prisma.viewLog.count({
      where: { plantId: id },
    });

    return { viewCount };
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

  private sortPlants<T extends { distance?: number; tdsLevel?: number | null; pricePerLiter?: number | null; name?: string }>(
    plants: T[],
    sortBy: SortBy,
    sortOrder: SortOrder,
  ): T[] {
    const multiplier = sortOrder === SortOrder.ASC ? 1 : -1;

    return [...plants].sort((a, b) => {
      switch (sortBy) {
        case SortBy.DISTANCE:
          return ((a.distance || 0) - (b.distance || 0)) * multiplier;
        case SortBy.TDS:
          return ((a.tdsLevel || 0) - (b.tdsLevel || 0)) * multiplier;
        case SortBy.PRICE:
          return ((a.pricePerLiter || 0) - (b.pricePerLiter || 0)) * multiplier;
        case SortBy.NAME:
          return (a.name || '').localeCompare(b.name || '') * multiplier;
        default:
          return 0;
      }
    });
  }
}
