# Hướng Dẫn Tạo USB Bootable để Cài Đặt Server Tự Động

## Tổng Quan

Script này tạo USB bootable có thể cài đặt toàn bộ hệ thống (OS + Server + Projects) tự động chỉ với một lần boot.

## Yêu Cầu

- USB dung lượng tối thiểu 16GB (khuyến nghị 32GB)
- Windows với quyền Administrator
- Rufus: https://rufus.ie/
- Ubuntu Server ISO hoặc CentOS ISO
- Thư mục setup này đã được cấu hình đầy đủ

## Cách Sử Dụng

### Bước 1: Chuẩn bị

1. Tải Ubuntu Server ISO hoặc CentOS ISO
2. Cắm USB vào máy
3. Mở PowerShell với quyền Administrator

### Bước 2: Chạy Script

```powershell
cd C:\Users\user03\Desktop\linh20220211\setup

# Chạy script với tham số
.\create-usb-setup.ps1 -USBDrive "E:" -ISOPath "C:\Downloads\ubuntu-22.04-server-amd64.iso"

# Hoặc chỉ định đường dẫn setup khác
.\create-usb-setup.ps1 -USBDrive "E:" -ISOPath "C:\Downloads\ubuntu-22.04-server-amd64.iso" -SetupPath "C:\path\to\setup"
```

### Bước 3: Tạo USB Bootable với Rufus

Script sẽ dừng và yêu cầu bạn dùng Rufus:

1. Mở Rufus
2. Device: Chọn USB của bạn
3. Boot selection: Chọn file ISO
4. Partition scheme: MBR (cho legacy BIOS) hoặc GPT (cho UEFI)
5. File system: FAT32
6. Nhấn Start

Sau khi hoàn thành, quay lại PowerShell và nhấn Enter.

### Bước 4: Script Tự Động Hoàn Thiện

Script sẽ tự động:
- Format USB
- Copy file cấu hình cloud-init/kickstart
- Copy toàn bộ thư mục setup vào USB
- Tạo script auto-install.sh
- Cấu hình cloud-init để chạy auto-install sau khi boot

### Bước 5: Boot từ USB trên Server

1. Cắm USB vào server
2. Boot và chọn boot từ USB trong BIOS/UEFI

**Đối với Ubuntu:**
- Khi màn hình GRUB hiện ra, nhấn `e`
- Thêm vào cuối dòng: `cloud-init=nocloud-net;s=/cdrom/nocloud/`
- Nhấn `F10` để boot

**Đối với CentOS:**
- Khi màn hình boot hiện ra, nhấn `Tab`
- Thêm vào cuối dòng: `inst.ks=cdrom:/ks.cfg`
- Nhấn Enter

### Bước 6: Đợi Cài Đặt Tự Động

- OS sẽ cài đặt tự động (10-20 phút)
- Sau khi reboot, script auto-install.sh sẽ chạy
- Toàn bộ server và projects sẽ được cài đặt (20-40 phút)

Tổng thời gian: **30-60 phút**

## Xác Nhận Sau Khi Cài Xong

```bash
# Kiểm tra log cài đặt
tail -f /opt/setup/auto-install.log

# Kiểm tra services
systemctl status nginx
systemctl status docker
systemctl status cockpit

# Kiểm tra application
curl http://localhost

# Lấy IP address
ip addr show
```

## Truy Cập Web Interfaces

Sau khi cài xong, bạn có thể truy cập:

- **Cockpit**: `https://server_ip:9090` - Quản lý server
- **Webmin**: `https://server_ip:10000` - Quản lý hệ thống
- **Grafana**: `http://server_ip:3000` - Monitoring (user: admin, password: admin)
- **Portainer**: `https://server_ip:9443` - Docker management

## Cấu Hình Trước Khi Tạo USB

Trước khi chạy script, hãy cấu hình `project-config.yml`:

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

## Lưu Ý Quan Trọng

1. **Dung lượng USB**: Cần tối thiểu 16GB, khuyến nghị 32GB
2. **Network**: Server cần kết nối internet để download packages
3. **Test trước**: Test trên VM trước khi dùng với server production
4. **Backup**: Backup dữ liệu quan trọng trước khi cài đặt mới
5. **Password**: Đổi password mặc định trong các file cấu hình

## Xử Lý Lỗi Thường Gặp

### Lỗi: Script cần quyền Administrator
- Chuột phải vào PowerShell → "Run as Administrator"

### Lỗi: Không tìm thấy USB drive
- Kiểm tra letter của USB (E:, F:, G:, v.v.)
- Đảm bảo USB đã được cắm và nhận diện

### Lỗi: Không tìm thấy file ISO
- Kiểm tra đường dẫn ISO có đúng không
- Đảm bảo file ISO đã tải hoàn tất

### Lỗi: Cloud-init không chạy
- Kiểm tra file user-data có đúng định dạng YAML không
- Kiểm tra đường dẫn `/cdrom/nocloud/` có đúng không
- Xem log: `/var/log/cloud-init-output.log`

### Lỗi: Ansible không cài được
- Kiểm tra kết nối internet
- Kiểm tra Python version (cần 3.6+)
- Xem log: `/opt/setup/auto-install.log`

### Lỗi: Deploy project thất bại
- Kiểm tra `project-config.yml` có đúng không
- Kiểm tra Git repository có public không
- Nếu repository private, cần cấu hình SSH key

## Tùy Chỉnh

### Chỉ Cài Đặt Server, Không Deploy Project

Edit `auto-install.sh` và comment dòng chạy Ansible:

```bash
# ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

### Chỉ Cài Đặt Một Số Roles

Edit `playbook.yml` và comment các roles không cần:

```yaml
# - name: Setup AI/ML Tools
#   roles:
#     - ai-ml
```

### Thêm Script Tùy Chỉnh

Thêm script của bạn vào thư mục setup và gọi trong `auto-install.sh`:

```bash
# Chạy script tùy chỉnh
bash /opt/setup/my-custom-script.sh
```

## Workflow Chi Tiết

Xem workflow chi tiết tại: `.windsurf/workflows/create-usb-setup.md`

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra log: `/opt/setup/auto-install.log`
2. Kiểm tra cloud-init log: `/var/log/cloud-init-output.log`
3. Kiểm tra Ansible log trong thư mục `/opt/setup/`
4. Xem tài liệu chi tiết trong `README.md`
