# Build Script cho Linux Server Setup
# Sử dụng: .\build.ps1 [options]

param(
    [ValidateSet('deploy', 'web', 'database', 'app', 'monitoring', 'ai', 'security', 'rollback', 'status')]
    [string]$Action = 'deploy',
    
    [string]$InventoryFile = 'inventory.ini',
    
    [string]$ConfigFile = 'project-config.yml',
    
    [switch]$SkipCheck = $false,
    
    [switch]$Verbose = $false
)

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" Green
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" Red
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" Yellow
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" Cyan
}

# Check if Ansible is installed
function Test-Ansible {
    Write-Info "Checking Ansible installation..."
    try {
        $ansibleVersion = ansible --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Ansible is installed"
            if ($Verbose) {
                Write-ColorOutput $ansibleVersion Gray
            }
            return $true
        }
    }
    catch {
        # Ignore
    }
    
    Write-Error "Ansible is not installed"
    Write-Info "Install Ansible with: pip install ansible"
    return $false
}

# Check if inventory file exists
function Test-Inventory {
    Write-Info "Checking inventory file..."
    if (Test-Path $InventoryFile) {
        Write-Success "Inventory file found: $InventoryFile"
        return $true
    }
    else {
        Write-Error "Inventory file not found: $InventoryFile"
        Write-Info "Create inventory file or specify with -InventoryFile"
        return $false
    }
}

# Check if config file exists
function Test-Config {
    Write-Info "Checking config file..."
    if (Test-Path $ConfigFile) {
        Write-Success "Config file found: $ConfigFile"
        return $true
    }
    else {
        Write-Warning "Config file not found: $ConfigFile"
        Write-Info "Continuing without config file..."
        return $true
    }
}

# Run Ansible playbook
function Invoke-Playbook {
    param(
        [string]$Tags,
        [string]$ExtraVars
    )
    
    $ansibleArgs = @(
        'ansible-playbook',
        '-i', $InventoryFile,
        'playbook.yml'
    )
    
    if ($Tags) {
        $ansibleArgs += '--tags', $Tags
    }
    
    if (Test-Path $ConfigFile) {
        $ansibleArgs += '-e', "@$ConfigFile"
    }
    
    if ($ExtraVars) {
        $ansibleArgs += '-e', $ExtraVars
    }
    
    if ($Verbose) {
        $ansibleArgs += '-vv'
    }
    
    Write-Info "Running: $($ansibleArgs -join ' ')"
    Write-ColorOutput "----------------------------------------" Gray
    
    & ansible @ansibleArgs
    
    $exitCode = $LASTEXITCODE
    Write-ColorOutput "----------------------------------------" Gray
    
    if ($exitCode -eq 0) {
        Write-Success "Playbook completed successfully"
    }
    else {
        Write-Error "Playbook failed with exit code: $exitCode"
    }
    
    return $exitCode -eq 0
}

# Main build function
function Build {
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput "  Linux Server Setup - Build Script" Cyan
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput ""
    
    # Pre-flight checks
    if (-not $SkipCheck) {
        if (-not (Test-Ansible)) {
            exit 1
        }
        
        if (-not (Test-Inventory)) {
            exit 1
        }
        
        if (-not (Test-Config)) {
            # Continue anyway
        }
    }
    
    Write-ColorOutput ""
    
    # Execute action
    switch ($Action) {
        'deploy' {
            Write-Info "Deploying full stack..."
            Invoke-Playbook
        }
        'web' {
            Write-Info "Deploying web server only..."
            Invoke-Playbook -Tags 'web'
        }
        'database' {
            Write-Info "Deploying database only..."
            Invoke-Playbook -Tags 'database'
        }
        'app' {
            Write-Info "Deploying application only..."
            Invoke-Playbook -Tags 'deploy,dependencies,application'
        }
        'monitoring' {
            Write-Info "Deploying monitoring tools..."
            Invoke-Playbook -Tags 'cockpit,webmin,monitoring,portainer'
        }
        'ai' {
            Write-Info "Deploying AI/ML tools..."
            Invoke-Playbook -Tags 'ai-ml,ai-chatops,ai-monitoring,ai-healing,ai-assistant'
        }
        'security' {
            Write-Info "Deploying security tools..."
            Invoke-Playbook -Tags 'ai-security,ai-security-response,app-hardening,container-isolation'
        }
        'rollback' {
            Write-Warning "Rollback not implemented yet"
            Write-Info "Use Ansible vault or version control for rollback"
        }
        'status' {
            Write-Info "Checking server status..."
            Invoke-Playbook -Tags 'application-restart' -ExtraVars 'check_status=true'
        }
        default {
            Write-Error "Unknown action: $Action"
            exit 1
        }
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "========================================" Cyan
    Write-ColorOutput "  Build completed" Cyan
    Write-ColorOutput "========================================" Cyan
}

# Show help
function Show-Help {
    Write-ColorOutput "Linux Server Setup - Build Script" Cyan
    Write-ColorOutput ""
    Write-ColorOutput "Usage:" White
    Write-ColorOutput "  .\build.ps1 [options]" White
    Write-ColorOutput ""
    Write-ColorOutput "Options:" White
    Write-ColorOutput "  -Action <action>        Action to perform (default: deploy)" White
    Write-ColorOutput "                         Values: deploy, web, database, app, monitoring, ai, security, rollback, status" White
    Write-ColorOutput "  -InventoryFile <file>   Inventory file (default: inventory.ini)" White
    Write-ColorOutput "  -ConfigFile <file>      Config file (default: project-config.yml)" White
    Write-ColorOutput "  -SkipCheck             Skip pre-flight checks" White
    Write-ColorOutput "  -Verbose               Enable verbose output" White
    Write-ColorOutput ""
    Write-ColorOutput "Examples:" White
    Write-ColorOutput "  .\build.ps1                          # Full deployment" White
    Write-ColorOutput "  .\build.ps1 -Action app              # Deploy application only" White
    Write-ColorOutput "  .\build.ps1 -Action web -Verbose    # Deploy web with verbose output" White
    Write-ColorOutput "  .\build.ps1 -Action monitoring      # Deploy monitoring tools" White
    Write-ColorOutput ""
    Write-ColorOutput "Quick Start:" White
    Write-ColorOutput "  1. Edit inventory.ini with your server IP" White
    Write-ColorOutput "  2. Edit project-config.yml with your project settings" White
    Write-ColorOutput "  3. Run: .\build.ps1" White
    Write-ColorOutput ""
}

# Check for help flag
if ($args -contains '-h' -or $args -contains '--help' -or $args -contains '/?') {
    Show-Help
    exit 0
}

# Run build
Build
