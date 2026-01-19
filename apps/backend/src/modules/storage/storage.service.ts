import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import { v4 as uuidv4 } from 'uuid';

export interface UploadResult {
  url: string;
  key: string;
  bucket: string;
}

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private client: Minio.Client;

  constructor(private readonly configService: ConfigService) {
    const useSSL = this.configService.get<string>('MINIO_USE_SSL', 'false') === 'true';

    this.client = new Minio.Client({
      endPoint: this.configService.get<string>('MINIO_ENDPOINT', 'localhost'),
      port: parseInt(this.configService.get<string>('MINIO_PORT', '9000'), 10),
      useSSL: useSSL,
      accessKey: this.configService.get<string>('MINIO_ACCESS_KEY', 'flowgrid'),
      secretKey: this.configService.get<string>(
        'MINIO_SECRET_KEY',
        'flowgrid123',
      ),
    });
  }

  async onModuleInit(): Promise<void> {
    await this.ensureBucketsExist();
  }

  private async ensureBucketsExist(): Promise<void> {
    const buckets = [
      this.configService.get<string>(
        'MINIO_BUCKET_PHOTOS',
        'flowgrid-photos',
      ),
      this.configService.get<string>(
        'MINIO_BUCKET_DOCUMENTS',
        'flowgrid-documents',
      ),
    ];

    for (const bucket of buckets) {
      try {
        const exists = await this.client.bucketExists(bucket);
        if (!exists) {
          await this.client.makeBucket(bucket);
          this.logger.log(`Created bucket: ${bucket}`);
        }
      } catch (error) {
        this.logger.warn(`Could not check/create bucket ${bucket}: ${error}`);
      }
    }
  }

  async uploadPhoto(
    file: Buffer,
    originalName: string,
    contentType: string,
  ): Promise<UploadResult> {
    const bucket = this.configService.get<string>(
      'MINIO_BUCKET_PHOTOS',
      'flowgrid-photos',
    );
    return this.upload(bucket, file, originalName, contentType);
  }

  async uploadDocument(
    file: Buffer,
    originalName: string,
    contentType: string,
  ): Promise<UploadResult> {
    const bucket = this.configService.get<string>(
      'MINIO_BUCKET_DOCUMENTS',
      'flowgrid-documents',
    );
    return this.upload(bucket, file, originalName, contentType);
  }

  private async upload(
    bucket: string,
    file: Buffer,
    originalName: string,
    contentType: string,
  ): Promise<UploadResult> {
    const extension = originalName.split('.').pop() || '';
    const key = `${uuidv4()}.${extension}`;

    await this.client.putObject(bucket, key, file, file.length, {
      'Content-Type': contentType,
    });

    const url = this.getPublicUrl(bucket, key);

    return { url, key, bucket };
  }

  async deleteFile(bucket: string, key: string): Promise<void> {
    await this.client.removeObject(bucket, key);
  }

  getPublicUrl(bucket: string, key: string): string {
    const endpoint = this.configService.get<string>(
      'MINIO_ENDPOINT',
      'localhost',
    );
    const port = parseInt(this.configService.get<string>('MINIO_PORT', '9000'), 10);
    const useSSL = this.configService.get<string>('MINIO_USE_SSL', 'false') === 'true';
    const protocol = useSSL ? 'https' : 'http';

    return `${protocol}://${endpoint}:${port}/${bucket}/${key}`;
  }

  async getPresignedUrl(
    bucket: string,
    key: string,
    expirySeconds = 3600,
  ): Promise<string> {
    return this.client.presignedGetObject(bucket, key, expirySeconds);
  }
}
