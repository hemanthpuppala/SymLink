import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ConsumerAuthController } from './consumer-auth.controller';
import { ConsumerPlantController } from './consumer-plant.controller';
import { ConsumerProfileController } from './consumer-profile.controller';

@Module({
  imports: [AuthModule],
  controllers: [ConsumerAuthController, ConsumerPlantController, ConsumerProfileController],
})
export class ConsumerModule {}
