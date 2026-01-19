import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
  Request,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OwnerGuard } from '../../common/guards/owner.guard';

@Controller('v1/owner/notifications')
@UseGuards(OwnerGuard)
export class OwnerNotificationsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getNotifications(
    @Request() req: any,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('unreadOnly') unreadOnly = 'false',
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const skip = (pageNum - 1) * limitNum;
    const showUnreadOnly = unreadOnly === 'true';

    const where = {
      ownerId: req.user.sub,
      ...(showUnreadOnly && { isRead: false }),
    };

    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limitNum,
      }),
      this.prisma.notification.count({ where }),
    ]);

    const unreadCount = await this.prisma.notification.count({
      where: {
        ownerId: req.user.sub,
        isRead: false,
      },
    });

    return {
      notifications,
      unreadCount,
      meta: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  @Post(':id/read')
  async markAsRead(@Request() req: any, @Param('id') id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id,
        ownerId: req.user.sub,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    const updated = await this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });

    return updated;
  }

  @Post('read-all')
  async markAllAsRead(@Request() req: any) {
    await this.prisma.notification.updateMany({
      where: {
        ownerId: req.user.sub,
        isRead: false,
      },
      data: { isRead: true },
    });

    return { message: 'All notifications marked as read' };
  }
}
