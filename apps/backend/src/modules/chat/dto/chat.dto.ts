import {
  IsString,
  IsOptional,
  IsNumber,
  IsBoolean,
  Min,
  Max,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class CreateMessageDto {
  @IsString()
  content: string;
}

export class GetMessagesQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @IsOptional()
  @IsString()
  before?: string; // Message ID for cursor pagination
}

export class UpdateRetentionDto {
  @IsNumber()
  @Min(1)
  @Max(365)
  retentionDays: number;
}

export class ConversationResponseDto {
  id: string;
  plantId: string;
  plantName: string;
  plantAddress: string;
  otherPartyName: string;
  lastMessage?: {
    content: string;
    sentAt: string;
    senderType: string;
  };
  unreadCount: number;
  createdAt: string;
}

export class MessageResponseDto {
  id: string;
  conversationId: string;
  senderType: 'consumer' | 'owner';
  senderId: string;
  content: string;
  sentAt: string;
  deliveredAt?: string;
  readAt?: string;
}

// WebSocket event DTOs
export class WsJoinConversationDto {
  conversationId: string;
}

export class WsSendMessageDto {
  conversationId: string;
  content: string;
}

export class WsTypingDto {
  conversationId: string;
  isTyping: boolean;
}

export class WsMarkReadDto {
  conversationId: string;
  messageId: string;
}
