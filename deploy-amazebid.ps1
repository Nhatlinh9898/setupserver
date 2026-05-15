# AmazeBid Deployment Script
# Script này giúp deploy và rollback ứng dụng AmazeBid

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("deploy", "rollback", "backup", "status")]
    [string]$Action = "deploy",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$INVENTORY_FILE = "inventory.ini"
$PLAYBOOK_FILE = "playbook.yml"
$CONFIG_FILE = "project-config.yml"
$APP_CODE_DIR = "app-code"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Error-Output {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Write-Warning-Output {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Cyan"
}

# Check if Ansible is installed
function Test-AnsibleInstalled {
    try {
        $version = ansible --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

# Check if required files exist
function Test-RequiredFiles {
    $files = @(
        $INVENTORY_FILE,
        $PLAYBOOK_FILE,
        $CONFIG_FILE
    )
    
    foreach ($file in $files) {
        if (-not (Test-Path $file)) {
            Write-Error-Output "File không tồn tại: $file"
            return $false
        }
    }
    return $true
}

# Deploy function
function Deploy-Amazebid {
    Write-Info "Bắt đầu deploy AmazeBid..."
    
    # Check if app-code directory exists
    if (Test-Path $APP_CODE_DIR) {
        Write-Info "Đang push code lên GitHub..."
        
        Push-Location $APP_CODE_DIR
        try {
            git add -A
            $commitMessage = "Update $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            git commit -m $commitMessage
            git push origin main
            Write-Success "Đã push code lên GitHub"
        }
        catch {
            Write-Warning-Output "Không thể push code: $_"
            Write-Info "Tiếp tục deploy với code hiện tại trên GitHub..."
        }
        finally {
            Pop-Location
        }
    }
    
    # Run Ansible playbook
    Write-Info "Đang chạy Ansible playbook..."
    $command = "ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE -e @$CONFIG_FILE"
    
    try {
        Invoke-Expression $command
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deploy thành công!"
            Write-Info "Ứng dụng đang chạy tại: http://your-server-ip:3000"
        }
        else {
            Write-Error-Output "Deploy thất bại với exit code: $LASTEXITCODE"
            exit 1
        }
    }
    catch {
        Write-Error-Output "Lỗi khi chạy Ansible: $_"
        exit 1
    }
}

# Rollback function
function Rollback-Amazebid {
    param([string]$TargetVersion)
    
    Write-Info "Bắt đầu rollback AmazeBid..."
    
    if ([string]::IsNullOrEmpty($TargetVersion)) {
        Write-Info "Không có version cụ thể, rollback về version trước đó..."
        
        # Get previous commit
        Push-Location $APP_CODE_DIR
        try {
            $previousCommit = git log --format="%H" -n 2 | Select-Object -Skip 1
            if ([string]::IsNullOrEmpty($previousCommit)) {
                Write-Error-Output "Không tìm thấy version trước đó"
                exit 1
            }
            $TargetVersion = $previousCommit.Trim()
            Write-Info "Rollback về commit: $TargetVersion"
        }
        finally {
            Pop-Location
        }
    }
    
    # Checkout to target version
    Push-Location $APP_CODE_DIR
    try {
        git checkout $TargetVersion
        git push origin main --force
        Write-Success "Đã rollback và push lên GitHub"
    }
    catch {
        Write-Error-Output "Lỗi khi rollback: $_"
        exit 1
    }
    finally {
        Pop-Location
    }
    
    # Redeploy
    Write-Info "Đang redeploy sau rollback..."
    $command = "ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE -e @$CONFIG_FILE"
    
    try {
        Invoke-Expression $command
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Rollback thành công!"
        }
        else {
            Write-Error-Output "Redeploy sau rollback thất bại"
            exit 1
        }
    }
    catch {
        Write-Error-Output "Lỗi khi redeploy: $_"
        exit 1
    }
}

# Backup function
function Backup-Amazebid {
    Write-Info "Đang backup AmazeBid..."
    
    # Backup database
    Write-Info "Backup database..."
    $command = "ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE --tags database-backup -e @$CONFIG_FILE"
    Invoke-Expression $command
    
    # Backup code
    Write-Info "Backup code..."
    $backupDir = "backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item -Path "$APP_CODE_DIR\*" -Destination $backupDir -Recurse -Force
    
    Write-Success "Backup hoàn tất tại: $backupDir"
}

# Status function
function Get-AmazebidStatus {
    Write-Info "Kiểm tra trạng thái AmazeBid..."
    
    # Check Git status
    Push-Location $APP_CODE_DIR
    try {
        Write-Info "=== Git Status ==="
        git status
        Write-Info ""
        Write-Info "=== Recent Commits ==="
        git log --oneline -n 5
    }
    finally {
        Pop-Location
    }
    
    # Check server status
    Write-Info ""
    Write-Info "=== Server Status ==="
    $command = "ansible -i $INVENTORY_FILE webservers -m shell -a 'systemctl status amazebid' -e @$CONFIG_FILE"
    Invoke-Expression $command
}

# Main script
Write-ColorOutput "========================================" "Magenta"
Write-ColorOutput "  AmazeBid Deployment Script" "Magenta"
Write-ColorOutput "========================================" "Magenta"
Write-Host ""

# Check prerequisites
if (-not (Test-AnsibleInstalled)) {
    Write-Error-Output "Ansible chưa được cài đặt"
    Write-Info "Cài đặt Ansible: pip install ansible"
    exit 1
}

if (-not (Test-RequiredFiles)) {
    Write-Error-Output "Thiếu file cấu hình cần thiết"
    exit 1
}

# Execute action
switch ($Action) {
    "deploy" {
        Deploy-Amazebid
    }
    "rollback" {
        Rollback-Amazebid -TargetVersion $Version
    }
    "backup" {
        Backup-Amazebid
    }
    "status" {
        Get-AmazebidStatus
    }
    default {
        Write-Error-Output "Action không hợp lệ: $Action"
        exit 1
    }
}

Write-Host ""
Write-Success "Hoàn tất!"
