#!/bin/bash
# Server Setup Script
# Script này cài đặt và cấu hình server cơ bản cho Ubuntu/Debian và CentOS/RHEL
# Sử dụng: sudo bash server-setup.sh

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hàm in thông báo
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script này cần chạy với quyền root (sudo)"
        exit 1
    fi
}

# Phát hiện OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Không thể phát hiện hệ điều hành"
        exit 1
    fi

    print_info "Phát hiện OS: $OS $OS_VERSION"
}

# Cập nhật hệ thống
update_system() {
    print_info "Đang cập nhật hệ thống..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt update && apt upgrade -y
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        yum update -y
    else
        print_error "OS không được hỗ trợ: $OS"
        exit 1
    fi
}

# Cài đặt các package cơ bản
install_basic_packages() {
    print_info "Đang cài đặt các package cơ bản..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt install -y vim curl wget git htop net-tools ufw fail2ban unzip \
            software-properties-common apt-transport-https ca-certificates \
            gnupg lsb-release python3 python3-pip python3-venv
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        yum install -y vim curl wget git htop net-tools firewalld fail2ban unzip \
            epel-release python3 python3-pip
    fi
}

# Cấu hình Firewall
configure_firewall() {
    print_info "Đang cấu hình firewall..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Cấu hình UFW
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow http
        ufw allow https
        ufw --force enable
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        # Cấu hình firewalld
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
}

# Cấu hình SSH
configure_ssh() {
    print_info "Đang cấu hình SSH..."
    
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    # Backup file cấu hình
    cp $SSH_CONFIG ${SSH_CONFIG}.backup
    
    # Tắt root login
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' $SSH_CONFIG
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' $SSH_CONFIG
    
    # Tắt password authentication (nếu bạn muốn chỉ dùng SSH key)
    # sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
    # sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG
    
    # Restart SSH service
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        systemctl restart sshd
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        systemctl restart sshd
    fi
}

# Cấu hình Swap
configure_swap() {
    print_info "Đang cấu hình Swap..."
    
    SWAP_FILE="/swapfile"
    SWAP_SIZE="4G"
    
    if [ ! -f "$SWAP_FILE" ]; then
        fallocate -l $SWAP_SIZE $SWAP_FILE
        chmod 600 $SWAP_FILE
        mkswap $SWAP_FILE
        swapon $SWAP_FILE
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
        print_info "Đã tạo swap file $SWAP_SIZE"
    else
        print_warning "Swap file đã tồn tại"
    fi
}

# Tối ưu hóa hệ thống
optimize_system() {
    print_info "Đang tối ưu hóa hệ thống..."
    
    # Tối ưu hóa sysctl
    cat >> /etc/sysctl.conf << EOF

# Network optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

    sysctl -p
    
    # Tăng giới hạn file descriptor
    cat >> /etc/security/limits.conf << EOF

* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
}

# Cài đặt Docker
install_docker() {
    print_info "Đang cài đặt Docker..."
    
    if command -v docker &> /dev/null; then
        print_warning "Docker đã được cài đặt"
        return
    fi
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Thêm Docker repository
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    # Enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Thêm user hiện tại vào docker group
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
    fi
    
    print_info "Docker đã được cài đặt thành công"
}

# Cài đặt Nginx
install_nginx() {
    print_info "Đang cài đặt Nginx..."
    
    if command -v nginx &> /dev/null; then
        print_warning "Nginx đã được cài đặt"
        return
    fi
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt install -y nginx
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        yum install -y nginx
    fi
    
    # Enable Nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Tạo file index.html mẫu
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Server Setup Complete</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .info { background: #f4f4f4; padding: 20px; border-radius: 5px; margin: 20px auto; max-width: 600px; }
    </style>
</head>
<body>
    <h1>Server Setup Complete!</h1>
    <div class="info">
        <p><strong>OS:</strong> $OS $OS_VERSION</p>
        <p><strong>Hostname:</strong> $(hostname)</p>
        <p><strong>IP Address:</strong> $(hostname -I | awk '{print $1}')</p>
        <p><strong>Setup Time:</strong> $(date)</p>
    </div>
</body>
</html>
EOF
    
    print_info "Nginx đã được cài đặt thành công"
}

# Main function
main() {
    print_info "Bắt đầu cấu hình server..."
    
    check_root
    detect_os
    update_system
    install_basic_packages
    configure_firewall
    configure_ssh
    configure_swap
    optimize_system
    
    # Hỏi người dùng về các tùy chọn
    read -p "Bạn có muốn cài đặt Docker không? (y/n): " install_docker_choice
    if [[ "$install_docker_choice" == "y" ]] || [[ "$install_docker_choice" == "Y" ]]; then
        install_docker
    fi
    
    read -p "Bạn có muốn cài đặt Nginx không? (y/n): " install_nginx_choice
    if [[ "$install_nginx_choice" == "y" ]] || [[ "$install_nginx_choice" == "Y" ]]; then
        install_nginx
    fi
    
    print_info "Cấu hình server hoàn tất!"
    print_info "Bạn nên reboot server để áp dụng tất cả thay đổi."
    print_warning "Đừng quên cấu hình SSH key trước khi tắt password authentication!"
}

# Chạy main
main
