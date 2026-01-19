import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  Request,
  UseGuards,
  ForbiddenException,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import {
  CreateMessageDto,
  GetMessagesQueryDto,
} from './dto/chat.dto';

@Controller('v1/consumer/conversations')
export class ConsumerChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  async getConversations(@Request() req: any) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    return this.chatService.getConsumerConversations(req.user.sub);
  }

  @Get('unread-count')
  async getUnreadCount(@Request() req: any) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    const count = await this.chatService.getConsumerUnreadCount(req.user.sub);
    return { count };
  }

  @Get('plant/:plantId')
  async getOrCreateConversation(
    @Param('plantId') plantId: string,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    return this.chatService.getOrCreateConversation(req.user.sub, plantId);
  }

  @Get(':id/messages')
  async getMessages(
    @Param('id') conversationId: string,
    @Query() query: GetMessagesQueryDto,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    return this.chatService.getMessages(
      conversationId,
      req.user.sub,
      'consumer',
      query,
    );
  }

  @Post(':id/messages')
  async sendMessage(
    @Param('id') conversationId: string,
    @Body() dto: CreateMessageDto,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    return this.chatService.sendMessage(
      conversationId,
      req.user.sub,
      'consumer',
      dto,
    );
  }

  @Post(':id/read')
  async markAsRead(
    @Param('id') conversationId: string,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'consumer') {
      throw new ForbiddenException('Only consumers can access this endpoint');
    }
    await this.chatService.markAsRead(conversationId, req.user.sub, 'consumer');
    return { success: true };
  }
}
