import { IsNumber, IsOptional, IsString, Min, Max, IsBoolean, IsEnum } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export enum SortBy {
  DISTANCE = 'distance',
  TDS = 'tds',
  PRICE = 'price',
  NAME = 'name',
}

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

export class NearbyPlantsQueryDto {
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0.1)
  @Max(100)
  radiusKm?: number = 10;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  @IsOptional()
  verifiedOnly?: boolean;

  @IsEnum(SortBy)
  @IsOptional()
  sortBy?: SortBy = SortBy.DISTANCE;

  @IsEnum(SortOrder)
  @IsOptional()
  sortOrder?: SortOrder = SortOrder.ASC;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  minTds?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  maxTds?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  minPrice?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  maxPrice?: number;
}

export class SearchPlantsQueryDto {
  @IsString()
  @IsOptional()
  query?: string;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(1)
  page?: number = 1;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  @IsOptional()
  verifiedOnly?: boolean;

  @IsEnum(SortBy)
  @IsOptional()
  sortBy?: SortBy = SortBy.DISTANCE;

  @IsEnum(SortOrder)
  @IsOptional()
  sortOrder?: SortOrder = SortOrder.ASC;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  minTds?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  maxTds?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  minPrice?: number;

  @Type(() => Number)
  @IsNumber()
  @IsOptional()
  @Min(0)
  maxPrice?: number;
}
