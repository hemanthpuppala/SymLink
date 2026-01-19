import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import {
  CreateMessageDto,
  GetMessagesQueryDto,
} from './dto/chat.dto';

@Controller('v1/owner/conversations')
export class OwnerChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  async getConversations(@Request() req: any) {
    if (req.user?.type !== 'owner') {
      throw new ForbiddenException('Only owners can access this endpoint');
    }
    return this.chatService.getOwnerConversations(req.user.sub);
  }

  @Get('unread-count')
  async getUnreadCount(@Request() req: any) {
    if (req.user?.type !== 'owner') {
      throw new ForbiddenException('Only owners can access this endpoint');
    }
    const count = await this.chatService.getOwnerUnreadCount(req.user.sub);
    return { count };
  }

  @Get(':id/messages')
  async getMessages(
    @Param('id') conversationId: string,
    @Query() query: GetMessagesQueryDto,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'owner') {
      throw new ForbiddenException('Only owners can access this endpoint');
    }
    return this.chatService.getMessages(
      conversationId,
      req.user.sub,
      'owner',
      query,
    );
  }

  @Post(':id/messages')
  async sendMessage(
    @Param('id') conversationId: string,
    @Body() dto: CreateMessageDto,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'owner') {
      throw new ForbiddenException('Only owners can access this endpoint');
    }
    return this.chatService.sendMessage(
      conversationId,
      req.user.sub,
      'owner',
      dto,
    );
  }

  @Post(':id/read')
  async markAsRead(
    @Param('id') conversationId: string,
    @Request() req: any,
  ) {
    if (req.user?.type !== 'owner') {
      throw new ForbiddenException('Only owners can access this endpoint');
    }
    await this.chatService.markAsRead(conversationId, req.user.sub, 'owner');
    return { success: true };
  }
}
