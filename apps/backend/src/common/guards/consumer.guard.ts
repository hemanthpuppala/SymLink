import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { JwtPayload } from '../../modules/auth/auth.service';

@Injectable()
export class ConsumerGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user as JwtPayload;

    if (!user || user.type !== 'consumer') {
      throw new ForbiddenException('Consumer access required');
    }

    return true;
  }
}
