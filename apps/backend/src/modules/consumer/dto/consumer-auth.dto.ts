import { IsEmail, IsString, MinLength, IsOptional, Matches, MaxLength } from 'class-validator';

export class RegisterConsumerDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(3)
  @MaxLength(20)
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'Display name can only contain letters, numbers, and underscores',
  })
  displayName: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsString()
  @MinLength(2)
  name: string;

  @IsString()
  @IsOptional()
  phone?: string;
}

export class CheckDisplayNameDto {
  @IsString()
  @MinLength(3)
  @MaxLength(20)
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'Display name can only contain letters, numbers, and underscores',
  })
  displayName: string;
}

export class LoginConsumerDto {
  @IsEmail()
  email: string;

  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @IsString()
  refreshToken: string;
}
