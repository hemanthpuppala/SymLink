import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { AuthModule } from '../auth/auth.module';
import { SyncModule } from '../sync/sync.module';
import { OwnerAuthController } from './owner-auth.controller';
import { OwnerProfileController } from './owner-profile.controller';
import { OwnerPlantController } from './owner-plant.controller';
import { OwnerVerificationController } from './owner-verification.controller';
import { OwnerNotificationsController } from './owner-notifications.controller';

@Module({
  imports: [
    AuthModule,
    SyncModule,
    MulterModule.register({
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB
      },
    }),
  ],
  controllers: [
    OwnerAuthController,
    OwnerProfileController,
    OwnerPlantController,
    OwnerVerificationController,
    OwnerNotificationsController,
  ],
})
export class OwnerModule {}
