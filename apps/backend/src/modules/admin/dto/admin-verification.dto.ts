import { IsString, IsOptional, IsEnum } from 'class-validator';
import { RequestStatus } from '@prisma/client';

export class UpdateVerificationDto {
  @IsEnum(RequestStatus)
  status: RequestStatus;

  @IsString()
  @IsOptional()
  rejectionReason?: string;
}
