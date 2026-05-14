# Script tạo USB Bootable để Cài Đặt Server Tự Động
# Chạy với PowerShell Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$USBDrive,
    
    [Parameter(Mandatory=$true)]
    [string]$ISOPath,
    
    [Parameter(Mandatory=$false)]
    [string]$SetupPath = "C:\Users\user03\Desktop\linh20220211\setup"
)

# Kiểm tra quyền Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Lỗi: Script cần chạy với quyền Administrator" -ForegroundColor Red
    Write-Host "Hãy chuột phải vào PowerShell và chọn 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Kiểm tra USB drive
if (-not (Test-Path $USBDrive)) {
    Write-Host "Lỗi: Không tìm thấy drive $USBDrive" -ForegroundColor Red
    exit 1
}

# Kiểm tra ISO file
if (-not (Test-Path $ISOPath)) {
    Write-Host "Lỗi: Không tìm thấy file ISO: $ISOPath" -ForegroundColor Red
    exit 1
}

# Kiểm tra thư mục setup
if (-not (Test-Path $SetupPath)) {
    Write-Host "Lỗi: Không tìm thấy thư mục setup: $SetupPath" -ForegroundColor Red
    exit 1
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Tạo USB Bootable để Cài Đặt Server Tự Động" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "USB Drive: $USBDrive" -ForegroundColor Cyan
Write-Host "ISO Path: $ISOPath" -ForegroundColor Cyan
Write-Host "Setup Path: $SetupPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

# Xác nhận
$confirm = Read-Host "USB sẽ được format. Tiếp tục? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Đã hủy." -ForegroundColor Yellow
    exit 0
}

# 1. Format USB
Write-Host "`n[1/7] Format USB..." -ForegroundColor Yellow
try {
    $driveLetter = $USBDrive[0]
    Format-Volume -DriveLetter $driveLetter -FileSystem FAT32 -Force -ErrorAction Stop
    Write-Host "Đã format USB thành công" -ForegroundColor Green
} catch {
    Write-Host "Lỗi khi format USB: $_" -ForegroundColor Red
    exit 1
}

# 2. Tạo USB bootable với Rufus (manual step)
Write-Host "`n[2/7] Vui lòng dùng Rufus để tạo USB bootable:" -ForegroundColor Yellow
Write-Host "   1. Mở Rufus (https://rufus.ie/)" -ForegroundColor White
Write-Host "   2. Device: Chọn $USBDrive" -ForegroundColor White
Write-Host "   3. Boot selection: Chọn ISO file" -ForegroundColor White
Write-Host "   4. ISO: $ISOPath" -ForegroundColor Cyan
Write-Host "   5. Partition scheme: MBR (hoặc GPT cho UEFI)" -ForegroundColor White
Write-Host "   6. File system: FAT32" -ForegroundColor White
Write-Host "   7. Nhấn Start để tạo USB bootable" -ForegroundColor White
$confirm = Read-Host "Nhấn Enter sau khi hoàn thành với Rufus"

# 3. Copy file cấu hình cloud-init
Write-Host "`n[3/7] Copy file cấu hình cloud-init..." -ForegroundColor Yellow
try {
    $nocloudPath = "$USBDrive\nocloud"
    New-Item -ItemType Directory -Force -Path $nocloudPath | Out-Null
    
    if (Test-Path "$SetupPath\ubuntu-server-cloud-init.yaml") {
        Copy-Item "$SetupPath\ubuntu-server-cloud-init.yaml" "$nocloudPath\user-data" -Force
        "" | Out-File "$nocloudPath\meta-data" -Encoding ASCII
        Write-Host "Đã copy file cloud-init cho Ubuntu" -ForegroundColor Green
    } elseif (Test-Path "$SetupPath\centos-kickstart.cfg") {
        Copy-Item "$SetupPath\centos-kickstart.cfg" "$USBDrive\ks.cfg" -Force
        Write-Host "Đã copy file kickstart cho CentOS" -ForegroundColor Green
    } else {
        Write-Host "Cảnh báo: Không tìm thấy file cloud-init hoặc kickstart" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Lỗi khi copy file cấu hình: $_" -ForegroundColor Red
    exit 1
}

# 4. Copy thư mục setup vào USB
Write-Host "`n[4/7] Copy thư mục setup vào USB..." -ForegroundColor Yellow
try {
    $usbSetupPath = "$USBDrive\setup"
    if (Test-Path $usbSetupPath) {
        Remove-Item $usbSetupPath -Recurse -Force
    }
    Copy-Item -Recurse -Force $SetupPath $usbSetupPath
    Write-Host "Đã copy thư mục setup vào USB" -ForegroundColor Green
} catch {
    Write-Host "Lỗi khi copy thư mục setup: $_" -ForegroundColor Red
    exit 1
}

# 5. Tạo auto-install.sh
Write-Host "`n[5/7] Tạo auto-install.sh..." -ForegroundColor Yellow
try {
    $autoInstallScript = @'
#!/bin/bash
set -e
echo "=========================================="
echo "Bắt đầu cài đặt server và deploy dự án"
echo "=========================================="

# 1. Cài đặt Ansible
echo "[1/5] Cài đặt Ansible..."
apt update
apt install -y python3 python3-pip
pip3 install ansible

# 2. Cấu hình inventory
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
'@
    $autoInstallScript | Out-File "$usbSetupPath\auto-install.sh" -Encoding ASCII
    Write-Host "Đã tạo auto-install.sh" -ForegroundColor Green
} catch {
    Write-Host "Lỗi khi tạo auto-install.sh: $_" -ForegroundColor Red
    exit 1
}

# 6. Cấu hình cloud-init để chạy auto-install
Write-Host "`n[6/7] Cấu hình cloud-init để chạy auto-install..." -ForegroundColor Yellow
try {
    if (Test-Path "$nocloudPath\user-data") {
        $cloudInitContent = Get-Content "$nocloudPath\user-data" -Raw
        $runcmd = @"

# Run custom script after first boot
runcmd:
  - mkdir -p /opt/setup
  - cp -r /media/usb/setup/* /opt/setup/ 2>/dev/null || cp -r /cdrom/setup/* /opt/setup/ 2>/dev/null || true
  - chmod +x /opt/setup/auto-install.sh
  - bash /opt/setup/auto-install.sh > /opt/setup/auto-install.log 2>&1
"@
        $cloudInitContent + $runcmd | Out-File "$nocloudPath\user-data" -Encoding ASCII
        Write-Host "Đã cấu hình cloud-init" -ForegroundColor Green
    }
} catch {
    Write-Host "Lỗi khi cấu hình cloud-init: $_" -ForegroundColor Red
    exit 1
}

# 7. Hoàn tất
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "USB đã sẵn sàng!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Các bước tiếp theo:" -ForegroundColor Cyan
Write-Host "1. Cắm USB vào server" -ForegroundColor White
Write-Host "2. Boot từ USB" -ForegroundColor White
Write-Host "3. Nhấn 'e' ở GRUB (Ubuntu) hoặc 'Tab' (CentOS)" -ForegroundColor White
Write-Host "4. Thêm vào cuối dòng:" -ForegroundColor White
Write-Host "   Ubuntu: cloud-init=nocloud-net;s=/cdrom/nocloud/" -ForegroundColor Cyan
Write-Host "   CentOS: inst.ks=cdrom:/ks.cfg" -ForegroundColor Cyan
Write-Host "5. Nhấn F10 (Ubuntu) hoặc Enter (CentOS) để boot" -ForegroundColor White
Write-Host "6. Đợi cài đặt tự động (30-60 phút)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
Write-Host "Sau khi cài xong:" -ForegroundColor Cyan
Write-Host "- Kiểm tra log: tail -f /opt/setup/auto-install.log" -ForegroundColor White
Write-Host "- Truy cập Cockpit: https://server_ip:9090" -ForegroundColor White
Write-Host "- Truy cập Webmin: https://server_ip:10000" -ForegroundColor White
Write-Host "- Truy cập Grafana: http://server_ip:3000" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
