# Build Guide - Hướng dẫn sử dụng Build Scripts

## Tổng quan

Hệ thống build này hỗ trợ 2 chế độ hoạt động:

### 1. Deploy đến server đã có OS (build.ps1)
Dùng khi bạn đã có server Linux đang chạy và muốn deploy project.

### 2. Full Auto Setup từ USB (full-auto-setup.ps1) ⭐
Dùng khi muốn cài mới hoàn toàn từ USB bootable → OS → Server → Project (tự động 100%).

---

## Chế độ 1: Deploy đến server đã có OS

### Khi nào dùng?
- Server Linux đã cài sẵn
- Chỉ cần deploy project và cấu hình services

### Cách sử dụng

**Đơn giản nhất:**
```powershell
# Double-click vào build.bat
```

**Với tùy chọn:**
```powershell
# Full deployment
.\build.ps1

# Chỉ deploy app
.\build.ps1 -Action app

# Chỉ deploy monitoring
.\build.ps1 -Action monitoring

# Xem help
.\build.ps1 -h
```

### Các actions có sẵn
- `deploy` - Full stack (mặc định)
- `web` - Web server only
- `database` - Database only
- `app` - Application only
- `monitoring` - Monitoring tools
- `ai` - AI/ML tools
- `security` - Security tools
- `status` - Check server status

### Yêu cầu
- Ansible đã cài (`pip install ansible`)
- File `inventory.ini` đã cấu hình với server IP
- File `project-config.yml` đã cấu hình (tùy chọn)

---

## Chế độ 2: Full Auto Setup từ USB ⭐

### Khi nào dùng?
- Cài mới server từ đầu
- Muốn tự động hóa toàn bộ quy trình
- Không muốn cấu hình thủ công từng bước

### Cách sử dụng

**Đơn giản nhất:**
```powershell
# Double-click vào full-auto-setup.bat
# Nhập USB drive letter và đường dẫn ISO
```

**Với PowerShell:**
```powershell
# Ubuntu
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\ubuntu-22.04-server-amd64.iso

# CentOS
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\centos-8.iso -OS centos

# Deploy đến server đã có (không cần USB)
.\full-auto-setup.ps1 -OnlyDeploy

# Xem help
.\full-auto-setup.ps1 -h
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

---

## So sánh 2 chế độ

| Tính năng | build.ps1 | full-auto-setup.ps1 |
|-----------|-----------|---------------------|
| Cài OS | ❌ Không | ✅ Tự động |
| Cấu hình server | ✅ Có | ✅ Tự động |
| Deploy project | ✅ Có | ✅ Tự động |
| Cần USB | ❌ Không | ✅ Có |
| Cần Rufus | ❌ Không | ❌ Không (tự động) |
| Thời gian | 10-20 phút | 30-60 phút |
| Độ khó | Dễ | Rất dễ |

---

## Chuẩn bị trước khi chạy

### Cấu hình project-config.yml

Trước khi chạy bất kỳ script nào, hãy cấu hình `project-config.yml`:

```yaml
# Thông tin Git Repository
git_repository: "https://github.com/yourusername/your-repo.git"
git_branch: "main"

# Thông tin Project
app_name: "my-app"
app_user: "admin"
project_path: "/opt/apps/my-app"
app_port: 3000

# Environment Variables
env_vars:
  NODE_ENV: "production"
  PORT: "3000"
  DATABASE_URL: "postgresql://user:password@localhost:5432/mydb"
```

### Cấu hình inventory.ini (chỉ cho build.ps1)

```ini
[webservers]
server-01 ansible_host=YOUR_SERVER_IP ansible_user=admin
```

---

## Troubleshooting

### build.ps1

**Ansible không được cài đặt**
```
✗ Ansible is not installed
ℹ Install Ansible with: pip install ansible
```
**Giải pháp**: Cài đặt Ansible với `pip install ansible`

**File inventory không tìm thấy**
```
✗ Inventory file not found: inventory.ini
```
**Giải pháp**: Tạo file inventory.ini hoặc sử dụng `-InventoryFile`

**SSH connection failed**
```
FAILED! => {"msg": "Failed to connect to the host via ssh"}
```
**Giải pháp**: Kiểm tra IP address, SSH key, và kết nối network

### full-auto-setup.ps1

**Script cần quyền Administrator**
```
✗ Script cần chạy với quyền Administrator
```
**Giải pháp**: Chuột phải vào PowerShell → "Run as Administrator"

**Không tìm thấy USB drive**
```
✗ Không tìm thấy drive E:
```
**Giải pháp**: Kiểm tra letter của USB (E:, F:, G:, v.v.)

**Không tìm thấy file ISO**
```
✗ Không tìm thấy file ISO: C:\Downloads\ubuntu.iso
```
**Giải pháp**: Kiểm tra đường dẫn ISO có đúng không

**Cloud-init không chạy**
```
Lỗi: Cloud-init không chạy
```
**Giải pháp**: 
- Kiểm tra file user-data có đúng định dạng YAML không
- Kiểm tra đường dẫn `/cdrom/nocloud/` có đúng không
- Xem log: `/var/log/cloud-init-output.log`

---

## Xem thêm

- [BUILD_README.md](BUILD_README.md) - Hướng dẫn chi tiết build.ps1
- [README.md](README.md) - Hướng dẫn chi tiết toàn bộ dự án
- [USB_SETUP_GUIDE.md](USB_SETUP_GUIDE.md) - Hướng dẫn USB setup
- [.windsurf/workflows/create-usb-setup.md](.windsurf/workflows/create-usb-setup.md) - Workflow chi tiết

---

## Quick Reference

```powershell
# Deploy đến server đã có
.\build.ps1

# Tạo USB bootable (full auto)
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\ubuntu-22.04.iso

# Double-click versions
build.bat              # Deploy
full-auto-setup.bat   # USB bootable
```
