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

      // Notify admins of new conversation
      this.syncGateway.notifyConversationCreated({
        id: conversation.id,
        consumerId,
        ownerId: plant.ownerId,
        plantId,
        plantName: plant.name,
        ownerName: plant.owner.name,
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
    // Include readReceiptsEnabled to respect privacy settings
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
            readReceiptsEnabled: true,
          },
        },
        owner: {
          select: {
            id: true,
            name: true,
            readReceiptsEnabled: true,
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

    // Check if the OTHER party has read receipts enabled
    // readReceiptsEnabled means "allow others to see when I've read their messages"
    // So we check the READER's setting (opposite party) to decide if we show readAt
    const otherPartyReadReceiptsEnabled = userType === 'consumer'
      ? conversation.owner.readReceiptsEnabled
      : conversation.consumer.readReceiptsEnabled;

    return {
      messages: messages.reverse().map((msg) => {
        // For messages I SENT, show readAt only if the other party has read receipts enabled
        // For messages I RECEIVED, readAt is irrelevant (I'm the one who read them)
        const isMyMessage = msg.senderType === userType;
        const shouldShowReadAt = isMyMessage ? otherPartyReadReceiptsEnabled : true;

        return {
          id: msg.id,
          conversationId: msg.conversationId,
          senderType: msg.senderType as 'consumer' | 'owner',
          senderId: msg.senderId,
          content: msg.content,
          sentAt: msg.sentAt.toISOString(),
          deliveredAt: msg.deliveredAt?.toISOString(),
          readAt: shouldShowReadAt ? msg.readAt?.toISOString() : undefined,
        };
      }),
      hasMore,
      conversation: conversationInfo,
    };
  }

  /**
   * Send a message in a conversation.
   *
   * IMPORTANT: Message delivery is UNCONDITIONAL and NEVER checks readReceiptsEnabled.
   * Read receipt settings only control whether the sender sees "read" indicators,
   * NOT whether messages are delivered. Messages must ALWAYS be delivered to the recipient.
   */
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
    const readAt = new Date();

    console.log(`[ChatService] markAsRead: conversationId=${conversationId}, userType=${userType}, otherPartyType=${otherPartyType}`);

    // Get the unread message IDs first (for emitting read receipts)
    const unreadMessages = await this.prisma.message.findMany({
      where: {
        conversationId,
        senderType: otherPartyType,
        readAt: null,
      },
      select: { id: true },
    });

    console.log(`[ChatService] Found ${unreadMessages.length} unread messages from ${otherPartyType}`);

    if (unreadMessages.length === 0) {
      console.log('[ChatService] No unread messages to mark as read');
      return;
    }

    const messageIds = unreadMessages.map((m) => m.id);
    console.log(`[ChatService] Message IDs to mark as read: ${messageIds.join(', ')}`);

    // Update all unread messages
    await this.prisma.message.updateMany({
      where: {
        id: { in: messageIds },
      },
      data: {
        readAt, // Always update for internal tracking (badge counts)
      },
    });

    // Notify both parties that conversation was updated (for badge refresh)
    this.syncGateway.notifyConversationUpdated({
      id: conversationId,
      consumerId: conversation.consumerId,
      ownerId: conversation.ownerId,
      readBy: userType,
      messagesRead: messageIds.length,
      readReceiptsEnabled, // Only show "read" status to sender if reader has this enabled
    });

    // IMPORTANT: readReceiptsEnabled controls whether the OTHER USER sees the "read" indicator.
    // It should NEVER affect message delivery - messages must always be delivered regardless.
    // The readAt timestamp is ALWAYS saved in DB (for internal tracking like badge counts).
    // We only skip emitting the WebSocket event to the sender if reader disabled read receipts.

    console.log(`[ChatService] readReceiptsEnabled=${readReceiptsEnabled}`);

    // Always notify admins about read events (admins have full observability)
    this.syncGateway.notifyMessagesReadToAdmin({
      conversationId,
      messageIds,
      readAt: readAt.toISOString(),
      consumerId: conversation.consumerId,
      ownerId: conversation.ownerId,
      readBy: userType,
    });

    // Only emit to the sender if the reader has read receipts enabled
    if (readReceiptsEnabled) {
      console.log(`[ChatService] Emitting notifyMessagesRead for ${messageIds.length} messages`);
      this.syncGateway.notifyMessagesRead({
        conversationId,
        messageIds,
        readAt: readAt.toISOString(),
        consumerId: conversation.consumerId,
        ownerId: conversation.ownerId,
        readBy: userType,
      });
    } else {
      console.log('[ChatService] Read receipts disabled for user, not emitting to sender');
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
