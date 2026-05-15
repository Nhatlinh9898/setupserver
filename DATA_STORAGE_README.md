# Data Storage Server - Hướng Dẫn Sử Dụng

## Tổng Quan

Server được thiết kế để xử lý và lưu trữ data lớn với các tính năng:
- **Lưu trữ phân tán**: Trên nhiều ổ cứng server (SSD, NVMe, HDD)
- **Phân loại nội dung**: Tự động phân loại theo category, tags, metadata
- **Xác thực**: User authentication với mã hóa ID
- **Mã hóa dữ liệu**: Encryption tại rest và in transit (AES-256-GCM)
- **Nén dữ liệu**: Tối ưu hóa storage với compression (zstd, gzip, brotli)
- **Version control**: Theo dõi các phiên bản data
- **Audit logging**: Theo dõi mọi hoạt động

## Cấu Trúc Hệ Thống

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

## Cài Đặt

### Bước 1: Cấu hình trong `project-config.yml`

```yaml
# Bật Data Storage
data_storage_enabled: true
storage_subdir: "data"

# Cấu hình các ổ cứng server
storage_disks:
  - name: "primary"
    device: "/dev/sdb1"
    mount_point: "/mnt/data-primary"
    fstype: "xfs"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "SSD"
    is_primary: true
    
  - name: "hot"
    device: "/dev/sdc1"
    mount_point: "/mnt/data-hot"
    fstype: "xfs"
    disk_type: "NVME"
    is_hot_swap: true
    
  - name: "archive"
    device: "/dev/sdd1"
    mount_point: "/mnt/data-archive"
    fstype: "ext4"
    disk_type: "HDD"
    
  - name: "backup"
    device: "/dev/sde1"
    mount_point: "/mnt/data-backup"
    fstype: "ext4"
    disk_type: "HDD"

# Cấu hình nén
compression_enabled: true
compression_algorithm: "zstd"
compression_level: 6

# Cấu hình mã hóa
encryption_enabled: true
encryption_algorithm: "AES-256-GCM"

# Cấu hình phân loại
auto_classify_enabled: true
classification_model: "local"

# Cấu hình version control
version_control_enabled: true
max_versions_per_item: 10

# Cấu hình audit
audit_log_enabled: true
audit_log_retention_days: 365
```

### Bước 2: Chạy Ansible Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

### Bước 3: Cấu hình Environment Variables

```bash
# Database
DATA_STORAGE_DATABASE_URL="postgresql://user:password@localhost:5432/datastore"

# Encryption Keys (PHẢI ĐỔI!)
DATA_STORAGE_ENCRYPTION_KEY="your-256-bit-encryption-key-here"
DATA_STORAGE_ID_ENCRYPTION_KEY="your-id-encryption-key-here"

# Storage Paths
DATA_STORAGE_PRIMARY_PATH="/mnt/data-primary/data"
DATA_STORAGE_HOT_PATH="/mnt/data-hot/data"
DATA_STORAGE_ARCHIVE_PATH="/mnt/data-archive/data"
DATA_STORAGE_BACKUP_PATH="/mnt/data-backup/data"
```

## Sử Dụng Prisma Schema

### Copy Schema vào Project

Copy file `prisma-schema-example.prisma` vào thư mục `prisma/schema.prisma` của project:

```bash
cp prisma-schema-example.prisma /path/to/your/project/prisma/schema.prisma
```

### Generate Prisma Client

```bash
cd /path/to/your/project
npx prisma generate
```

### Run Migrations

```bash
npx prisma migrate dev --name init
```

## Sử Dụng Data Processing Services

### 1. Compression Service

```typescript
import { CompressionService } from './services/compression.service';

const compressionService = new CompressionService();

// Nén file
const result = await compressionService.compressFile(
  '/path/to/input.txt',
  '/path/to/output.txt.zst',
  { algorithm: 'zstd', level: 6 }
);

console.log(`Compression ratio: ${result.compressionRatio}`);
console.log(`Time taken: ${result.timeTaken}ms`);
```

### 2. Encryption Service

```typescript
import { EncryptionService } from './services/encryption.service';

const encryptionService = new EncryptionService(
  process.env.DATA_STORAGE_ENCRYPTION_KEY!,
  'AES-256-GCM'
);

// Mã hóa file
await encryptionService.encryptFile(
  '/path/to/input.txt',
  '/path/to/output.encrypted'
);

// Giải mã file
await encryptionService.decryptFile(
  '/path/to/output.encrypted',
  '/path/to/decrypted.txt'
);
```

### 3. ID Encryption Service

```typescript
import { IdEncryptionService } from './services/id-encryption.service';

const idEncryptionService = new IdEncryptionService(
  process.env.DATA_STORAGE_ID_ENCRYPTION_KEY!
);

// Mã hóa ID để cung cấp cho app
const originalId = 'data-item-123';
const encryptedId = idEncryptionService.encryptId(originalId);
console.log(encryptedId); // "abc123:def456..."

// Giải mã ID khi nhận từ app
const decryptedId = idEncryptionService.decryptId(encryptedId);
console.log(decryptedId); // "data-item-123"
```

### 4. Classification Service

```typescript
import { ClassificationService } from './services/classification.service';

const classificationService = new ClassificationService();

// Phân loại file
const classification = await classificationService.classifyFile('/path/to/file.pdf');
console.log(classification);
// {
//   category: 'document',
//   tags: ['important'],
//   contentType: 'application/pdf',
//   confidence: 0.8
// }

// Extract metadata
const metadata = await classificationService.extractMetadata('/path/to/file.jpg');
console.log(metadata);
// {
//   size: 1024000,
//   mimeType: 'image/jpeg',
//   extension: 'jpg',
//   dimensions: { width: 1920, height: 1080 }
// }
```

### 5. Storage Service

```typescript
import { StorageService } from './services/storage.service';

const storageService = new StorageService('least_used');

// Khởi tạo disks
await storageService.initialize([
  {
    name: 'primary',
    mountPoint: '/mnt/data-primary',
    devicePath: '/dev/sdb1',
    totalCapacity: 500 * 1024 * 1024 * 1024, // 500GB
    usedCapacity: 0,
    availableCapacity: 500 * 1024 * 1024 * 1024,
    isPrimary: true,
  },
  // ... thêm disks khác
]);

// Lưu file
const { path, disk } = await storageService.storeFile(
  'myfile.txt',
  Buffer.from('Hello World'),
  'primary'
);

// Lấy disk info
const diskInfo = await storageService.getDiskInfo('primary');
console.log(diskInfo);
```

### 6. Version Control Service

```typescript
import { VersionControlService } from './services/version-control.service';

const versionControlService = new VersionControlService(
  '/mnt/data-primary',
  10 // max versions
);

// Tạo version mới
const version = await versionControlService.createVersion(
  'data-item-1',
  '/path/to/file.txt',
  'Updated content'
);

// List versions
const versions = await versionControlService.listVersions('data-item-1');
console.log(versions);

// Restore version
await versionControlService.restoreVersion(
  'data-item-1',
  2,
  '/path/to/restore.txt'
);
```

## API Endpoints

### Data Management

```typescript
// Upload data
POST /api/data/upload
Content-Type: multipart/form-data

// Get data by encrypted ID
GET /api/data/:encryptedId

// List data
GET /api/data?page=1&limit=20&category=document

// Update data
PUT /api/data/:encryptedId

// Delete data
DELETE /api/data/:encryptedId

// Compress data
POST /api/data/:encryptedId/compress
Body: { algorithm: 'zstd', level: 6 }

// Encrypt data
POST /api/data/:encryptedId/encrypt
Body: { algorithm: 'AES-256-GCM' }

// Get versions
GET /api/data/:encryptedId/versions

// Restore version
POST /api/data/:encryptedId/restore/:version
```

### Storage Management

```typescript
// List disks
GET /api/storage/disks

// Get disk info
GET /api/storage/disks/:encryptedId

// Get storage usage
GET /api/storage/usage

// Get allocations
GET /api/storage/allocations
```

### Classification

```typescript
// List categories
GET /api/categories

// Create category
POST /api/categories
Body: { name: 'documents', description: 'Document files' }

// Classify data
POST /api/data/:encryptedId/classify
Body: { categoryId: 'xxx', tags: ['important'] }
```

## Monitoring & Maintenance

### Check Storage Health

```bash
# Check disk usage
df -h

# Check disk health with smartctl
sudo smartctl -a /dev/sdb1

# Check storage monitoring logs
tail -f /opt/data-storage/logs/storage-monitor.log
```

### Manual Cleanup

```bash
# Run cleanup script manually
sudo /opt/data-storage/cleanup-storage.sh

# Check cleanup logs
tail -f /opt/data-storage/logs/cleanup.log
```

### Backup Strategy

```bash
# Daily backup (được setup tự động qua cron)
# Script: /opt/data-storage/cleanup-storage.sh

# Manual backup
rsync -av /mnt/data-primary/ /mnt/data-backup/manual/

# Database backup
pg_dump -U user datastore > /mnt/data-backup/db/manual.sql
```

## Security Best Practices

### 1. Encryption Keys

- **LUÔN ĐỔI encryption keys trong production**
- Sử dụng environment variables hoặc secret management
- Rotate keys định kỳ (mặc định 90 ngày)
- Không commit keys vào git

### 2. Access Control

- Sử dụng RBAC (Role-Based Access Control)
- Giới hạn access level cho data
- Log tất cả access attempts
- Review audit logs thường xuyên

### 3. Network Security

- Storage servers trong private network
- Sử dụng HTTPS/TLS cho tất cả API calls
- Firewall chỉ mở ports cần thiết
- VPN cho remote access

### 4. Data Lifecycle

- Archive data cũ định kỳ
- Xóa data hết hạn tự động
- Backup định kỳ và test restore
- Version control cho data quan trọng

## Troubleshooting

### Disk không mount được

```bash
# Check disk status
lsblk

# Check mount status
findmnt

# Manual mount
sudo mount /dev/sdb1 /mnt/data-primary

# Check logs
journalctl -xe
```

### Compression thất bại

```bash
# Check if zstd installed
which zstd

# Install zstd
sudo apt install zstd

# Test compression manually
zstd -6 input.txt -o output.txt.zst
```

### Encryption key error

```bash
# Check environment variables
echo $DATA_STORAGE_ENCRYPTION_KEY

# Key phải là 64 characters (32 bytes hex)
# Generate new key:
openssl rand -hex 32
```

### Database connection error

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check connection
psql -U user -d datastore

# Check DATABASE_URL
echo $DATA_STORAGE_DATABASE_URL
```

## File Reference

- `prisma-schema-example.prisma` - Prisma schema mẫu
- `DATA_STORAGE_CONFIG.md` - Cấu hình chi tiết storage
- `DATA_PROCESSING_SERVICES.md` - Services implementation
- `roles/data-storage/tasks/main.yml` - Ansible role setup
- `project-config.yml` - Cấu hình project

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra logs: `/opt/data-storage/logs/`
2. Kiểm tra disk health: `df -h`, `lsblk`
3. Kiểm tra service status: `systemctl status data-storage`
4. Review configuration trong `project-config.yml`
