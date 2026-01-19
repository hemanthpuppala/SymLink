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
  }

  notifyConversationUpdated(conversation: any) {
    this.broadcastToUser(conversation.consumerId, 'consumer', 'conversation:updated', conversation);
    this.broadcastToUser(conversation.ownerId, 'owner', 'conversation:updated', conversation);
  }

  // Generic data refresh signal
  notifyRefresh(userType: 'consumer' | 'owner' | 'admin', dataType: string) {
    this.broadcastToType(userType, 'data:refresh', { type: dataType });
  }
}
