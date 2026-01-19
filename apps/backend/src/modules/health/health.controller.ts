import { Controller, Get } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Public()
  @Get()
  async check() {
    return this.healthService.check();
  }

  @Public()
  @Get('ready')
  async readiness() {
    return this.healthService.readiness();
  }

  @Public()
  @Get('live')
  async liveness() {
    return this.healthService.liveness();
  }
}
