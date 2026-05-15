# Prisma Integration - Quick Start

## Cách Sử Dụng Nhanh

### 1. Cấu hình trong `project-config.yml`

```yaml
prisma_integration_enabled: true
prisma_merge_strategy: "extend"  # extend hoặc replace
prisma_auto_generate: true
prisma_auto_migrate: true
```

### 2. Chạy Ansible Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

Ansible sẽ tự động:
- Phát hiện file `prisma/schema.prisma` trong app
- Backup schema gốc
- Thêm data storage models vào schema
- Generate Prisma client
- Run migrations

### 3. Hoặc Sử Dụng Script Manual

```bash
# Copy script vào project
cp scripts/merge-prisma-schema.py /path/to/project/

# Run script
cd /path/to/project
python merge-prisma-schema.py prisma/schema.prisma extend

# Generate client
npx prisma generate

# Run migrations
npx prisma migrate deploy
```

## Xác Nhận

```bash
# Validate schema
npx prisma validate

# Check models
npx prisma studio
```

## Files Đã Tạo

- `PRISMA_INTEGRATION_GUIDE.md` - Hướng dẫn chi tiết
- `roles/prisma-integration/tasks/main.yml` - Ansible role
- `scripts/merge-prisma-schema.py` - Python script
- `project-config.yml` - Đã cập nhật cấu hình
- `playbook.yml` - Đã thêm role

## Lưu Ý

- Schema gốc sẽ được backup thành `.prisma.backup`
- Nếu schema đã có data storage models, sẽ không thêm lại
- Có thể tạo relations giữa models có sẵn và data storage models
