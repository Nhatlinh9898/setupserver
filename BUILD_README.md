# Build Script - Hướng dẫn sử dụng nhanh

## 2 Chế độ hoạt động

### 1. Deploy đến server đã có OS (Sử dụng build.ps1)
Dùng khi bạn đã có server Linux chạy và muốn deploy project.

### 2. Full Auto Setup từ USB (Sử dụng full-auto-setup.ps1)
Dùng khi bạn muốn cài mới hoàn toàn từ USB bootable → OS → Server → Project (tự động 100%).

---

## Chế độ 1: Deploy đến server đã có OS

### Phương pháp 1: Double-click (Đơn giản nhất)

Chỉ cần double-click vào file `build.bat` để chạy build mặc định.

### Phương pháp 2: PowerShell với tùy chọn

```powershell
# Full deployment (mặc định)
.\build.ps1

# Chỉ deploy web server
.\build.ps1 -Action web

# Chỉ deploy database
.\build.ps1 -Action database

# Chỉ deploy application
.\build.ps1 -Action app

# Chỉ deploy monitoring tools
.\build.ps1 -Action monitoring

# Chỉ deploy AI/ML tools
.\build.ps1 -Action ai

# Chỉ deploy security tools
.\build.ps1 -Action security

# Xem trạng thái server
.\build.ps1 -Action status

# Bật verbose output
.\build.ps1 -Action deploy -Verbose

# Sử dụng file inventory khác
.\build.ps1 -InventoryFile my-inventory.ini

# Sử dụng file config khác
.\build.ps1 -ConfigFile my-config.yml

# Bỏ qua kiểm tra pre-flight
.\build.ps1 -SkipCheck
```

### Xem help

```powershell
.\build.ps1 -h
```

## Các Actions

| Action | Mô tả |
|--------|-------|
| `deploy` | Deploy full stack (mặc định) |
| `web` | Chỉ deploy web server (Nginx/Apache) |
| `database` | Chỉ deploy database (MySQL/PostgreSQL) |
| `app` | Chỉ deploy application (code + dependencies) |
| `monitoring` | Deploy monitoring tools (Cockpit, Webmin, Grafana, Portainer) |
| `ai` | Deploy AI/ML tools (Ollama, ChatOps, Monitoring, Healing, Assistant) |
| `security` | Deploy security tools (AI Security, Security Response, App Hardening, Container Isolation) |
| `status` | Kiểm tra trạng thái server |
| `rollback` | Rollback (chưa implement) |

## Chuẩn bị trước khi chạy

1. **Cài đặt Ansible** (nếu chưa có):
   ```bash
   pip install ansible
   ```

2. **Cấu hình inventory.ini**:
   ```ini
   [webservers]
   server-01 ansible_host=YOUR_SERVER_IP ansible_user=admin
   ```

3. **Cấu hình project-config.yml** (tùy chọn):
   - Thay đổi thông tin project
   - Cấu hình environment variables
   - Bật/tắt các services

## Lưu ý

- Script sẽ tự động kiểm tra Ansible đã cài chưa
- Script sẽ kiểm tra file inventory.ini tồn tại
- File project-config.yml là tùy chọn (nếu không có sẽ chạy với default values)
- Sử dụng `-Verbose` để xem chi tiết output
- Sử dụng `-SkipCheck` để bỏ qua các kiểm tra pre-flight

## Troubleshooting

### Ansible không được cài đặt
```
✗ Ansible is not installed
ℹ Install Ansible with: pip install ansible
```
**Giải pháp**: Cài đặt Ansible với `pip install ansible`

### File inventory không tìm thấy
```
✗ Inventory file not found: inventory.ini
```
**Giải pháp**: Tạo file inventory.ini hoặc sử dụng `-InventoryFile` để chỉ định file khác

### SSH connection failed
```
FAILED! => {"msg": "Failed to connect to the host via ssh"}
```
**Giải pháp**: 
- Kiểm tra IP address trong inventory.ini
- Kiểm tra SSH key đã được cấu hình chưa
- Đảm bảo server có thể truy cập được

## Xem thêm

- [README.md](README.md) - Hướng dẫn chi tiết
- [QUICK_START_DEPLOY.md](QUICK_START_DEPLOY.md) - Quick start guide

---

## Chế độ 2: Full Auto Setup từ USB (Tự động 100%)

Dùng khi muốn cài mới hoàn toàn từ USB bootable → OS → Server → Project.

### Cách sử dụng

```powershell
# Tạo USB bootable cho Ubuntu
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\ubuntu-22.04-server-amd64.iso

# Tạo USB bootable cho CentOS
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\centos-8.iso -OS centos

# Deploy đến server đã có (không cần USB)
.\full-auto-setup.ps1 -OnlyDeploy
```

### Workflow tự động

1. **Tạo USB bootable** (tự động, không cần Rufus)
   - Format USB
   - Copy file từ ISO sang USB
   - Copy file cấu hình cloud-init/kickstart
   - Copy toàn bộ thư mục setup vào USB
   - Tạo auto-install.sh

2. **Boot từ USB trên server**
   - Cắm USB vào server
   - Boot từ USB trong BIOS/UEFI
   - OS cài tự động (10-20 phút)

3. **auto-install.sh chạy sau boot**
   - Cài Ansible
   - Cấu hình inventory
   - Chạy server-setup.sh
   - Chạy Ansible playbook
   - Deploy project (20-40 phút)

4. **Hoàn tất**
   - Server và project sẵn sàng
   - Truy cập Cockpit, Webmin, Grafana

### Yêu cầu

- USB dung lượng tối thiểu 16GB (khuyến nghị 32GB)
- PowerShell với quyền Administrator
- Ubuntu Server ISO hoặc CentOS ISO
- Server có kết nối internet

### Sau khi cài xong

```bash
# Kiểm tra log cài đặt
tail -f /opt/setup/auto-install.log

# Truy cập web interfaces
# Cockpit: https://server_ip:9090
# Webmin: https://server_ip:10000
# Grafana: http://server_ip:3000
# Portainer: https://server_ip:9443
```

### Xem help

```powershell
.\full-auto-setup.ps1 -h
```
