import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AdminGuard } from '../../common/guards/admin.guard';

@Controller('v1/admin/chat')
@UseGuards(AdminGuard)
export class AdminChatController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get chat statistics for admin dashboard
   */
  @Get('stats')
  async getChatStats() {
    const [
      totalConversations,
      totalMessages,
      messagesLast24h,
      messagesLast7d,
      unreadMessages,
    ] = await Promise.all([
      this.prisma.conversation.count(),
      this.prisma.message.count(),
      this.prisma.message.count({
        where: {
          sentAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
        },
      }),
      this.prisma.message.count({
        where: {
          sentAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
      }),
      this.prisma.message.count({
        where: { readAt: null },
      }),
    ]);

    // Get message delivery stats
    const deliveredMessages = await this.prisma.message.count({
      where: { deliveredAt: { not: null } },
    });

    const readMessages = await this.prisma.message.count({
      where: { readAt: { not: null } },
    });

    return {
      totalConversations,
      totalMessages,
      messagesLast24h,
      messagesLast7d,
      unreadMessages,
      deliveredMessages,
      readMessages,
      deliveryRate: totalMessages > 0
        ? Math.round((deliveredMessages / totalMessages) * 100)
        : 0,
      readRate: totalMessages > 0
        ? Math.round((readMessages / totalMessages) * 100)
        : 0,
    };
  }

  /**
   * Get all conversations with full metadata
   */
  @Get('conversations')
  async getConversations(
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('search') search?: string,
    @Query('plantId') plantId?: string,
    @Query('ownerId') ownerId?: string,
    @Query('consumerId') consumerId?: string,
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    const skip = (pageNum - 1) * limitNum;

    const where: any = {};

    if (plantId) {
      where.plantId = plantId;
    }
    if (ownerId) {
      where.ownerId = ownerId;
    }
    if (consumerId) {
      where.consumerId = consumerId;
    }
    if (search) {
      where.OR = [
        { plant: { name: { contains: search, mode: 'insensitive' } } },
        { owner: { name: { contains: search, mode: 'insensitive' } } },
        { consumer: { name: { contains: search, mode: 'insensitive' } } },
        { consumer: { displayName: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [conversations, total] = await Promise.all([
      this.prisma.conversation.findMany({
        where,
        include: {
          plant: {
            select: {
              id: true,
              name: true,
              address: true,
            },
          },
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
          consumer: {
            select: {
              id: true,
              name: true,
              email: true,
              displayName: true,
            },
          },
          messages: {
            orderBy: { sentAt: 'desc' },
            take: 1,
          },
          _count: {
            select: {
              messages: true,
            },
          },
        },
        orderBy: { lastMessageAt: 'desc' },
        skip,
        take: limitNum,
      }),
      this.prisma.conversation.count({ where }),
    ]);

    // Enrich with unread counts
    const enrichedConversations = await Promise.all(
      conversations.map(async (conv) => {
        const [unreadFromConsumer, unreadFromOwner] = await Promise.all([
          this.prisma.message.count({
            where: {
              conversationId: conv.id,
              senderType: 'consumer',
              readAt: null,
            },
          }),
          this.prisma.message.count({
            where: {
              conversationId: conv.id,
              senderType: 'owner',
              readAt: null,
            },
          }),
        ]);

        const lastMessage = conv.messages[0];

        return {
          id: conv.id,
          createdAt: conv.createdAt.toISOString(),
          lastMessageAt: conv.lastMessageAt?.toISOString(),
          plant: conv.plant,
          owner: conv.owner,
          consumer: conv.consumer,
          messageCount: conv._count.messages,
          unreadFromConsumer,
          unreadFromOwner,
          lastMessage: lastMessage
            ? {
                content: lastMessage.content,
                senderType: lastMessage.senderType,
                sentAt: lastMessage.sentAt.toISOString(),
                deliveredAt: lastMessage.deliveredAt?.toISOString(),
                readAt: lastMessage.readAt?.toISOString(),
              }
            : null,
        };
      }),
    );

    return {
      conversations: enrichedConversations,
      meta: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  /**
   * Get full conversation with all messages and complete metadata
   */
  @Get('conversations/:conversationId')
  async getConversationDetail(
    @Param('conversationId') conversationId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '100',
  ) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
            isVerified: true,
          },
        },
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        consumer: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            displayName: true,
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(200, Math.max(1, parseInt(limit, 10) || 100));
    const skip = (pageNum - 1) * limitNum;

    const [messages, totalMessages] = await Promise.all([
      this.prisma.message.findMany({
        where: { conversationId },
        orderBy: { sentAt: 'asc' },
        skip,
        take: limitNum,
      }),
      this.prisma.message.count({ where: { conversationId } }),
    ]);

    // Get message statistics for this conversation
    const [
      totalFromConsumer,
      totalFromOwner,
      deliveredCount,
      readCount,
    ] = await Promise.all([
      this.prisma.message.count({
        where: { conversationId, senderType: 'consumer' },
      }),
      this.prisma.message.count({
        where: { conversationId, senderType: 'owner' },
      }),
      this.prisma.message.count({
        where: { conversationId, deliveredAt: { not: null } },
      }),
      this.prisma.message.count({
        where: { conversationId, readAt: { not: null } },
      }),
    ]);

    return {
      conversation: {
        id: conversation.id,
        createdAt: conversation.createdAt.toISOString(),
        lastMessageAt: conversation.lastMessageAt?.toISOString(),
        plant: conversation.plant,
        owner: conversation.owner,
        consumer: conversation.consumer,
      },
      statistics: {
        totalMessages,
        totalFromConsumer,
        totalFromOwner,
        deliveredCount,
        readCount,
        deliveryRate: totalMessages > 0
          ? Math.round((deliveredCount / totalMessages) * 100)
          : 0,
        readRate: totalMessages > 0
          ? Math.round((readCount / totalMessages) * 100)
          : 0,
      },
      messages: messages.map((msg) => ({
        id: msg.id,
        senderType: msg.senderType,
        senderId: msg.senderId,
        content: msg.content,
        sentAt: msg.sentAt.toISOString(),
        deliveredAt: msg.deliveredAt?.toISOString(),
        readAt: msg.readAt?.toISOString(),
        // Calculate response times
        deliveryDelayMs: msg.deliveredAt
          ? msg.deliveredAt.getTime() - msg.sentAt.getTime()
          : null,
        readDelayMs: msg.readAt
          ? msg.readAt.getTime() - msg.sentAt.getTime()
          : null,
      })),
      meta: {
        page: pageNum,
        limit: limitNum,
        total: totalMessages,
        totalPages: Math.ceil(totalMessages / limitNum),
      },
    };
  }

  /**
   * Get all messages from a specific user (consumer or owner)
   */
  @Get('messages/by-user/:userType/:userId')
  async getMessagesByUser(
    @Param('userType') userType: 'consumer' | 'owner',
    @Param('userId') userId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '50',
  ) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
    const skip = (pageNum - 1) * limitNum;

    const where = {
      senderType: userType,
      senderId: userId,
    };

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where,
        include: {
          conversation: {
            include: {
              plant: { select: { name: true } },
              owner: { select: { name: true } },
              consumer: { select: { displayName: true } },
            },
          },
        },
        orderBy: { sentAt: 'desc' },
        skip,
        take: limitNum,
      }),
      this.prisma.message.count({ where }),
    ]);

    return {
      messages: messages.map((msg) => ({
        id: msg.id,
        conversationId: msg.conversationId,
        content: msg.content,
        sentAt: msg.sentAt.toISOString(),
        deliveredAt: msg.deliveredAt?.toISOString(),
        readAt: msg.readAt?.toISOString(),
        conversation: {
          plantName: msg.conversation.plant.name,
          ownerName: msg.conversation.owner.name,
          consumerName: msg.conversation.consumer.displayName,
        },
      })),
      meta: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  /**
   * Export conversation data (for compliance/audit purposes)
   */
  @Get('conversations/:conversationId/export')
  async exportConversation(@Param('conversationId') conversationId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        plant: true,
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        consumer: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            displayName: true,
          },
        },
        messages: {
          orderBy: { sentAt: 'asc' },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return {
      exportedAt: new Date().toISOString(),
      conversation: {
        id: conversation.id,
        createdAt: conversation.createdAt.toISOString(),
        lastMessageAt: conversation.lastMessageAt?.toISOString(),
      },
      participants: {
        plant: conversation.plant,
        owner: conversation.owner,
        consumer: conversation.consumer,
      },
      messages: conversation.messages.map((msg) => ({
        id: msg.id,
        senderType: msg.senderType,
        senderId: msg.senderId,
        content: msg.content,
        timestamps: {
          sent: msg.sentAt.toISOString(),
          delivered: msg.deliveredAt?.toISOString() ?? null,
          read: msg.readAt?.toISOString() ?? null,
        },
        metadata: {
          deliveryDelayMs: msg.deliveredAt
            ? msg.deliveredAt.getTime() - msg.sentAt.getTime()
            : null,
          readDelayMs: msg.readAt
            ? msg.readAt.getTime() - msg.sentAt.getTime()
            : null,
        },
      })),
      summary: {
        totalMessages: conversation.messages.length,
        messagesFromConsumer: conversation.messages.filter(
          (m) => m.senderType === 'consumer',
        ).length,
        messagesFromOwner: conversation.messages.filter(
          (m) => m.senderType === 'owner',
        ).length,
        deliveredCount: conversation.messages.filter(
          (m) => m.deliveredAt !== null,
        ).length,
        readCount: conversation.messages.filter(
          (m) => m.readAt !== null,
        ).length,
      },
    };
  }
}
