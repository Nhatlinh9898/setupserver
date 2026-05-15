---
description: Tạo USB bootable để cài đặt server và deploy dự án tự động
---

# Quy trình tạo USB Bootable để Cài Đặt Server Tự Động

Quy trình này tạo USB có thể boot và cài đặt toàn bộ hệ thống (OS + Server + Projects) tự động.

## 🚀 Cách nhanh nhất - Sử dụng Script Tự Động

Thay vì làm thủ công, bạn có thể sử dụng script tự động hóa toàn bộ quy trình:

```powershell
# Chạy script full-auto-setup.ps1 (không cần Rufus manual)
.\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\ubuntu-22.04-server-amd64.iso

# Hoặc double-click vào full-auto-setup.bat
```

Script này sẽ tự động:
- Format USB
- Tạo USB bootable (sử dụng PowerShell, không cần Rufus)
- Copy file cấu hình cloud-init/kickstart
- Copy toàn bộ thư mục setup vào USB
- Tạo auto-install.sh
- Cấu hình cloud-init để chạy auto-install sau khi boot

**Xem chi tiết:** [full-auto-setup.ps1](../full-auto-setup.ps1)

---

## Bước 1: Chuẩn bị USB (trên Windows)

### 1.1 Format USB
- Dùng Rufus hoặc Disk Management để format USB thành FAT32
- Đảm bảo USB có dung lượng tối thiểu 16GB (khuyến nghị 32GB)

### 1.2 Tải ISO
- Ubuntu Server: https://ubuntu.com/download/server
- Hoặc CentOS: https://www.centos.org/download/

## Bước 2: Tạo USB Bootable với Rufus

### 2.1 Mở Rufus
- Device: Chọn USB của bạn
- Boot selection: Chọn file ISO đã tải
- Partition scheme: MBR (cho legacy BIOS) hoặc GPT (cho UEFI)
- File system: FAT32
- Cluster size: Default

### 2.2 Start
- Nhấn Start để tạo USB bootable
- Đợi quá trình hoàn thành

## Bước 3: Copy File Cấu Hình vào USB

### 3.1 Tạo thư mục cấu hình trên USB

**Đối với Ubuntu:**
```
USB:/nocloud/user-data
USB:/nocloud/meta-data
```

**Đối với CentOS:**
```
USB:/ks.cfg
```

### 3.2 Copy file cấu hình từ thư mục setup

```powershell
# Copy file cloud-init cho Ubuntu
copy c:\Users\user03\Desktop\linh20220211\setup\ubuntu-server-cloud-init.yaml E:\nocloud\user-data

# Tạo file meta-data rỗng
echo. > E:\nocloud\meta-data

# Hoặc copy kickstart cho CentOS
copy c:\Users\user03\Desktop\linh20220211\setup\centos-kickstart.cfg E:\ks.cfg
```

## Bước 4: Copy Toàn Bộ Thư Mục Setup vào USB

```powershell
# Copy toàn bộ thư mục setup vào USB
xcopy /E /I /Y c:\Users\user03\Desktop\linh20220211\setup E:\setup
```

## Bước 5: Tạo Script Auto-Run Sau Khi Boot

Tạo file `E:\setup\auto-install.sh`:

```bash
#!/bin/bash
# Auto-install script - chạy sau khi OS cài xong

set -e

echo "=========================================="
echo "Bắt đầu cài đặt server và deploy dự án"
echo "=========================================="

# 1. Cài đặt Ansible trên server
echo "[1/5] Cài đặt Ansible..."
apt update
apt install -y python3 python3-pip
pip3 install ansible

# 2. Cấu hình inventory với IP hiện tại
echo "[2/5] Cấu hình inventory..."
SERVER_IP=$(hostname -I | awk '{print $1}')
cat > /opt/setup/inventory.ini << EOF
[appservers]
localhost ansible_host=$SERVER_IP ansible_connection=local

[dbservers]
localhost ansible_host=$SERVER_IP ansible_connection=local

[allservers]
localhost ansible_host=$SERVER_IP ansible_connection=local
EOF

# 3. Chạy server-setup.sh
echo "[3/5] Chạy server-setup.sh..."
cd /opt/setup
sudo bash server-setup.sh << EOF
y
y
EOF

# 4. Chạy Ansible playbook
echo "[4/5] Chạy Ansible playbook..."
cd /opt/setup
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml

# 5. Hoàn tất
echo "[5/5] Cài đặt hoàn tất!"
echo "=========================================="
echo "Server đã sẵn sàng!"
echo "=========================================="
echo "Truy cập Cockpit: https://$SERVER_IP:9090"
echo "Truy cập Webmin: https://$SERVER_IP:10000"
echo "Truy cập Grafana: http://$SERVER_IP:3000"
echo "=========================================="
```

## Bước 6: Cấu Hình Cloud-Init để Chạy Auto-Install

### 6.1 Edit file ubuntu-server-cloud-init.yaml

Thêm vào cuối file (trước cuối):

```yaml
# Run custom script after first boot
runcmd:
  - mkdir -p /opt/setup
  - cp -r /media/usb/setup/* /opt/setup/
  - chmod +x /opt/setup/auto-install.sh
  - bash /opt/setup/auto-install.sh
```

### 6.2 Hoặc edit centos-kickstart.cfg

Thêm vào cuối file (trước cuối):

```bash
%post --log=/root/ks-post.log
mkdir -p /opt/setup
cp -r /mnt/source/setup/* /opt/setup/
chmod +x /opt/setup/auto-install.sh
bash /opt/setup/auto-install.sh
%end
```

## Bước 7: Boot từ USB và Cài Đặt

### 7.1 Boot từ USB
- Cắm USB vào server
- Boot và chọn boot từ USB trong BIOS/UEFI

### 7.2 Cài đặt Ubuntu
- Khi màn hình GRUB hiện ra, nhấn `e`
- Thêm vào cuối dòng: `cloud-init=nocloud-net;s=/cdrom/nocloud/`
- Nhấn `F10` để boot

### 7.3 Cài đặt CentOS
- Khi màn hình boot hiện ra, nhấn `Tab`
- Thêm vào cuối dòng: `inst.ks=cdrom:/ks.cfg`
- Nhấn Enter

### 7.4 Đợi cài đặt
- OS sẽ cài đặt tự động
- Sau khi reboot, script auto-install.sh sẽ chạy
- Toàn bộ server và projects sẽ được cài đặt tự động

## Bước 8: Xác Nhận Cài Đặt

Sau khi cài xong (khoảng 30-60 phút):

```bash
# Kiểm tra services
systemctl status nginx
systemctl status docker
systemctl status cockpit

# Kiểm tra application
curl http://localhost

# Truy cập web interfaces
# - Cockpit: https://server_ip:9090
# - Webmin: https://server_ip:10000
# - Grafana: http://server_ip:3000
```

## Script Tự Động Hóa Toàn Bộ (Windows PowerShell)

Lưu file `create-usb-setup.ps1`:

```powershell
# Script tạo USB bootable tự động
# Chạy với PowerShell Administrator

$USB_DRIVE = "E:"  # Thay đổi theo USB của bạn
$ISO_PATH = "C:\Downloads\ubuntu-22.04-server-amd64.iso"  # Thay đổi theo ISO của bạn
$SETUP_PATH = "C:\Users\user03\Desktop\linh20220211\setup"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Tạo USB Bootable để Cài Đặt Server Tự Động" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 1. Format USB
Write-Host "[1/6] Format USB..." -ForegroundColor Yellow
Format-Volume -DriveLetter $USB_DRIVE[0] -FileSystem FAT32 -Force

# 2. Tạo USB bootable với Rufus (manual step)
Write-Host "[2/6] Vui lòng dùng Rufus để tạo USB bootable với ISO:" -ForegroundColor Yellow
Write-Host "   ISO: $ISO_PATH" -ForegroundColor Cyan
Write-Host "   USB: $USB_DRIVE" -ForegroundColor Cyan
Read-Host "Nhấn Enter sau khi hoàn thành với Rufus"

# 3. Copy file cấu hình
Write-Host "[3/6] Copy file cấu hình..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$USB_DRIVE\nocloud"
Copy-Item "$SETUP_PATH\ubuntu-server-cloud-init.yaml" "$USB_DRIVE\nocloud\user-data"
"" | Out-File "$USB_DRIVE\nocloud\meta-data"

# 4. Copy thư mục setup
Write-Host "[4/6] Copy thư mục setup vào USB..." -ForegroundColor Yellow
Copy-Item -Recurse -Force "$SETUP_PATH" "$USB_DRIVE\setup"

# 5. Tạo auto-install.sh
Write-Host "[5/6] Tạo auto-install.sh..." -ForegroundColor Yellow
$autoInstallScript = @'
#!/bin/bash
set -e
echo "=========================================="
echo "Bắt đầu cài đặt server và deploy dự án"
echo "=========================================="
echo "[1/5] Cài đặt Ansible..."
apt update
apt install -y python3 python3-pip
pip3 install ansible
echo "[2/5] Cấu hình inventory..."
SERVER_IP=$(hostname -I | awk '{print $1}')
cat > /opt/setup/inventory.ini << EOF
[appservers]
localhost ansible_host=$SERVER_IP ansible_connection=local
[dbservers]
localhost ansible_host=$SERVER_IP ansible_connection=local
[allservers]
localhost ansible_host=$SERVER_IP ansible_connection=local
EOF
echo "[3/5] Chạy server-setup.sh..."
cd /opt/setup
sudo bash server-setup.sh << EOF
y
y
EOF
echo "[4/5] Chạy Ansible playbook..."
cd /opt/setup
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
echo "[5/5] Cài đặt hoàn tất!"
echo "=========================================="
echo "Server đã sẵn sàng!"
echo "=========================================="
echo "Truy cập Cockpit: https://$SERVER_IP:9090"
echo "Truy cập Webmin: https://$SERVER_IP:10000"
echo "Truy cập Grafana: http://$SERVER_IP:3000"
echo "=========================================="
'@
$autoInstallScript | Out-File "$USB_DRIVE\setup\auto-install.sh" -Encoding ASCII

# 6. Cấu hình cloud-init
Write-Host "[6/6] Cấu hình cloud-init..." -ForegroundColor Yellow
$cloudInitContent = Get-Content "$USB_DRIVE\setup\ubuntu-server-cloud-init.yaml"
$runcmd = @"

# Run custom script after first boot
runcmd:
  - mkdir -p /opt/setup
  - cp -r /media/usb/setup/* /opt/setup/ || cp -r /cdrom/setup/* /opt/setup/
  - chmod +x /opt/setup/auto-install.sh
  - bash /opt/setup/auto-install.sh
"@
$cloudInitContent + $runcmd | Out-File "$USB_DRIVE\nocloud\user-data" -Encoding ASCII

Write-Host "========================================" -ForegroundColor Green
Write-Host "USB đã sẵn sàng!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Các bước tiếp theo:" -ForegroundColor Cyan
Write-Host "1. Cắm USB vào server" -ForegroundColor White
Write-Host "2. Boot từ USB" -ForegroundColor White
Write-Host "3. Nhấn 'e' ở GRUB, thêm: cloud-init=nocloud-net;s=/cdrom/nocloud/" -ForegroundColor White
Write-Host "4. Nhấn F10 để boot" -ForegroundColor White
Write-Host "5. Đợi cài đặt tự động (30-60 phút)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
```

## Lưu Ý Quan Trọng

1. **Dung lượng USB**: Cần tối thiểu 16GB, khuyến nghị 32GB
2. **Thời gian cài đặt**: 30-60 phút tùy cấu hình server
3. **Network**: Server cần kết nối internet để download packages
4. **Project config**: Đảm bảo `project-config.yml` đã cấu hình đúng trước khi tạo USB
5. **Test trước**: Test trên VM trước khi dùng với server production
6. **Backup**: Backup dữ liệu quan trọng trước khi cài đặt mới

## Xử Lý Lỗi Thường Gặp

### Lỗi: Không tìm thấy USB khi boot
- Kiểm tra BIOS/UEFI boot order
- Thử chế độ Legacy BIOS thay vì UEFI

### Lỗi: Cloud-init không chạy
- Kiểm tra file user-data có đúng định dạng YAML không
- Kiểm tra đường dẫn `/cdrom/nocloud/` có đúng không

### Lỗi: Ansible không cài được
- Kiểm tra kết nối internet
- Kiểm tra Python version (cần 3.6+)

### Lỗi: Deploy project thất bại
- Kiểm tra `project-config.yml` có đúng không
- Kiểm tra Git repository có public không (hoặc cấu hình SSH key)
