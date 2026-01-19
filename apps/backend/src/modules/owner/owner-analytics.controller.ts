import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { OwnerGuard } from '../../common/guards/owner.guard';
import { PrismaService } from '../prisma/prisma.service';

interface DailyViewCount {
  date: string;
  count: number;
}

interface AnalyticsResponse {
  totalViews: number;
  weeklyViews: number;
  dailyViews: DailyViewCount[];
  uniqueViewers: number;
  weeklyUniqueViewers: number;
}

@Controller('v1/owner/analytics')
@UseGuards(JwtAuthGuard, OwnerGuard)
export class OwnerAnalyticsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getAnalytics(@Request() req: any): Promise<AnalyticsResponse> {
    const ownerId = req.user.sub;

    // Get owner's plant
    const plant = await this.prisma.plant.findFirst({
      where: { ownerId },
      select: { id: true },
    });

    if (!plant) {
      return {
        totalViews: 0,
        weeklyViews: 0,
        dailyViews: [],
        uniqueViewers: 0,
        weeklyUniqueViewers: 0,
      };
    }

    const plantId = plant.id;
    const now = new Date();
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Get total view count
    const totalViews = await this.prisma.viewLog.count({
      where: { plantId },
    });

    // Get weekly view count
    const weeklyViews = await this.prisma.viewLog.count({
      where: {
        plantId,
        viewedAt: { gte: sevenDaysAgo },
      },
    });

    // Get unique viewers (all time)
    const uniqueViewersResult = await this.prisma.viewLog.groupBy({
      by: ['consumerId'],
      where: {
        plantId,
        consumerId: { not: null },
      },
    });
    const uniqueViewers = uniqueViewersResult.length;

    // Get unique viewers (weekly)
    const weeklyUniqueViewersResult = await this.prisma.viewLog.groupBy({
      by: ['consumerId'],
      where: {
        plantId,
        consumerId: { not: null },
        viewedAt: { gte: sevenDaysAgo },
      },
    });
    const weeklyUniqueViewers = weeklyUniqueViewersResult.length;

    // Get daily views for the last 7 days
    const dailyViews = await this.getDailyViews(plantId, sevenDaysAgo);

    return {
      totalViews,
      weeklyViews,
      dailyViews,
      uniqueViewers,
      weeklyUniqueViewers,
    };
  }

  private async getDailyViews(plantId: string, startDate: Date): Promise<DailyViewCount[]> {
    const result: DailyViewCount[] = [];
    const now = new Date();

    // Generate date range for the last 7 days
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);

      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const count = await this.prisma.viewLog.count({
        where: {
          plantId,
          viewedAt: {
            gte: date,
            lt: nextDate,
          },
        },
      });

      result.push({
        date: date.toISOString().split('T')[0],
        count,
      });
    }

    return result;
  }
}
