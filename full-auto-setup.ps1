# Full Auto Setup Script - End-to-End Automation
# Từ tạo USB bootable → Cài OS → Cấu hình Server → Deploy Project
# Chạy với PowerShell Administrator

param(
    [Parameter(Mandatory=$true)]
    [string]$USBDrive,
    
    [Parameter(Mandatory=$true)]
    [string]$ISOPath,
    
    [Parameter(Mandatory=$false)]
    [string]$SetupPath = $PSScriptRoot,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('ubuntu', 'centos')]
    [string]$OS = 'ubuntu',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipUSB = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$OnlyDeploy = $false
)

# Colors
function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput "✓ $Message" Green }
function Write-Error { param([string]$Message) Write-ColorOutput "✗ $Message" Red }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠ $Message" Yellow }
function Write-Info { param([string]$Message) Write-ColorOutput "ℹ $Message" Cyan }
function Write-Step { param([string]$Message) Write-ColorOutput "► $Message" Magenta }

# Check Administrator
function Test-Administrator {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Script cần chạy với quyền Administrator"
        Write-Info "Chuột phải vào PowerShell và chọn 'Run as Administrator'"
        return $false
    }
    return $true
}

# Check paths
function Test-Paths {
    if (-not (Test-Path $SetupPath)) {
        Write-Error "Không tìm thấy thư mục setup: $SetupPath"
        return $false
    }
    
    if (-not $SkipUSB -and -not (Test-Path $USBDrive)) {
        Write-Error "Không tìm thấy drive $USBDrive"
        return $false
    }
    
    if (-not $SkipUSB -and -not (Test-Path $ISOPath)) {
        Write-Error "Không tìm thấy file ISO: $ISOPath"
        return $false
    }
    
    return $true
}

# Create USB bootable using PowerShell (no Rufus needed)
function New-USBBootable {
    Write-Step "Tạo USB bootable tự động..."
    
    try {
        $driveLetter = $USBDrive[0]
        
        # Format USB
        Write-Info "Format USB drive..."
        $volume = Get-Volume -DriveLetter $driveLetter -ErrorAction Stop
        Dismount-Volume -DriveLetter $driveLetter -Force
        Format-Volume -DriveLetter $driveLetter -FileSystem FAT32 -Force -ErrorAction Stop
        
        # Mount ISO
        Write-Info "Mount ISO file..."
        $mountResult = Mount-DiskImage -ImagePath $ISOPath -PassThru
        $isoDriveLetter = ($mountResult | Get-Volume).DriveLetter
        
        # Copy ISO contents to USB
        Write-Info "Copy file từ ISO sang USB (có thể mất 10-15 phút)..."
        Robocopy "${isoDriveLetter}:\" "${USBDrive}\" /E /XD /XF /R:0 /W:0
        
        # Dismount ISO
        Dismount-DiskImage -ImagePath $ISOPath
        
        Write-Success "Đã tạo USB bootable thành công"
        return $true
    }
    catch {
        Write-Error "Lỗi khi tạo USB bootable: $_"
        return $false
    }
}

# Copy setup files to USB
function Copy-SetupToUSB {
    Write-Step "Copy thư mục setup vào USB..."
    
    try {
        $usbSetupPath = "$USBDrive\setup"
        if (Test-Path $usbSetupPath) {
            Remove-Item $usbSetupPath -Recurse -Force
        }
        Copy-Item -Recurse -Force $SetupPath $usbSetupPath
        Write-Success "Đã copy thư mục setup vào USB"
        return $true
    }
    catch {
        Write-Error "Lỗi khi copy setup: $_"
        return $false
    }
}

# Create cloud-init configuration
function New-CloudInitConfig {
    Write-Step "Tạo cấu hình cloud-init..."
    
    try {
        $nocloudPath = "$USBDrive\nocloud"
        New-Item -ItemType Directory -Force -Path $nocloudPath | Out-Null
        
        if ($OS -eq 'ubuntu') {
            if (Test-Path "$SetupPath\ubuntu-server-cloud-init.yaml") {
                $cloudInitContent = Get-Content "$SetupPath\ubuntu-server-cloud-init.yaml" -Raw
                
                # Add runcmd to run auto-install
                $runcmd = @"

# Auto-install script
runcmd:
  - mkdir -p /opt/setup
  - cp -r /media/*/setup/* /opt/setup/ 2>/dev/null || cp -r /cdrom/setup/* /opt/setup/ 2>/dev/null || true
  - chmod +x /opt/setup/auto-install.sh
  - bash /opt/setup/auto-install.sh > /opt/setup/auto-install.log 2>&1 &
"@
                
                $cloudInitContent + $runcmd | Out-File "$nocloudPath\user-data" -Encoding ASCII
                "" | Out-File "$nocloudPath\meta-data" -Encoding ASCII
                Write-Success "Đã tạo cloud-init config cho Ubuntu"
            }
            else {
                Write-Warning "Không tìm thấy ubuntu-server-cloud-init.yaml"
            }
        }
        elseif ($OS -eq 'centos') {
            if (Test-Path "$SetupPath\centos-kickstart.cfg") {
                Copy-Item "$SetupPath\centos-kickstart.cfg" "$USBDrive\ks.cfg" -Force
                Write-Success "Đã copy kickstart config cho CentOS"
            }
            else {
                Write-Warning "Không tìm thấy centos-kickstart.cfg"
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Lỗi khi tạo cloud-init: $_"
        return $false
    }
}

# Create auto-install script
function New-AutoInstallScript {
    Write-Step "Tạo script auto-install.sh..."
    
    try {
        $usbSetupPath = "$USBDrive\setup"
        
        $autoInstallScript = @'
#!/bin/bash
set -e

# Full Auto-Install Script
# Chạy sau khi OS cài xong

echo "=========================================="
echo "Full Auto-Install Script"
echo "=========================================="
echo "Bắt đầu cài đặt server và deploy dự án..."
echo "=========================================="

# Log file
LOG_FILE="/opt/setup/auto-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# 1. Update system
echo "[1/8] Cập nhật hệ thống..."
export DEBIAN_FRONTEND=noninteractive
apt update || yum update -y
apt upgrade -y || yum upgrade -y

# 2. Install basic packages
echo "[2/8] Cài đặt packages cơ bản..."
apt install -y curl wget git python3 python3-pip python3-venv || yum install -y curl wget git python3 python3-pip

# 3. Install Ansible
echo "[3/8] Cài đặt Ansible..."
pip3 install ansible --upgrade

# 4. Copy setup to /opt
echo "[4/8] Copy setup files..."
mkdir -p /opt/setup
if [ -d "/media/*/setup" ]; then
    cp -r /media/*/setup/* /opt/setup/
elif [ -d "/cdrom/setup" ]; then
    cp -r /cdrom/setup/* /opt/setup/
fi

# 5. Configure inventory
echo "[5/8] Cấu hình inventory..."
SERVER_IP=$(hostname -I | awk '{print $1}')
cat > /opt/setup/inventory.ini << EOF
[appservers]
localhost ansible_host=$SERVER_IP ansible_connection=local

[dbservers]
localhost ansible_host=$SERVER_IP ansible_connection=local

[allservers]
localhost ansible_host=$SERVER_IP ansible_connection=local

[gpuservers]
localhost ansible_host=$SERVER_IP ansible_connection=local
EOF

# 6. Run server-setup.sh
echo "[6/8] Chạy server-setup.sh..."
cd /opt/setup
if [ -f "server-setup.sh" ]; then
    chmod +x server-setup.sh
    bash server-setup.sh << EOF
y
y
y
EOF
fi

# 7. Run Ansible playbook
echo "[7/8] Chạy Ansible playbook..."
cd /opt/setup
if [ -f "project-config.yml" ]; then
    ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
else
    ansible-playbook -i inventory.ini playbook.yml
fi

# 8. Complete
echo "[8/8] Cài đặt hoàn tất!"
echo "=========================================="
echo "Server đã sẵn sàng!"
echo "=========================================="
echo "Server IP: $SERVER_IP"
echo "Cockpit: https://$SERVER_IP:9090"
echo "Webmin: https://$SERVER_IP:10000"
echo "Grafana: http://$SERVER_IP:3000"
echo "Portainer: https://$SERVER_IP:9443"
echo "=========================================="
echo "Kiểm tra log: tail -f $LOG_FILE"
echo "=========================================="

# Send notification (optional)
if command -v curl &> /dev/null; then
    echo "Gửi thông báo hoàn tất..."
    # Add webhook notification here if needed
fi
'@
        
        $autoInstallScript | Out-File "$usbSetupPath\auto-install.sh" -Encoding ASCII
        Write-Success "Đã tạo auto-install.sh"
        return $true
    }
    catch {
        Write-Error "Lỗi khi tạo auto-install.sh: $_"
        return $false
    }
}

# Deploy to existing server (skip USB creation)
function Invoke-DeployToServer {
    Write-Step "Deploy trực tiếp đến server..."
    
    # Use existing build.ps1
    $buildScript = "$SetupPath\build.ps1"
    if (Test-Path $buildScript) {
        & powershell -ExecutionPolicy Bypass -File $buildScript -Action deploy
        return $LASTEXITCODE -eq 0
    }
    else {
        Write-Error "Không tìm thấy build.ps1"
        return $false
    }
}

# Main function
function Start-FullAutoSetup {
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput "  Full Auto Setup - End-to-End" Cyan
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput ""
    
    # Pre-flight checks
    if (-not (Test-Administrator)) {
        exit 1
    }
    
    if (-not (Test-Paths)) {
        exit 1
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "Configuration:" Cyan
    Write-ColorOutput "  USB Drive: $USBDrive" White
    Write-ColorOutput "  ISO Path: $ISOPath" White
    Write-ColorOutput "  Setup Path: $SetupPath" White
    Write-ColorOutput "  OS: $OS" White
    Write-ColorOutput ""
    
    # Confirm
    if (-not $SkipUSB -and -not $OnlyDeploy) {
        Write-Warning "USB sẽ được format và tất cả dữ liệu sẽ bị mất"
        $confirm = Read-Host "Tiếp tục? (y/n)"
        if ($confirm -ne "y") {
            Write-Info "Đã hủy"
            exit 0
        }
    }
    
    Write-ColorOutput ""
    
    # Execute based on mode
    if ($OnlyDeploy) {
        # Deploy to existing server only
        if (Invoke-DeployToServer) {
            Write-Success "Deploy hoàn tất"
        }
        else {
            Write-Error "Deploy thất bại"
            exit 1
        }
    }
    elseif ($SkipUSB) {
        # Skip USB, just prepare files
        Write-Info "Bỏ qua tạo USB, chỉ chuẩn bị files..."
        # Add logic to prepare files without USB
    }
    else {
        # Full USB creation
        Write-Step "Bắt đầu quy trình tạo USB bootable..."
        
        # 1. Create USB bootable
        if (-not (New-USBBootable)) {
            exit 1
        }
        
        # 2. Copy setup files
        if (-not (Copy-SetupToUSB)) {
            exit 1
        }
        
        # 3. Create cloud-init config
        if (-not (New-CloudInitConfig)) {
            exit 1
        }
        
        # 4. Create auto-install script
        if (-not (New-AutoInstallScript)) {
            exit 1
        }
        
        Write-ColorOutput ""
        Write-ColorOutput "========================================" Green
        Write-ColorOutput "  USB đã sẵn sàng!" Green
        Write-ColorOutput "========================================" Green
        Write-ColorOutput ""
        Write-ColorOutput "Các bước tiếp theo:" Cyan
        Write-ColorOutput "1. Cắm USB vào server" White
        Write-ColorOutput "2. Boot từ USB trong BIOS/UEFI" White
        Write-ColorOutput "3. Đợi cài đặt tự động hoàn tất (30-60 phút)" White
        Write-ColorOutput ""
        Write-ColorOutput "Sau khi cài xong:" Cyan
        Write-ColorOutput "- Kiểm tra log: tail -f /opt/setup/auto-install.log" White
        Write-ColorOutput "- Truy cập Cockpit: https://server_ip:9090" White
        Write-ColorOutput "- Truy cập Webmin: https://server_ip:10000" White
        Write-ColorOutput "- Truy cập Grafana: http://server_ip:3000" White
        Write-ColorOutput ""
    }
    
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput "  Hoàn tất!" Cyan
    Write-ColorOutput "========================================" Cyan
}

# Show help
function Show-Help {
    Write-ColorOutput "Full Auto Setup - End-to-End Automation" Cyan
    Write-ColorOutput ""
    Write-ColorOutput "Usage:" White
    Write-ColorOutput "  .\full-auto-setup.ps1 -USBDrive <drive> -ISOPath <iso> [options]" White
    Write-ColorOutput ""
    Write-ColorOutput "Parameters:" White
    Write-ColorOutput "  -USBDrive <drive>       USB drive letter (e.g., E:)" White
    Write-ColorOutput "  -ISOPath <path>         Path to ISO file" White
    Write-ColorOutput "  -SetupPath <path>       Setup directory (default: current)" White
    Write-ColorOutput "  -OS <os>                OS type: ubuntu or centos (default: ubuntu)" White
    Write-ColorOutput "  -SkipUSB               Skip USB creation, prepare files only" White
    Write-ColorOutput "  -OnlyDeploy            Deploy to existing server only" White
    Write-ColorOutput ""
    Write-ColorOutput "Examples:" White
    Write-ColorOutput "  # Full USB creation for Ubuntu" White
    Write-ColorOutput "  .\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\ubuntu-22.04.iso" White
    Write-ColorOutput ""
    Write-ColorOutput "  # Full USB creation for CentOS" White
    Write-ColorOutput "  .\full-auto-setup.ps1 -USBDrive E: -ISOPath C:\Downloads\centos-8.iso -OS centos" White
    Write-ColorOutput ""
    Write-ColorOutput "  # Deploy to existing server (no USB)" White
    Write-ColorOutput "  .\full-auto-setup.ps1 -OnlyDeploy" White
    Write-ColorOutput ""
    Write-ColorOutput "Workflow:" White
    Write-ColorOutput "  1. Tạo USB bootable (tự động, không cần Rufus)" White
    Write-ColorOutput "  2. Copy file cấu hình cloud-init/kickstart" White
    Write-ColorOutput "  3. Copy toàn bộ setup vào USB" White
    Write-ColorOutput "  4. Tạo auto-install.sh" White
    Write-ColorOutput "  5. Boot từ USB trên server" White
    Write-ColorOutput "  6. OS cài tự động (10-20 phút)" White
    Write-ColorOutput "  7. auto-install.sh chạy sau boot (20-40 phút)" White
    Write-ColorOutput "  8. Server và project sẵn sàng!" White
    Write-ColorOutput ""
}

# Check for help
if ($args -contains '-h' -or $args -contains '--help' -or $args -contains '/?') {
    Show-Help
    exit 0
}

# Run
Start-FullAutoSetup
