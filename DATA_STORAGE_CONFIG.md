# Cấu Hình Data Storage Server

## Tổng Quan

Server được thiết kế để xử lý và lưu trữ data lớn với các tính năng:
- **Lưu trữ phân tán**: Trên nhiều ổ cứng server
- **Phân loại nội dung**: Theo category, tags, metadata
- **Xác thực**: User authentication với mã hóa ID
- **Mã hóa dữ liệu**: Encryption tại rest và in transit
- **Nén dữ liệu**: Tối ưu hóa storage với compression
- **Version control**: Theo dõi các phiên bản data
- **Audit logging**: Theo dõi mọi hoạt động

## Kiến Trúc Storage

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│              (Node.js/Express + Prisma)                  │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Data Processing Services                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │ Compress │  │ Encrypt  │  │ Classify │  │ Version │ │
│  │ Service  │  │ Service  │  │ Service  │  │ Control │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Storage Management Layer                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Disk 1  │  │  Disk 2  │  │  Disk 3  │  │ Backup  │ │
│  │ (Primary)│  │ (Hot)    │  │ (Archive)│  │ (Cold)  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Database Layer (PostgreSQL)                 │
│         - User & Authentication                          │
│         - Data Classification                            │
│         - Storage Allocation                            │
│         - Audit Logs                                    │
└─────────────────────────────────────────────────────────┘
```

## Cấu Hình Ổ Cứng Server

### Phân chia Storage theo loại dữ liệu

| Ổ cứng | Mount Point | Loại dữ liệu | Dung lượng khuyến nghị |
|--------|-------------|--------------|----------------------|
| /dev/sdb1 | /mnt/data-primary | Data thường xuyên truy cập | SSD 500GB+ |
| /dev/sdc1 | /mnt/data-hot | Data hot, cần tốc độ cao | NVMe 1TB+ |
| /dev/sdd1 | /mnt/data-archive | Data archive, ít truy cập | HDD 2TB+ |
| /dev/sde1 | /mnt/data-backup | Backup data | HDD 4TB+ |

### Cấu hình trong Ansible

Thêm vào `inventory.ini`:

```ini
[storage_servers]
storage-01 ansible_host=192.168.1.200 ansible_user=admin
```

### Script Setup Storage Disks

Tạo file `roles/data-storage/tasks/setup-disks.yml`:

```yaml
---
- name: Install required packages
  apt:
    name:
      - xfsprogs
      - ntfs-3g
      - hfsutils
      - parted
      - lvm2
    state: present

- name: Create mount points
  file:
    path: "{{ item.mount_point }}"
    state: directory
    mode: '0755'
  loop: "{{ storage_disks }}"

- name: Format disks
  filesystem:
    fstype: "{{ item.fstype }}"
    dev: "{{ item.device }}"
  loop: "{{ storage_disks }}"
  when: item.format | default(false)

- name: Mount disks
  mount:
    path: "{{ item.mount_point }}"
    src: "{{ item.device }}"
    fstype: "{{ item.fstype }}"
    opts: "{{ item.mount_options | default('defaults,noatime') }}"
    state: mounted
  loop: "{{ storage_disks }}"

- name: Set permissions
  file:
    path: "{{ item.mount_point }}"
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    mode: '0755'
  loop: "{{ storage_disks }}"

- name: Create storage directories
  file:
    path: "{{ item.mount_point }}/{{ storage_subdir }}"
    state: directory
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    mode: '0755'
  loop: "{{ storage_disks }}"
```

### Cấu hình trong `project-config.yml`

```yaml
# Data Storage Configuration
data_storage_enabled: true
storage_subdir: "data"

# Storage Disks Configuration
storage_disks:
  - name: "primary"
    device: "/dev/sdb1"
    mount_point: "/mnt/data-primary"
    fstype: "xfs"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "SSD"
    is_primary: true
    is_hot_swap: false
    
  - name: "hot"
    device: "/dev/sdc1"
    mount_point: "/mnt/data-hot"
    fstype: "xfs"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "NVME"
    is_primary: false
    is_hot_swap: true
    
  - name: "archive"
    device: "/dev/sdd1"
    mount_point: "/mnt/data-archive"
    fstype: "ext4"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "HDD"
    is_primary: false
    is_hot_swap: false
    
  - name: "backup"
    device: "/dev/sde1"
    mount_point: "/mnt/data-backup"
    fstype: "ext4"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "HDD"
    is_primary: false
    is_hot_swap: false

# Storage Allocation Strategy
storage_allocation_strategy: "round_robin"  # round_robin, least_used, priority
default_disk_for_upload: "primary"
archive_after_days: 90
backup_retention_days: 365

# Compression Configuration
compression_enabled: true
compression_algorithm: "zstd"  # gzip, lz4, zstd, brotli
compression_level: 6
compress_files_larger_than: "10MB"
compress_content_types:
  - "text/*"
  - "application/json"
  - "application/xml"
  - "application/javascript"

# Encryption Configuration
encryption_enabled: true
encryption_algorithm: "AES-256-GCM"
encryption_key_rotation_days: 90
encrypt_at_rest: true
encrypt_in_transit: true

# Data Classification
auto_classify_enabled: true
classification_model: "local"  # local, ai
default_access_level: "INTERNAL"
max_tags_per_item: 10

# Version Control
version_control_enabled: true
max_versions_per_item: 10
keep_versions_for_days: 365

# Audit Logging
audit_log_enabled: true
audit_log_retention_days: 365
log_access_attempts: true
log_data_changes: true
```

## Data Processing Services

### 1. Compression Service

```typescript
// services/compression.service.ts
import { compress, decompress } from 'compressor';
import { DataProcessingTask } from '@prisma/client';

export class CompressionService {
  async compressFile(inputPath: string, outputPath: string, options: CompressOptions): Promise<void> {
    // Compress file với zstd/gzip/lz4
  }

  async decompressFile(inputPath: string, outputPath: string): Promise<void> {
    // Decompress file
  }

  async getCompressionRatio(originalSize: number, compressedSize: number): number {
    return compressedSize / originalSize;
  }
}
```

### 2. Encryption Service

```typescript
// services/encryption.service.ts
import crypto from 'crypto';

export class EncryptionService {
  private algorithm = 'aes-256-gcm';
  private keyLength = 32;
  private ivLength = 16;
  private authTagLength = 16;

  async encrypt(data: Buffer, key: string): Promise<{ encrypted: Buffer; iv: Buffer; authTag: Buffer }> {
    const iv = crypto.randomBytes(this.ivLength);
    const cipher = crypto.createCipheriv(this.algorithm, Buffer.from(key, 'hex'), iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data),
      cipher.final()
    ]);
    
    const authTag = cipher.getAuthTag();
    
    return { encrypted, iv, authTag };
  }

  async decrypt(encrypted: Buffer, key: string, iv: Buffer, authTag: Buffer): Promise<Buffer> {
    const decipher = crypto.createDecipheriv(this.algorithm, Buffer.from(key, 'hex'), iv);
    decipher.setAuthTag(authTag);
    
    return Buffer.concat([
      decipher.update(encrypted),
      decipher.final()
    ]);
  }

  generateEncryptionKey(): string {
    return crypto.randomBytes(this.keyLength).toString('hex');
  }
}
```

### 3. ID Encryption Service

```typescript
// services/id-encryption.service.ts
import crypto from 'crypto';

export class IdEncryptionService {
  private algorithm = 'aes-256-cbc';
  private key: Buffer;
  private ivLength = 16;

  constructor(encryptionKey: string) {
    this.key = Buffer.from(encryptionKey, 'hex');
  }

  encryptId(id: string): string {
    const iv = crypto.randomBytes(this.ivLength);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    
    let encrypted = cipher.update(id, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    // Combine IV and encrypted data
    return iv.toString('hex') + ':' + encrypted;
  }

  decryptId(encryptedId: string): string {
    const parts = encryptedId.split(':');
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
}
```

### 4. Data Classification Service

```typescript
// services/classification.service.ts
export class ClassificationService {
  async classifyData(content: string, contentType: string): Promise<ClassificationResult> {
    // Phân loại data dựa trên content và type
    // Có thể dùng AI model hoặc rule-based
  }

  async extractMetadata(filePath: string): Promise<Record<string, any>> {
    // Extract metadata từ file
  }

  async generateTags(content: string): Promise<string[]> {
    // Generate tags từ content
  }
}
```

## API Endpoints

### Data Management

```typescript
// routes/data.routes.ts
router.post('/data/upload', upload.single('file'), dataController.upload);
router.get('/data/:encryptedId', dataController.getById);
router.get('/data', dataController.list);
router.put('/data/:encryptedId', dataController.update);
router.delete('/data/:encryptedId', dataController.delete);
router.post('/data/:encryptedId/compress', dataController.compress);
router.post('/data/:encryptedId/encrypt', dataController.encrypt);
router.get('/data/:encryptedId/versions', dataController.getVersions);
router.post('/data/:encryptedId/restore/:version', dataController.restoreVersion);
```

### Storage Management

```typescript
// routes/storage.routes.ts
router.get('/storage/disks', storageController.listDisks);
router.get('/storage/disks/:encryptedId', storageController.getDiskInfo);
router.post('/storage/disks', storageController.createDisk);
router.put('/storage/disks/:encryptedId', storageController.updateDisk);
router.get('/storage/allocations', storageController.getAllocations);
router.post('/storage/allocations', storageController.createAllocation);
```

### Classification

```typescript
// routes/classification.routes.ts
router.get('/categories', categoryController.list);
router.post('/categories', categoryController.create);
router.get('/categories/:encryptedId', categoryController.getById);
router.put('/categories/:encryptedId', categoryController.update);
router.delete('/categories/:encryptedId', categoryController.delete);
router.post('/data/:encryptedId/classify', classificationController.classify);
```

## Environment Variables

```bash
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/datastore"

# Encryption
ENCRYPTION_KEY="your-256-bit-encryption-key-here"
ID_ENCRYPTION_KEY="your-id-encryption-key-here"

# Storage
STORAGE_PRIMARY_PATH="/mnt/data-primary/data"
STORAGE_HOT_PATH="/mnt/data-hot/data"
STORAGE_ARCHIVE_PATH="/mnt/data-archive/data"
STORAGE_BACKUP_PATH="/mnt/data-backup/data"

# Compression
COMPRESSION_ENABLED="true"
COMPRESSION_ALGORITHM="zstd"
COMPRESSION_LEVEL="6"

# Classification
AUTO_CLASSIFY_ENABLED="true"
CLASSIFICATION_MODEL="local"

# Version Control
VERSION_CONTROL_ENABLED="true"
MAX_VERSIONS="10"

# Audit
AUDIT_LOG_ENABLED="true"
AUDIT_LOG_RETENTION_DAYS="365"
```

## Monitoring & Maintenance

### Health Check

```bash
# Check disk health
df -h
lsblk
smartctl -a /dev/sdb

# Check storage usage
du -sh /mnt/data-*

# Check database connections
psql -c "SELECT COUNT(*) FROM data_items;"
```

### Backup Strategy

```bash
# Daily backup
0 2 * * * /usr/bin/rsync -av /mnt/data-primary/ /mnt/data-backup/daily/

# Weekly archive
0 3 * * 0 /usr/bin/rsync -av /mnt/data-archive/ /mnt/data-backup/weekly/

# Database backup
0 1 * * * pg_dump -U user datastore > /mnt/data-backup/db/daily.sql
```

### Cleanup Old Data

```bash
# Archive data older than 90 days
find /mnt/data-primary -type f -mtime +90 -exec mv {} /mnt/data-archive/ \;

# Delete data older than 365 days from archive
find /mnt/data-archive -type f -mtime +365 -delete

# Delete old versions
find /mnt/data-primary -type f -name "*.v*" -mtime +365 -delete
```

## Security Best Practices

1. **Encryption at Rest**: Mã hóa tất cả data khi lưu trữ
2. **Encryption in Transit**: Sử dụng HTTPS/TLS cho tất cả API calls
3. **Access Control**: RBAC cho user access
4. **Audit Logging**: Log tất cả hoạt động
5. **Key Rotation**: Rotate encryption keys định kỳ
6. **Secure Storage**: Isolate storage servers
7. **Network Segmentation**: Storage trong private network
8. **Regular Backups**: Backup định kỳ và test restore
