import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ChatService } from './chat.service';
import {
  WsJoinConversationDto,
  WsSendMessageDto,
  WsTypingDto,
  WsMarkReadDto,
} from './dto/chat.dto';

interface AuthenticatedSocket extends Socket {
  user?: {
    sub: string;
    type: 'consumer' | 'owner';
    email: string;
  };
}

@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets: Map<string, Set<string>> = new Map(); // userId -> socketIds

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly chatService: ChatService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token, {
        secret: this.configService.get('JWT_SECRET'),
      });

      client.user = {
        sub: payload.sub,
        type: payload.type,
        email: payload.email,
      };

      // Track user's socket connections
      const userId = `${payload.type}:${payload.sub}`;
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      // Join user's personal room for notifications
      client.join(userId);

      console.log(`Client connected: ${client.id} as ${userId}`);
    } catch (error) {
      console.error('WebSocket auth error:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    if (client.user) {
      const userId = `${client.user.type}:${client.user.sub}`;
      const sockets = this.userSockets.get(userId);
      if (sockets) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
        }
      }
    }
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsJoinConversationDto,
  ) {
    if (!client.user) {
      return { error: 'Not authenticated' };
    }

    const hasAccess = await this.chatService.verifyConversationAccess(
      data.conversationId,
      client.user.sub,
      client.user.type,
    );

    if (!hasAccess) {
      return { error: 'Access denied' };
    }

    client.join(`conversation:${data.conversationId}`);
    return { success: true };
  }

  @SubscribeMessage('leave_conversation')
  handleLeaveConversation(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsJoinConversationDto,
  ) {
    client.leave(`conversation:${data.conversationId}`);
    return { success: true };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsSendMessageDto,
  ) {
    if (!client.user) {
      return { error: 'Not authenticated' };
    }

    try {
      const message = await this.chatService.sendMessage(
        data.conversationId,
        client.user.sub,
        client.user.type,
        { content: data.content },
      );

      // Emit to all clients in the conversation room
      this.server
        .to(`conversation:${data.conversationId}`)
        .emit('new_message', message);

      return { success: true, message };
    } catch (error: any) {
      return { error: error.message };
    }
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsTypingDto,
  ) {
    if (!client.user) {
      return { error: 'Not authenticated' };
    }

    // Broadcast typing status to other participants
    client.to(`conversation:${data.conversationId}`).emit('user_typing', {
      conversationId: data.conversationId,
      userId: client.user.sub,
      userType: client.user.type,
      isTyping: data.isTyping,
    });

    return { success: true };
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsMarkReadDto,
  ) {
    if (!client.user) {
      return { error: 'Not authenticated' };
    }

    try {
      await this.chatService.markMessageAsRead(data.messageId);

      // Notify the sender that their message was read
      this.server.to(`conversation:${data.conversationId}`).emit('message_read', {
        conversationId: data.conversationId,
        messageId: data.messageId,
        readAt: new Date().toISOString(),
      });

      return { success: true };
    } catch (error: any) {
      return { error: error.message };
    }
  }

  @SubscribeMessage('mark_delivered')
  async handleMarkDelivered(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: WsMarkReadDto,
  ) {
    if (!client.user) {
      return { error: 'Not authenticated' };
    }

    try {
      await this.chatService.markMessageAsDelivered(data.messageId);

      // Notify the sender that their message was delivered
      this.server
        .to(`conversation:${data.conversationId}`)
        .emit('message_delivered', {
          conversationId: data.conversationId,
          messageId: data.messageId,
          deliveredAt: new Date().toISOString(),
        });

      return { success: true };
    } catch (error: any) {
      return { error: error.message };
    }
  }

  // Helper method to send notification to a specific user
  sendToUser(userId: string, userType: 'consumer' | 'owner', event: string, data: any) {
    this.server.to(`${userType}:${userId}`).emit(event, data);
  }
}
