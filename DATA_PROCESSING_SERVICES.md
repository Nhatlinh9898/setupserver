# Data Processing Services

## Tổng Quan

Các services xử lý data cho server:
- **Compression Service**: Nén/giải nén data
- **Encryption Service**: Mã hóa/giải mã data
- **ID Encryption Service**: Mã hóa ID để cung cấp cho app
- **Classification Service**: Phân loại data
- **Version Control Service**: Quản lý phiên bản data
- **Storage Service**: Quản lý lưu trữ trên các ổ cứng

## 1. Compression Service

### File: `services/compression.service.ts`

```typescript
import { createReadStream, createWriteStream, promises as fs } from 'fs';
import { createGzip, createGunzip, createBrotliCompress, createBrotliDecompress } from 'zlib';
import { pipeline } from 'stream/promises';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export type CompressionAlgorithm = 'gzip' | 'brotli' | 'zstd' | 'lz4';

export interface CompressionOptions {
  algorithm: CompressionAlgorithm;
  level: number; // 1-9 for gzip/brotli, 1-19 for zstd
  deleteOriginal?: boolean;
}

export interface CompressionResult {
  originalSize: number;
  compressedSize: number;
  compressionRatio: number;
  timeTaken: number;
}

export class CompressionService {
  async compressFile(
    inputPath: string,
    outputPath: string,
    options: CompressionOptions
  ): Promise<CompressionResult> {
    const startTime = Date.now();
    const stats = await fs.stat(inputPath);
    const originalSize = stats.size;

    switch (options.algorithm) {
      case 'gzip':
        await this.compressGzip(inputPath, outputPath, options.level);
        break;
      case 'brotli':
        await this.compressBrotli(inputPath, outputPath, options.level);
        break;
      case 'zstd':
        await this.compressZstd(inputPath, outputPath, options.level);
        break;
      case 'lz4':
        await this.compressLz4(inputPath, outputPath);
        break;
      default:
        throw new Error(`Unsupported compression algorithm: ${options.algorithm}`);
    }

    const compressedStats = await fs.stat(outputPath);
    const compressedSize = compressedStats.size;
    const timeTaken = Date.now() - startTime;

    if (options.deleteOriginal) {
      await fs.unlink(inputPath);
    }

    return {
      originalSize,
      compressedSize,
      compressionRatio: compressedSize / originalSize,
      timeTaken,
    };
  }

  async decompressFile(
    inputPath: string,
    outputPath: string,
    algorithm: CompressionAlgorithm
  ): Promise<void> {
    switch (algorithm) {
      case 'gzip':
        await this.decompressGzip(inputPath, outputPath);
        break;
      case 'brotli':
        await this.decompressBrotli(inputPath, outputPath);
        break;
      case 'zstd':
        await this.decompressZstd(inputPath, outputPath);
        break;
      case 'lz4':
        await this.decompressLz4(inputPath, outputPath);
        break;
      default:
        throw new Error(`Unsupported compression algorithm: ${algorithm}`);
    }
  }

  private async compressGzip(inputPath: string, outputPath: string, level: number): Promise<void> {
    const readStream = createReadStream(inputPath);
    const writeStream = createWriteStream(outputPath);
    const gzip = createGzip({ level });

    await pipeline(readStream, gzip, writeStream);
  }

  private async decompressGzip(inputPath: string, outputPath: string): Promise<void> {
    const readStream = createReadStream(inputPath);
    const writeStream = createWriteStream(outputPath);
    const gunzip = createGunzip();

    await pipeline(readStream, gunzip, writeStream);
  }

  private async compressBrotli(inputPath: string, outputPath: string, level: number): Promise<void> {
    const readStream = createReadStream(inputPath);
    const writeStream = createWriteStream(outputPath);
    const brotli = createBrotliCompress({ 
      params: {
        [require('zlib').constants.BROTLI_PARAM_QUALITY]: level,
      },
    });

    await pipeline(readStream, brotli, writeStream);
  }

  private async decompressBrotli(inputPath: string, outputPath: string): Promise<void> {
    const readStream = createReadStream(inputPath);
    const writeStream = createWriteStream(outputPath);
    const brotli = createBrotliDecompress();

    await pipeline(readStream, brotli, writeStream);
  }

  private async compressZstd(inputPath: string, outputPath: string, level: number): Promise<void> {
    const command = `zstd -${level} -f -o ${outputPath} ${inputPath}`;
    await execAsync(command);
  }

  private async decompressZstd(inputPath: string, outputPath: string): Promise<void> {
    const command = `zstd -d -f -o ${outputPath} ${inputPath}`;
    await execAsync(command);
  }

  private async compressLz4(inputPath: string, outputPath: string): Promise<void> {
    const command = `lz4 -f ${inputPath} ${outputPath}`;
    await execAsync(command);
  }

  private async decompressLz4(inputPath: string, outputPath: string): Promise<void> {
    const command = `lz4 -d -f ${inputPath} ${outputPath}`;
    await execAsync(command);
  }

  async compressBuffer(buffer: Buffer, algorithm: CompressionAlgorithm, level: number): Promise<Buffer> {
    switch (algorithm) {
      case 'gzip':
        return this.compressBufferGzip(buffer, level);
      case 'brotli':
        return this.compressBufferBrotli(buffer, level);
      default:
        throw new Error(`Buffer compression not supported for: ${algorithm}`);
    }
  }

  private async compressBufferGzip(buffer: Buffer, level: number): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const gzip = createGzip({ level });
      const chunks: Buffer[] = [];

      gzip.on('data', (chunk) => chunks.push(chunk));
      gzip.on('end', () => resolve(Buffer.concat(chunks)));
      gzip.on('error', reject);

      gzip.end(buffer);
    });
  }

  private async compressBufferBrotli(buffer: Buffer, level: number): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const brotli = createBrotliCompress({ 
        params: {
          [require('zlib').constants.BROTLI_PARAM_QUALITY]: level,
        },
      });
      const chunks: Buffer[] = [];

      brotli.on('data', (chunk) => chunks.push(chunk));
      brotli.on('end', () => resolve(Buffer.concat(chunks)));
      brotli.on('error', reject);

      brotli.end(buffer);
    });
  }
}
```

## 2. Encryption Service

### File: `services/encryption.service.ts`

```typescript
import crypto from 'crypto';
import { promises as fs } from 'fs';

export type EncryptionAlgorithm = 'AES-256-GCM' | 'AES-256-CBC' | 'ChaCha20-Poly1305';

export interface EncryptionResult {
  encrypted: Buffer;
  iv: Buffer;
  authTag?: Buffer;
  algorithm: EncryptionAlgorithm;
}

export interface EncryptedData {
  data: string; // hex encoded
  iv: string;  // hex encoded
  authTag?: string; // hex encoded
  algorithm: EncryptionAlgorithm;
}

export class EncryptionService {
  private key: Buffer;
  private algorithm: EncryptionAlgorithm;

  constructor(key: string, algorithm: EncryptionAlgorithm = 'AES-256-GCM') {
    this.key = Buffer.from(key, 'hex');
    this.algorithm = algorithm;
  }

  async encrypt(data: Buffer): Promise<EncryptionResult> {
    switch (this.algorithm) {
      case 'AES-256-GCM':
        return this.encryptAES256GCM(data);
      case 'AES-256-CBC':
        return this.encryptAES256CBC(data);
      case 'ChaCha20-Poly1305':
        return this.encryptChaCha20Poly1305(data);
      default:
        throw new Error(`Unsupported encryption algorithm: ${this.algorithm}`);
    }
  }

  async decrypt(encrypted: Buffer, iv: Buffer, authTag?: Buffer): Promise<Buffer> {
    switch (this.algorithm) {
      case 'AES-256-GCM':
        return this.decryptAES256GCM(encrypted, iv, authTag!);
      case 'AES-256-CBC':
        return this.decryptAES256CBC(encrypted, iv);
      case 'ChaCha20-Poly1305':
        return this.decryptChaCha20Poly1305(encrypted, iv, authTag!);
      default:
        throw new Error(`Unsupported encryption algorithm: ${this.algorithm}`);
    }
  }

  async encryptFile(inputPath: string, outputPath: string): Promise<EncryptionResult> {
    const data = await fs.readFile(inputPath);
    const result = await this.encrypt(data);
    
    // Combine IV + authTag + encrypted data
    const combined = Buffer.concat([
      result.iv,
      result.authTag || Buffer.alloc(0),
      result.encrypted,
    ]);
    
    await fs.writeFile(outputPath, combined);
    return result;
  }

  async decryptFile(inputPath: string, outputPath: string): Promise<void> {
    const data = await fs.readFile(inputPath);
    
    let iv: Buffer;
    let authTag: Buffer;
    let encrypted: Buffer;

    if (this.algorithm === 'AES-256-GCM' || this.algorithm === 'ChaCha20-Poly1305') {
      iv = data.slice(0, 12); // 12 bytes for GCM/ChaCha20
      authTag = data.slice(12, 28); // 16 bytes for auth tag
      encrypted = data.slice(28);
    } else {
      iv = data.slice(0, 16); // 16 bytes for CBC
      encrypted = data.slice(16);
    }

    const decrypted = await this.decrypt(encrypted, iv, authTag);
    await fs.writeFile(outputPath, decrypted);
  }

  private encryptAES256GCM(data: Buffer): EncryptionResult {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.key, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data),
      cipher.final(),
    ]);
    
    const authTag = cipher.getAuthTag();

    return {
      encrypted,
      iv,
      authTag,
      algorithm: 'AES-256-GCM',
    };
  }

  private decryptAES256GCM(encrypted: Buffer, iv: Buffer, authTag: Buffer): Buffer {
    const decipher = crypto.createDecipheriv('aes-256-gcm', this.key, iv);
    decipher.setAuthTag(authTag);
    
    return Buffer.concat([
      decipher.update(encrypted),
      decipher.final(),
    ]);
  }

  private encryptAES256CBC(data: Buffer): EncryptionResult {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', this.key, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data),
      cipher.final(),
    ]);

    return {
      encrypted,
      iv,
      algorithm: 'AES-256-CBC',
    };
  }

  private decryptAES256CBC(encrypted: Buffer, iv: Buffer): Buffer {
    const decipher = crypto.createDecipheriv('aes-256-cbc', this.key, iv);
    
    return Buffer.concat([
      decipher.update(encrypted),
      decipher.final(),
    ]);
  }

  private encryptChaCha20Poly1305(data: Buffer): EncryptionResult {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('chacha20-poly1305', this.key, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data),
      cipher.final(),
    ]);
    
    const authTag = cipher.getAuthTag();

    return {
      encrypted,
      iv,
      authTag,
      algorithm: 'ChaCha20-Poly1305',
    };
  }

  private decryptChaCha20Poly1305(encrypted: Buffer, iv: Buffer, authTag: Buffer): Buffer {
    const decipher = crypto.createDecipheriv('chacha20-poly1305', this.key, iv);
    decipher.setAuthTag(authTag);
    
    return Buffer.concat([
      decipher.update(encrypted),
      decipher.final(),
    ]);
  }

  static generateKey(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  static hashPassword(password: string, salt?: string): { hash: string; salt: string } {
    const actualSalt = salt || crypto.randomBytes(16).toString('hex');
    const hash = crypto
      .pbkdf2Sync(password, actualSalt, 100000, 64, 'sha512')
      .toString('hex');
    
    return { hash, salt: actualSalt };
  }

  static verifyPassword(password: string, hash: string, salt: string): boolean {
    const { hash: computedHash } = this.hashPassword(password, salt);
    return computedHash === hash;
  }
}
```

## 3. ID Encryption Service

### File: `services/id-encryption.service.ts`

```typescript
import crypto from 'crypto';

export class IdEncryptionService {
  private algorithm = 'aes-256-cbc';
  private key: Buffer;
  private ivLength = 16;

  constructor(encryptionKey: string) {
    // Ensure key is 32 bytes for AES-256
    this.key = crypto.scryptSync(encryptionKey, 'salt', 32);
  }

  encryptId(id: string): string {
    const iv = crypto.randomBytes(this.ivLength);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    
    let encrypted = cipher.update(id, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    // Combine IV and encrypted data with separator
    return `${iv.toString('hex')}:${encrypted}`;
  }

  decryptId(encryptedId: string): string {
    const parts = encryptedId.split(':');
    if (parts.length !== 2) {
      throw new Error('Invalid encrypted ID format');
    }
    
    const iv = Buffer.from(parts[0], 'hex');
    const encrypted = parts[1];
    
    const decipher = crypto.createDecipheriv(this.algorithm, this.key, iv);
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }

  generateEncryptedId(originalId: string): string {
    return this.encryptId(originalId);
  }

  batchEncryptIds(ids: string[]): Map<string, string> {
    const result = new Map<string, string>();
    for (const id of ids) {
      result.set(id, this.encryptId(id));
    }
    return result;
  }

  batchDecryptIds(encryptedIds: string[]): Map<string, string> {
    const result = new Map<string, string>();
    for (const encryptedId of encryptedIds) {
      try {
        const decryptedId = this.decryptId(encryptedId);
        result.set(encryptedId, decryptedId);
      } catch (error) {
        console.error(`Failed to decrypt ID: ${encryptedId}`, error);
      }
    }
    return result;
  }

  isValidEncryptedId(encryptedId: string): boolean {
    try {
      this.decryptId(encryptedId);
      return true;
    } catch {
      return false;
    }
  }
}
```

## 4. Classification Service

### File: `services/classification.service.ts`

```typescript
import { promises as fs } from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export interface ClassificationResult {
  category: string;
  subcategories: string[];
  tags: string[];
  confidence: number;
  contentType: string;
}

export interface FileMetadata {
  size: number;
  mimeType: string;
  extension: string;
  createdAt: Date;
  modifiedAt: Date;
  dimensions?: { width: number; height: number }; // For images/videos
  duration?: number; // For audio/video
  pageCount?: number; // For PDFs
}

export class ClassificationService {
  private categoryRules: Map<string, RegExp[]>;
  private tagRules: Map<string, RegExp[]>;

  constructor() {
    this.categoryRules = new Map();
    this.tagRules = new Map();
    this.initializeRules();
  }

  private initializeRules(): void {
    // Initialize category rules
    this.categoryRules.set('document', [
      /\.pdf$/i,
      /\.docx?$/i,
      /\.xlsx?$/i,
      /\.pptx?$/i,
      /\.txt$/i,
      /\.rtf$/i,
      /\.odt$/i,
    ]);

    this.categoryRules.set('image', [
      /\.jpe?g$/i,
      /\.png$/i,
      /\.gif$/i,
      /\.bmp$/i,
      /\.webp$/i,
      /\.svg$/i,
      /\.tiff?$/i,
    ]);

    this.categoryRules.set('video', [
      /\.mp4$/i,
      /\.avi$/i,
      /\.mkv$/i,
      /\.mov$/i,
      /\.wmv$/i,
      /\.flv$/i,
      /\.webm$/i,
    ]);

    this.categoryRules.set('audio', [
      /\.mp3$/i,
      /\.wav$/i,
      /\.flac$/i,
      /\.aac$/i,
      /\.ogg$/i,
      /\.m4a$/i,
    ]);

    this.categoryRules.set('archive', [
      /\.zip$/i,
      /\.rar$/i,
      /\.7z$/i,
      /\.tar$/i,
      /\.gz$/i,
      /\.bz2$/i,
    ]);

    this.categoryRules.set('code', [
      /\.js$/i,
      /\.ts$/i,
      /\.py$/i,
      /\.java$/i,
      /\.cpp$/i,
      /\.c$/i,
      /\.go$/i,
      /\.rs$/i,
      /\.php$/i,
      /\.rb$/i,
    ]);

    // Initialize tag rules
    this.tagRules.set('important', [
      /important/i,
      /urgent/i,
      /critical/i,
    ]);

    this.tagRules.set('financial', [
      /invoice/i,
      /receipt/i,
      /payment/i,
      /budget/i,
    ]);

    this.tagRules.set('personal', [
      /personal/i,
      /private/i,
      /confidential/i,
    ]);
  }

  async classifyFile(filePath: string): Promise<ClassificationResult> {
    const fileName = filePath.split('/').pop() || '';
    const metadata = await this.extractMetadata(filePath);

    const category = this.classifyByExtension(fileName);
    const tags = this.extractTags(fileName);
    const contentType = metadata.mimeType;

    return {
      category,
      subcategories: [],
      tags,
      confidence: 0.8,
      contentType,
    };
  }

  async classifyContent(content: string): Promise<ClassificationResult> {
    const tags = this.extractTags(content);
    const category = this.classifyByContent(content);

    return {
      category,
      subcategories: [],
      tags,
      confidence: 0.7,
      contentType: 'text/plain',
    };
  }

  async extractMetadata(filePath: string): Promise<FileMetadata> {
    const stats = await fs.stat(filePath);
    const extension = filePath.split('.').pop() || '';
    
    // Get MIME type
    let mimeType = 'application/octet-stream';
    try {
      const { stdout } = await execAsync(`file --mime-type -b "${filePath}"`);
      mimeType = stdout.trim();
    } catch (error) {
      // Fallback to extension-based detection
      mimeType = this.getMimeTypeByExtension(extension);
    }

    const metadata: FileMetadata = {
      size: stats.size,
      mimeType,
      extension,
      createdAt: stats.birthtime,
      modifiedAt: stats.mtime,
    };

    // Extract additional metadata based on type
    if (this.isImage(extension)) {
      const dimensions = await this.getImageDimensions(filePath);
      if (dimensions) {
        metadata.dimensions = dimensions;
      }
    }

    if (this.isVideo(extension)) {
      const duration = await this.getVideoDuration(filePath);
      if (duration) {
        metadata.duration = duration;
      }
    }

    return metadata;
  }

  private classifyByExtension(fileName: string): string {
    for (const [category, patterns] of this.categoryRules) {
      for (const pattern of patterns) {
        if (pattern.test(fileName)) {
          return category;
        }
      }
    }
    return 'other';
  }

  private classifyByContent(content: string): string {
    // Simple content-based classification
    if (content.includes('<html') || content.includes('<!DOCTYPE')) {
      return 'html';
    }
    if (content.includes('{') && content.includes('}')) {
      return 'json';
    }
    if (content.includes('import ') || content.includes('require(')) {
      return 'code';
    }
    return 'text';
  }

  private extractTags(text: string): string[] {
    const tags: string[] = [];
    
    for (const [tag, patterns] of this.tagRules) {
      for (const pattern of patterns) {
        if (pattern.test(text)) {
          tags.push(tag);
          break;
        }
      }
    }

    return tags;
  }

  private getMimeTypeByExtension(extension: string): string {
    const mimeTypes: Record<string, string> = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'zip': 'application/zip',
      'json': 'application/json',
      'txt': 'text/plain',
    };

    return mimeTypes[extension.toLowerCase()] || 'application/octet-stream';
  }

  private isImage(extension: string): boolean {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'tiff', 'tif'].includes(extension.toLowerCase());
  }

  private isVideo(extension: string): boolean {
    return ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm'].includes(extension.toLowerCase());
  }

  private async getImageDimensions(filePath: string): Promise<{ width: number; height: number } | null> {
    try {
      const { stdout } = await execAsync(`identify -format "%w %h" "${filePath}[0]"`);
      const [width, height] = stdout.trim().split(' ').map(Number);
      return { width, height };
    } catch {
      return null;
    }
  }

  private async getVideoDuration(filePath: string): Promise<number | null> {
    try {
      const { stdout } = await execAsync(`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${filePath}"`);
      return parseFloat(stdout.trim());
    } catch {
      return null;
    }
  }
}
```

## 5. Storage Service

### File: `services/storage.service.ts`

```typescript
import { promises as fs } from 'fs';
import { join } from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export interface StorageDisk {
  name: string;
  mountPoint: string;
  devicePath: string;
  totalCapacity: number;
  usedCapacity: number;
  availableCapacity: number;
  isPrimary: boolean;
}

export class StorageService {
  private disks: Map<string, StorageDisk>;
  private allocationStrategy: 'round_robin' | 'least_used' | 'priority';
  private currentDiskIndex: number;

  constructor(allocationStrategy: 'round_robin' | 'least_used' | 'priority' = 'round_robin') {
    this.disks = new Map();
    this.allocationStrategy = allocationStrategy;
    this.currentDiskIndex = 0;
  }

  async initialize(disks: StorageDisk[]): Promise<void> {
    for (const disk of disks) {
      await this.mountDisk(disk);
      this.disks.set(disk.name, disk);
    }
  }

  async mountDisk(disk: StorageDisk): Promise<void> {
    try {
      // Check if already mounted
      const { stdout } = await execAsync(`findmnt -n -o TARGET ${disk.devicePath}`);
      if (stdout.trim() === disk.mountPoint) {
        return;
      }

      // Create mount point if not exists
      await fs.mkdir(disk.mountPoint, { recursive: true });

      // Mount disk
      await execAsync(`mount ${disk.devicePath} ${disk.mountPoint}`);
    } catch (error) {
      console.error(`Failed to mount disk ${disk.name}:`, error);
      throw error;
    }
  }

  async getDiskInfo(diskName: string): Promise<StorageDisk | null> {
    const disk = this.disks.get(diskName);
    if (!disk) return null;

    const { stdout } = await execAsync(`df -B1 ${disk.mountPoint}`);
    const lines = stdout.split('\n');
    const data = lines[1].split(/\s+/);

    return {
      ...disk,
      totalCapacity: parseInt(data[1]),
      usedCapacity: parseInt(data[2]),
      availableCapacity: parseInt(data[3]),
    };
  }

  async getAllDiskInfo(): Promise<StorageDisk[]> {
    const diskInfos: StorageDisk[] = [];
    
    for (const [name, disk] of this.disks) {
      const info = await this.getDiskInfo(name);
      if (info) {
        diskInfos.push(info);
      }
    }

    return diskInfos;
  }

  selectDiskForStorage(): StorageDisk | null {
    const activeDisks = Array.from(this.disks.values()).filter(d => d.availableCapacity > 0);
    
    if (activeDisks.length === 0) {
      return null;
    }

    switch (this.allocationStrategy) {
      case 'round_robin':
        return this.selectRoundRobin(activeDisks);
      case 'least_used':
        return this.selectLeastUsed(activeDisks);
      case 'priority':
        return this.selectByPriority(activeDisks);
      default:
        return activeDisks[0];
    }
  }

  private selectRoundRobin(disks: StorageDisk[]): StorageDisk {
    const disk = disks[this.currentDiskIndex % disks.length];
    this.currentDiskIndex++;
    return disk;
  }

  private selectLeastUsed(disks: StorageDisk[]): StorageDisk {
    return disks.reduce((least, current) => 
      current.usedCapacity < least.usedCapacity ? current : least
    );
  }

  private selectByPriority(disks: StorageDisk[]): StorageDisk {
    const primary = disks.find(d => d.isPrimary);
    return primary || disks[0];
  }

  async storeFile(
    fileName: string,
    data: Buffer,
    diskName?: string
  ): Promise<{ path: string; disk: StorageDisk }> {
    const disk = diskName 
      ? this.disks.get(diskName)!
      : this.selectDiskForStorage();

    if (!disk) {
      throw new Error('No available disk for storage');
    }

    const storagePath = join(disk.mountPoint, 'data', fileName);
    const dirPath = join(disk.mountPoint, 'data');

    await fs.mkdir(dirPath, { recursive: true });
    await fs.writeFile(storagePath, data);

    return { path: storagePath, disk };
  }

  async retrieveFile(filePath: string): Promise<Buffer> {
    return await fs.readFile(filePath);
  }

  async deleteFile(filePath: string): Promise<void> {
    await fs.unlink(filePath);
  }

  async moveFile(
    sourcePath: string,
    targetDiskName: string,
    targetFileName?: string
  ): Promise<string> {
    const targetDisk = this.disks.get(targetDiskName);
    if (!targetDisk) {
      throw new Error(`Target disk ${targetDiskName} not found`);
    }

    const fileName = targetFileName || sourcePath.split('/').pop() || '';
    const targetPath = join(targetDisk.mountPoint, 'data', fileName);
    const targetDir = join(targetDisk.mountPoint, 'data');

    await fs.mkdir(targetDir, { recursive: true });
    await fs.rename(sourcePath, targetPath);

    return targetPath;
  }

  async getStorageUsage(): Promise<{ total: number; used: number; available: number }> {
    const diskInfos = await this.getAllDiskInfo();
    
    return diskInfos.reduce(
      (acc, disk) => ({
        total: acc.total + disk.totalCapacity,
        used: acc.used + disk.usedCapacity,
        available: acc.available + disk.availableCapacity,
      }),
      { total: 0, used: 0, available: 0 }
    );
  }
}
```

## 6. Version Control Service

### File: `services/version-control.service.ts`

```typescript
import { promises as fs } from 'fs';
import { join } from 'path';
import { createHash } from 'crypto';

export interface DataVersion {
  versionNumber: number;
  storagePath: string;
  fileSize: number;
  checksum: string;
  changeNote?: string;
  createdAt: Date;
}

export class VersionControlService {
  private basePath: string;
  private maxVersions: number;

  constructor(basePath: string, maxVersions: number = 10) {
    this.basePath = basePath;
    this.maxVersions = maxVersions;
  }

  async createVersion(
    dataItemId: string,
    filePath: string,
    changeNote?: string
  ): Promise<DataVersion> {
    const versionsDir = join(this.basePath, 'versions', dataItemId);
    await fs.mkdir(versionsDir, { recursive: true });

    // Get current version number
    const versions = await this.listVersions(dataItemId);
    const versionNumber = versions.length + 1;

    // Copy file to version directory
    const versionPath = join(versionsDir, `v${versionNumber}`);
    await fs.copyFile(filePath, versionPath);

    // Calculate checksum
    const data = await fs.readFile(versionPath);
    const checksum = createHash('sha256').update(data).digest('hex');
    const stats = await fs.stat(versionPath);

    const version: DataVersion = {
      versionNumber,
      storagePath: versionPath,
      fileSize: stats.size,
      checksum,
      changeNote,
      createdAt: new Date(),
    };

    // Clean up old versions if exceeding max
    if (versions.length >= this.maxVersions) {
      await this.cleanupOldVersions(dataItemId);
    }

    return version;
  }

  async listVersions(dataItemId: string): Promise<DataVersion[]> {
    const versionsDir = join(this.basePath, 'versions', dataItemId);
    
    try {
      const files = await fs.readdir(versionsDir);
      const versions: DataVersion[] = [];

      for (const file of files) {
        if (file.startsWith('v')) {
          const versionPath = join(versionsDir, file);
          const stats = await fs.stat(versionPath);
          const data = await fs.readFile(versionPath);
          const checksum = createHash('sha256').update(data).digest('hex');
          const versionNumber = parseInt(file.replace('v', ''));

          versions.push({
            versionNumber,
            storagePath: versionPath,
            fileSize: stats.size,
            checksum,
            createdAt: stats.mtime,
          });
        }
      }

      return versions.sort((a, b) => a.versionNumber - b.versionNumber);
    } catch {
      return [];
    }
  }

  async restoreVersion(
    dataItemId: string,
    versionNumber: number,
    targetPath: string
  ): Promise<void> {
    const versions = await this.listVersions(dataItemId);
    const version = versions.find(v => v.versionNumber === versionNumber);

    if (!version) {
      throw new Error(`Version ${versionNumber} not found`);
    }

    await fs.copyFile(version.storagePath, targetPath);
  }

  async deleteVersion(dataItemId: string, versionNumber: number): Promise<void> {
    const versions = await this.listVersions(dataItemId);
    const version = versions.find(v => v.versionNumber === versionNumber);

    if (!version) {
      throw new Error(`Version ${versionNumber} not found`);
    }

    await fs.unlink(version.storagePath);
  }

  async cleanupOldVersions(dataItemId: string): Promise<void> {
    const versions = await this.listVersions(dataItemId);
    
    if (versions.length <= this.maxVersions) {
      return;
    }

    const versionsToDelete = versions.slice(0, versions.length - this.maxVersions);
    
    for (const version of versionsToDelete) {
      await fs.unlink(version.storagePath);
    }
  }

  async compareVersions(
    dataItemId: string,
    version1: number,
    version2: number
  ): Promise<{ identical: boolean; sizeDifference: number }> {
    const versions = await this.listVersions(dataItemId);
    const v1 = versions.find(v => v.versionNumber === version1);
    const v2 = versions.find(v => v.versionNumber === version2);

    if (!v1 || !v2) {
      throw new Error('One or both versions not found');
    }

    const identical = v1.checksum === v2.checksum;
    const sizeDifference = Math.abs(v1.fileSize - v2.fileSize);

    return { identical, sizeDifference };
  }
}
```

## Usage Example

```typescript
// Initialize services
const compressionService = new CompressionService();
const encryptionService = new EncryptionService(process.env.ENCRYPTION_KEY!);
const idEncryptionService = new IdEncryptionService(process.env.ID_ENCRYPTION_KEY!);
const classificationService = new ClassificationService();
const storageService = new StorageService('least_used');
const versionControlService = new VersionControlService('/mnt/data-primary');

// Example workflow
async function processFile(filePath: string) {
  // 1. Classify file
  const classification = await classificationService.classifyFile(filePath);
  
  // 2. Compress file
  const compressedPath = filePath + '.compressed';
  const compressionResult = await compressionService.compressFile(
    filePath,
    compressedPath,
    { algorithm: 'zstd', level: 6 }
  );
  
  // 3. Encrypt file
  const encryptedPath = compressedPath + '.encrypted';
  await encryptionService.encryptFile(compressedPath, encryptedPath);
  
  // 4. Store on disk
  const { path, disk } = await storageService.storeFile(
    'processed.dat',
    await fs.readFile(encryptedPath)
  );
  
  // 5. Create version
  await versionControlService.createVersion('data-item-1', path, 'Initial version');
  
  // 6. Generate encrypted ID for app
  const encryptedId = idEncryptionService.generateEncryptedId('data-item-1');
  
  return {
    classification,
    compressionResult,
    storagePath: path,
    disk: disk.name,
    encryptedId,
  };
}
```
