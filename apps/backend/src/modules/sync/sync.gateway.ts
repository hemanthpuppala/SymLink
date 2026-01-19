/**
 * SYNC GATEWAY - Real-time WebSocket-based event broadcasting
 *
 * IMPORTANT METHODOLOGY - Auto-refresh should ALWAYS use WebSocket, NOT polling:
 *
 * WHY WebSocket (Push-based) over Polling:
 * - Instant: Updates appear immediately when events occur on the server
 * - Efficient: No wasted requests when nothing has changed
 * - Scalable: Server controls when to push, clients don't hammer the API
 * - Battery-friendly: Mobile devices don't drain battery with constant polling
 *
 * HOW IT WORKS:
 * 1. Clients connect to /sync namespace with JWT token
 * 2. Clients are automatically joined to rooms based on user type (consumer/owner/admin)
 * 3. When data changes, call the appropriate notify* method
 * 4. Clients receive events and invalidate their local cache to re-fetch fresh data
 *
 * ADDING NEW REAL-TIME FEATURES:
 * 1. Create a new notify* method in this gateway
 * 2. Call it from the relevant service when data changes
 * 3. On the client, listen for the event and invalidate React Query cache
 *
 * NEVER tell clients to poll with setInterval or refetchInterval.
 * ALWAYS use this WebSocket gateway for real-time updates.
 */

import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Injectable } from '@nestjs/common';

interface AuthenticatedSocket extends Socket {
  user?: {
    sub: string;
    type: 'consumer' | 'owner' | 'admin';
    email: string;
  };
}

@Injectable()
@WebSocketGateway({
  namespace: '/sync',
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class SyncGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets: Map<string, Set<string>> = new Map();

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
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

      // Join user-specific room
      const userId = `${payload.type}:${payload.sub}`;
      client.join(userId);

      // Join type-specific room (all consumers, all owners, all admins)
      client.join(`type:${payload.type}`);

      // Track socket
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      console.log(`[Sync] Client connected: ${client.id} as ${userId}`);
    } catch (error) {
      console.error('[Sync] Auth error:', error);
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
    console.log(`[Sync] Client disconnected: ${client.id}`);
  }

  // Broadcast to all connected clients of a specific type
  broadcastToType(type: 'consumer' | 'owner' | 'admin', event: string, data: any) {
    this.server.to(`type:${type}`).emit(event, data);
  }

  // Broadcast to a specific user
  broadcastToUser(userId: string, userType: string, event: string, data: any) {
    const room = `${userType}:${userId}`;
    const socketsInRoom = this.userSockets.get(room);
    console.log(`[SyncGateway] Broadcasting ${event} to room ${room}, active sockets: ${socketsInRoom?.size ?? 0}`);
    this.server.to(room).emit(event, data);
  }

  // Broadcast to all connected clients
  broadcastToAll(event: string, data: any) {
    this.server.emit(event, data);
  }

  // Plant events
  notifyPlantCreated(plant: any) {
    this.broadcastToAll('plant:created', plant);
  }

  notifyPlantUpdated(plant: any) {
    this.broadcastToAll('plant:updated', plant);
  }

  notifyPlantDeleted(plantId: string) {
    this.broadcastToAll('plant:deleted', { id: plantId });
  }

  // Verification events
  notifyVerificationCreated(request: any) {
    this.broadcastToType('admin', 'verification:created', request);
    this.broadcastToUser(request.ownerId, 'owner', 'verification:created', request);
  }

  notifyVerificationUpdated(request: any) {
    this.broadcastToType('admin', 'verification:updated', request);
    this.broadcastToUser(request.ownerId, 'owner', 'verification:updated', request);
    // Also notify consumers if plant is now verified
    if (request.status === 'APPROVED') {
      this.broadcastToType('consumer', 'plant:verified', { plantId: request.plantId });
    }
  }

  // Message events
  notifyNewMessage(message: any, conversation: any) {
    console.log(`[SyncGateway] Notifying new message in conversation ${conversation.id}`);
    console.log(`[SyncGateway] Consumer: ${conversation.consumerId}, Owner: ${conversation.ownerId}`);

    // Notify both parties
    this.broadcastToUser(conversation.consumerId, 'consumer', 'message:new', {
      message,
      conversationId: conversation.id,
    });
    this.broadcastToUser(conversation.ownerId, 'owner', 'message:new', {
      message,
      conversationId: conversation.id,
    });

    // Notify admins for real-time chat monitoring
    this.broadcastToType('admin', 'chat:message', {
      message,
      conversationId: conversation.id,
      consumerId: conversation.consumerId,
      ownerId: conversation.ownerId,
    });
  }

  notifyConversationUpdated(conversation: any) {
    this.broadcastToUser(conversation.consumerId, 'consumer', 'conversation:updated', conversation);
    this.broadcastToUser(conversation.ownerId, 'owner', 'conversation:updated', conversation);

    // Notify admins
    this.broadcastToType('admin', 'chat:updated', conversation);
  }

  // Notify admins when a new conversation is created
  notifyConversationCreated(conversation: any) {
    this.broadcastToType('admin', 'chat:created', conversation);
  }

  notifyMessagesRead(data: {
    conversationId: string;
    messageIds: string[];
    readAt: string;
    consumerId: string;
    ownerId: string;
    readBy: 'consumer' | 'owner';
  }) {
    console.log(`[SyncGateway] notifyMessagesRead called: readBy=${data.readBy}, messageIds=${data.messageIds.length}`);
    // Notify the sender (opposite party) that their messages were read
    // If consumer read, notify owner. If owner read, notify consumer.
    if (data.readBy === 'consumer') {
      console.log(`[SyncGateway] Broadcasting messages:read to owner:${data.ownerId}`);
      this.broadcastToUser(data.ownerId, 'owner', 'messages:read', {
        conversationId: data.conversationId,
        messageIds: data.messageIds,
        readAt: data.readAt,
      });
    } else {
      console.log(`[SyncGateway] Broadcasting messages:read to consumer:${data.consumerId}`);
      this.broadcastToUser(data.consumerId, 'consumer', 'messages:read', {
        conversationId: data.conversationId,
        messageIds: data.messageIds,
        readAt: data.readAt,
      });
    }

  }

  /**
   * Notify admins about read events - ALWAYS called regardless of user read receipt settings.
   * Admins have full observability and should see all read events.
   */
  notifyMessagesReadToAdmin(data: {
    conversationId: string;
    messageIds: string[];
    readAt: string;
    consumerId: string;
    ownerId: string;
    readBy: 'consumer' | 'owner';
  }) {
    this.broadcastToType('admin', 'chat:read', data);
  }

  notifyMessageDelivered(data: {
    conversationId: string;
    messageId: string;
    deliveredAt: string;
    consumerId: string;
    ownerId: string;
    deliveredTo: 'consumer' | 'owner';
  }) {
    // Notify the sender that their message was delivered
    if (data.deliveredTo === 'consumer') {
      this.broadcastToUser(data.ownerId, 'owner', 'message:delivered', {
        conversationId: data.conversationId,
        messageId: data.messageId,
        deliveredAt: data.deliveredAt,
      });
    } else {
      this.broadcastToUser(data.consumerId, 'consumer', 'message:delivered', {
        conversationId: data.conversationId,
        messageId: data.messageId,
        deliveredAt: data.deliveredAt,
      });
    }
  }

  // Generic data refresh signal
  notifyRefresh(userType: 'consumer' | 'owner' | 'admin', dataType: string) {
    this.broadcastToType(userType, 'data:refresh', { type: dataType });
  }
}
