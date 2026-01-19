import {
  IsString,
  IsNumber,
  IsOptional,
  IsArray,
  Min,
  Max,
  IsBoolean,
} from 'class-validator';

export class CreatePlantDto {
  @IsString()
  name: string;

  @IsString()
  address: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  tdsLevel?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  pricePerLiter?: number;

  @IsString()
  @IsOptional()
  operatingHours?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  photos?: string[];
}

export class UpdatePlantDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  address?: string;

  @IsNumber()
  @IsOptional()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsNumber()
  @IsOptional()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsNumber()
  @IsOptional()
  @Min(0)
  tdsLevel?: number;

  @IsNumber()
  @IsOptional()
  @Min(0)
  pricePerLiter?: number;

  @IsString()
  @IsOptional()
  operatingHours?: string;
}

export class UpdatePlantStatusDto {
  @IsBoolean()
  isActive: boolean;
}
