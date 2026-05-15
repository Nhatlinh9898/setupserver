# Hướng dẫn Deploy AmazeBid

## Tổng quan

Script `deploy-amazebid.ps1` giúp bạn deploy, rollback, backup và kiểm tra trạng thái ứng dụng AmazeBid một cách dễ dàng.

## Yêu cầu

- Ansible đã được cài đặt trên máy local
- File cấu hình `inventory.ini` đã được cập nhật với IP server
- File cấu hình `project-config.yml` đã được cấu hình đúng

## Cách sử dụng

### 1. Deploy ứng dụng

```powershell
# Deploy bình thường (sẽ tự động push code lên GitHub trước)
.\deploy-amazebid.ps1 -Action deploy

# Hoặc chỉ chạy script (mặc định là deploy)
.\deploy-amazebid.ps1
```

Quy trình:
1. Script sẽ push code từ thư mục `app-code` lên GitHub
2. Ansible sẽ pull code mới từ GitHub về server
3. Cài đặt dependencies (nếu có thay đổi)
4. Chạy build (nếu cần)
5. Chạy Prisma migrations (nếu có thay đổi schema)
6. Restart ứng dụng với PM2
7. Tự động backup trước khi deploy (đã cấu hình trong `project-config.yml`)

### 2. Rollback về version trước

```powershell
# Rollback về version ngay trước đó
.\deploy-amazebid.ps1 -Action rollback

# Rollback về commit cụ thể
.\deploy-amazebid.ps1 -Action rollback -Version "abc123def456"
```

Quy trình:
1. Script sẽ checkout về commit được chỉ định
2. Force push lên GitHub
3. Ansible sẽ redeploy với version đó

### 3. Backup thủ công

```powershell
# Backup database và code
.\deploy-amazebid.ps1 -Action backup
```

Quy trình:
1. Backup database trên server
2. Copy code từ `app-code` sang thư mục `backups\`

### 4. Kiểm tra trạng thái

```powershell
# Xem trạng thái Git và server
.\deploy-amazebid.ps1 -Action status
```

## Quy trình làm việc khuyến nghị

### Khi phát triển mới

```powershell
# 1. Thay đổi code trong app-code/
# 2. Test local (nếu cần)

# 3. Deploy
.\deploy-amazebid.ps1 -Action deploy

# 4. Kiểm tra trạng thái
.\deploy-amazebid.ps1 -Action status
```

### Khi có lỗi sau deploy

```powershell
# 1. Rollback về version trước
.\deploy-amazebid.ps1 -Action rollback

# 2. Kiểm tra lỗi
# 3. Fix lỗi trong app-code/

# 4. Deploy lại
.\deploy-amazebid.ps1 -Action deploy
```

### Khi thay đổi database schema

```powershell
# 1. Thay đổi prisma/schema.prisma
# 2. Deploy (Ansible sẽ tự động chạy migrations)
.\deploy-amazebid.ps1 -Action deploy
```

## Cấu hình Backup & Rollback

Trong file `project-config.yml`:

```yaml
# Backup Configuration
backup_enabled: true
backup_before_deploy: true  # Tự động backup trước khi deploy
backup_retention_days: 30  # Giữ backup trong 30 ngày
backup_database: true  # Backup database
backup_code: true  # Backup code
backup_path: "/opt/backups/amazebid"

# Rollback Configuration
rollback_enabled: true
rollback_auto_on_failure: false  # Tự động rollback khi deploy thất bại
rollback_keep_versions: 5  # Giữ 5 phiên bản để rollback
```

## Các kịch bản cụ thể

### Chỉ deploy code (không thay đổi dependencies)

```bash
ansible-playbook -i inventory.ini playbook.yml --tags deploy,application -e @project-config.yml
```

### Chỉ cài đặt dependencies mới

```bash
ansible-playbook -i inventory.ini playbook.yml --tags dependencies -e @project-config.yml
```

### Chỉ chạy database migrations

```bash
ansible-playbook -i inventory.ini playbook.yml --tags prisma-migrate -e @project-config.yml
```

### Chỉ restart ứng dụng

```bash
ansible-playbook -i inventory.ini playbook.yml --tags application-restart -e @project-config.yml
```

## Xem logs trên server

```bash
# Xem logs PM2
ssh admin@your-server-ip
pm2 logs amazebid

# Xem logs Nginx
sudo tail -f /var/log/nginx/error.log

# Xem logs application
sudo tail -f /opt/apps/amazebid/logs/app.log
```

## Troubleshooting

### Deploy thất bại

1. Kiểm tra logs Ansible để xem lỗi cụ thể
2. Kiểm tra kết nối đến server
3. Kiểm tra quyền truy cập GitHub
4. Rollback về version trước nếu cần

### Database migration thất bại

1. Kiểm tra kết nối database
2. Kiểm tra schema Prisma
3. Xem logs migration: `sudo tail -f /opt/apps/amazebid/prisma/migrations.log`

### Ứng dụng không start

1. Kiểm tra PM2 status: `pm2 status`
2. Kiểm tra logs: `pm2 logs amazebid`
3. Kiểm tra port: `sudo netstat -tlnp | grep 3000`
4. Kiểm tra environment variables

## Tích hợp CI/CD (Tùy chọn)

Bạn có thể tích hợp với GitHub Actions để tự động deploy khi push code:

```yaml
# .github/workflows/deploy.yml
name: Deploy AmazeBid
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy with Ansible
        uses: arillso/action-ansible-playbook@v1
        with:
          playbook: playbook.yml
          inventory: inventory.ini
          extra_vars: '@project-config.yml'
```

## Lưu ý quan trọng

1. **Luôn test trước khi deploy production**
2. **Backup trước khi thay đổi quan trọng**
3. **Kiểm tra environment variables trong production**
4. **Giữ secret keys an toàn** (không commit vào git)
5. **Monitor logs sau mỗi deploy**
6. **Test rollback procedure thường xuyên**

## Hỗ trợ

Nếu gặp vấn đề:
1. Kiểm tra logs Ansible
2. Kiểm tra logs server
3. Xem tài liệu Ansible roles trong thư mục `roles/`
4. Kiểm tra file cấu hình `project-config.yml`
