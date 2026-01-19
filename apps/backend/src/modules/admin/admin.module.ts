import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminAuthController } from './admin-auth.controller';
import { AdminVerificationController } from './admin-verification.controller';
import { AdminDashboardController } from './admin-dashboard.controller';
import { AdminPlantsController } from './admin-plants.controller';
import { AdminChatController } from './admin-chat.controller';

@Module({
  imports: [AuthModule],
  controllers: [
    AdminAuthController,
    AdminVerificationController,
    AdminDashboardController,
    AdminPlantsController,
    AdminChatController,
  ],
})
export class AdminModule {}
