import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncGateway } from '../sync/sync.gateway';
import {
  CreateMessageDto,
  GetMessagesQueryDto,
  ConversationResponseDto,
  MessageResponseDto,
} from './dto/chat.dto';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly syncGateway: SyncGateway,
  ) {}

  // Consumer methods
  async getConsumerConversations(consumerId: string): Promise<ConversationResponseDto[]> {
    const conversations = await this.prisma.conversation.findMany({
      where: { consumerId },
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
          },
        },
        messages: {
          orderBy: { sentAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: 'desc' },
    });

    return Promise.all(
      conversations.map(async (conv) => {
        const unreadCount = await this.prisma.message.count({
          where: {
            conversationId: conv.id,
            senderType: 'owner',
            readAt: null,
          },
        });

        const lastMessage = conv.messages[0];

        return {
          id: conv.id,
          plantId: conv.plant.id,
          plantName: conv.plant.name,
          plantAddress: conv.plant.address,
          otherPartyName: conv.owner.name,
          lastMessage: lastMessage
            ? {
                content: lastMessage.content,
                sentAt: lastMessage.sentAt.toISOString(),
                senderType: lastMessage.senderType,
              }
            : undefined,
          unreadCount,
          createdAt: conv.createdAt.toISOString(),
        };
      }),
    );
  }

  async getOrCreateConversation(
    consumerId: string,
    plantId: string,
  ): Promise<ConversationResponseDto> {
    // Check if plant exists and get owner info
    const plant = await this.prisma.plant.findUnique({
      where: { id: plantId },
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

    // Find or create conversation
    let conversation = await this.prisma.conversation.findUnique({
      where: {
        consumerId_plantId: {
          consumerId,
          plantId,
        },
      },
    });

    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: {
          consumerId,
          ownerId: plant.ownerId,
          plantId,
        },
      });
    }

    const unreadCount = await this.prisma.message.count({
      where: {
        conversationId: conversation.id,
        senderType: 'owner',
        readAt: null,
      },
    });

    return {
      id: conversation.id,
      plantId: plant.id,
      plantName: plant.name,
      plantAddress: plant.address,
      otherPartyName: plant.owner.name,
      unreadCount,
      createdAt: conversation.createdAt.toISOString(),
    };
  }

  async getMessages(
    conversationId: string,
    userId: string,
    userType: 'consumer' | 'owner',
    query: GetMessagesQueryDto,
  ): Promise<{ messages: MessageResponseDto[]; hasMore: boolean; conversation: any }> {
    // Verify access and get conversation with related data
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
          },
        },
        consumer: {
          select: {
            id: true,
            displayName: true,
          },
        },
        owner: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      (userType === 'consumer' && conversation.consumerId !== userId) ||
      (userType === 'owner' && conversation.ownerId !== userId)
    ) {
      throw new ForbiddenException('Access denied to this conversation');
    }

    const { page = 1, limit = 50, before } = query;

    const whereClause: any = {
      conversationId,
    };

    if (before) {
      const beforeMessage = await this.prisma.message.findUnique({
        where: { id: before },
      });
      if (beforeMessage) {
        whereClause.sentAt = { lt: beforeMessage.sentAt };
      }
    }

    const messages = await this.prisma.message.findMany({
      where: whereClause,
      orderBy: { sentAt: 'desc' },
      take: limit + 1, // Get one extra to check if there are more
      skip: before ? 0 : (page - 1) * limit,
    });

    const hasMore = messages.length > limit;
    if (hasMore) {
      messages.pop(); // Remove the extra message
    }

    // Build conversation info based on user type
    const conversationInfo = {
      id: conversation.id,
      plantId: conversation.plant.id,
      plantName: conversation.plant.name,
      plantAddress: conversation.plant.address,
      // For consumers: show plant/owner name, for owners: show consumer displayName
      otherPartyName: userType === 'consumer'
        ? conversation.owner.name
        : conversation.consumer.displayName,
    };

    return {
      messages: messages.reverse().map((msg) => ({
        id: msg.id,
        conversationId: msg.conversationId,
        senderType: msg.senderType as 'consumer' | 'owner',
        senderId: msg.senderId,
        content: msg.content,
        sentAt: msg.sentAt.toISOString(),
        deliveredAt: msg.deliveredAt?.toISOString(),
        readAt: msg.readAt?.toISOString(),
      })),
      hasMore,
      conversation: conversationInfo,
    };
  }

  async sendMessage(
    conversationId: string,
    userId: string,
    userType: 'consumer' | 'owner',
    dto: CreateMessageDto,
  ): Promise<MessageResponseDto> {
    // Verify access
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      (userType === 'consumer' && conversation.consumerId !== userId) ||
      (userType === 'owner' && conversation.ownerId !== userId)
    ) {
      throw new ForbiddenException('Access denied to this conversation');
    }

    // Create message
    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderType: userType,
        senderId: userId,
        content: dto.content,
      },
    });

    // Update conversation's lastMessageAt
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { lastMessageAt: message.sentAt },
    });

    // Create notification for the other party
    if (userType === 'consumer') {
      await this.prisma.notification.create({
        data: {
          ownerId: conversation.ownerId,
          type: 'NEW_MESSAGE',
          title: 'New Message',
          message: `You have a new message`,
        },
      });
    }

    const messageResponse = {
      id: message.id,
      conversationId: message.conversationId,
      senderType: message.senderType as 'consumer' | 'owner',
      senderId: message.senderId,
      content: message.content,
      sentAt: message.sentAt.toISOString(),
      deliveredAt: message.deliveredAt?.toISOString(),
      readAt: message.readAt?.toISOString(),
    };

    // Real-time notification via WebSocket
    this.syncGateway.notifyNewMessage(messageResponse, conversation);

    return messageResponse;
  }

  async markAsRead(
    conversationId: string,
    userId: string,
    userType: 'consumer' | 'owner',
  ): Promise<void> {
    // Verify access
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    if (
      (userType === 'consumer' && conversation.consumerId !== userId) ||
      (userType === 'owner' && conversation.ownerId !== userId)
    ) {
      throw new ForbiddenException('Access denied to this conversation');
    }

    // Check if the reader has read receipts enabled
    let readReceiptsEnabled = true;
    if (userType === 'consumer') {
      const consumer = await this.prisma.consumer.findUnique({
        where: { id: userId },
        select: { readReceiptsEnabled: true },
      });
      readReceiptsEnabled = consumer?.readReceiptsEnabled ?? true;
    } else {
      const owner = await this.prisma.owner.findUnique({
        where: { id: userId },
        select: { readReceiptsEnabled: true },
      });
      readReceiptsEnabled = owner?.readReceiptsEnabled ?? true;
    }

    // Mark all messages from the other party as read
    const otherPartyType = userType === 'consumer' ? 'owner' : 'consumer';

    const result = await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderType: otherPartyType,
        readAt: null,
      },
      data: {
        readAt: new Date(), // Always update for internal tracking (badge counts)
      },
    });

    // Notify both parties that conversation was updated (for badge refresh)
    if (result.count > 0) {
      this.syncGateway.notifyConversationUpdated({
        id: conversationId,
        consumerId: conversation.consumerId,
        ownerId: conversation.ownerId,
        readBy: userType,
        messagesRead: result.count,
        readReceiptsEnabled, // Only show "read" status to sender if reader has this enabled
      });
    }
  }

  async markMessageAsDelivered(messageId: string): Promise<void> {
    await this.prisma.message.update({
      where: { id: messageId },
      data: { deliveredAt: new Date() },
    });
  }

  async markMessageAsRead(messageId: string): Promise<void> {
    await this.prisma.message.update({
      where: { id: messageId },
      data: { readAt: new Date() },
    });
  }

  // Owner methods
  async getOwnerConversations(ownerId: string): Promise<ConversationResponseDto[]> {
    const conversations = await this.prisma.conversation.findMany({
      where: { ownerId },
      include: {
        plant: {
          select: {
            id: true,
            name: true,
            address: true,
          },
        },
        consumer: {
          select: {
            id: true,
            displayName: true,
          },
        },
        messages: {
          orderBy: { sentAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { lastMessageAt: 'desc' },
    });

    return Promise.all(
      conversations.map(async (conv) => {
        const unreadCount = await this.prisma.message.count({
          where: {
            conversationId: conv.id,
            senderType: 'consumer',
            readAt: null,
          },
        });

        const lastMessage = conv.messages[0];

        return {
          id: conv.id,
          plantId: conv.plant.id,
          plantName: conv.plant.name,
          plantAddress: conv.plant.address,
          otherPartyName: conv.consumer.displayName, // Use displayName for privacy
          lastMessage: lastMessage
            ? {
                content: lastMessage.content,
                sentAt: lastMessage.sentAt.toISOString(),
                senderType: lastMessage.senderType,
              }
            : undefined,
          unreadCount,
          createdAt: conv.createdAt.toISOString(),
        };
      }),
    );
  }

  async getOwnerUnreadCount(ownerId: string): Promise<number> {
    const conversations = await this.prisma.conversation.findMany({
      where: { ownerId },
      select: { id: true },
    });

    const count = await this.prisma.message.count({
      where: {
        conversationId: { in: conversations.map((c) => c.id) },
        senderType: 'consumer',
        readAt: null,
      },
    });

    return count;
  }

  async getConsumerUnreadCount(consumerId: string): Promise<number> {
    const conversations = await this.prisma.conversation.findMany({
      where: { consumerId },
      select: { id: true },
    });

    const count = await this.prisma.message.count({
      where: {
        conversationId: { in: conversations.map((c) => c.id) },
        senderType: 'owner',
        readAt: null,
      },
    });

    return count;
  }

  // Helper to verify conversation access
  async verifyConversationAccess(
    conversationId: string,
    userId: string,
    userType: 'consumer' | 'owner',
  ): Promise<boolean> {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      return false;
    }

    if (userType === 'consumer') {
      return conversation.consumerId === userId;
    }

    return conversation.ownerId === userId;
  }
}
