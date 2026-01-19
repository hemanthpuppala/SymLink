import { IsEmail, IsString, MinLength, IsOptional, IsEnum } from 'class-validator';
import { AdminRole } from '@prisma/client';

export class LoginAdminDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class CreateAdminDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  @MinLength(2)
  name: string;

  @IsEnum(AdminRole)
  @IsOptional()
  role?: AdminRole;
}

export class RefreshTokenDto {
  @IsString()
  refreshToken: string;
}
