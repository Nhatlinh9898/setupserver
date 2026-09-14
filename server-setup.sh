#!/bin/bash
# Server Setup Script — cấu hình base Ubuntu/Debian và RHEL-family
# Sử dụng: sudo bash server-setup.sh
# Biến môi trường tùy chọn:
#   SETUP_INSTALL_DOCKER=y|n
#   SETUP_INSTALL_NGINX=y|n
#   SETUP_NONINTERACTIVE=1  (bỏ qua prompt, dùng biến ở trên, mặc định n)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        print_error "Script này cần chạy với quyền root (sudo)"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Không thể phát hiện hệ điều hành"
        exit 1
    fi
    print_info "Phát hiện OS: $OS $OS_VERSION"
}

pkg_update() {
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y
    elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "almalinux" || "$OS" == "fedora" ]]; then
        if command -v dnf >/dev/null 2>&1; then
            dnf -y update
        else
            yum update -y
        fi
    else
        print_error "OS không được hỗ trợ: $OS"
        exit 1
    fi
}

install_basic_packages() {
    print_info "Đang cài đặt các package cơ bản..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        DEBIAN_FRONTEND=noninteractive apt install -y vim curl wget git htop net-tools ufw fail2ban unzip \
            software-properties-common apt-transport-https ca-certificates \
            gnupg lsb-release python3 python3-pip python3-venv
    else
        if command -v dnf >/dev/null 2>&1; then
            dnf -y install vim curl wget git htop net-tools firewalld fail2ban unzip \
                epel-release python3 python3-pip || dnf -y install vim curl wget git htop net-tools firewalld unzip python3 python3-pip
        else
            yum install -y vim curl wget git htop net-tools firewalld fail2ban unzip \
                epel-release python3 python3-pip
        fi
    fi
}

configure_firewall() {
    print_info "Đang cấu hình firewall..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow OpenSSH || ufw allow ssh
        ufw allow http
        ufw allow https
        ufw --force enable
    else
        systemctl enable --now firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
}

configure_ssh() {
    print_info "Đang cấu hình SSH (tắt root login; giữ password auth)..."
    SSH_CONFIG="/etc/ssh/sshd_config"
    cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%s)"
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    # Không tắt PasswordAuthentication ở đây — tránh khóa máy khi chưa có SSH key
    systemctl restart sshd 2>/dev/null || systemctl restart ssh
}

configure_swap() {
    print_info "Đang cấu hình Swap..."
    SWAP_FILE="/swapfile"
    SWAP_SIZE="4G"
    if [ ! -f "$SWAP_FILE" ]; then
        fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=4096
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE"
        swapon "$SWAP_FILE"
        grep -q "$SWAP_FILE" /etc/fstab || echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
        print_info "Đã tạo swap file $SWAP_SIZE"
    else
        print_warning "Swap file đã tồn tại"
    fi
}

optimize_system() {
    print_info "Đang tối ưu hóa hệ thống..."
    cat > /etc/sysctl.d/99-server-setup.conf << 'EOFSYS'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 8192
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOFSYS
    sysctl --system || sysctl -p || true

    if ! grep -q 'soft nofile 65536' /etc/security/limits.conf; then
        cat >> /etc/security/limits.conf << 'EOFLIM'

* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOFLIM
    fi
}

install_docker() {
    print_info "Đang cài đặt Docker..."
    if command -v docker &>/dev/null; then
        print_warning "Docker đã được cài đặt"
        return
    fi
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
          > /etc/apt/sources.list.d/docker.list
        apt update
        DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        if command -v dnf >/dev/null 2>&1; then
            dnf -y install yum-utils || true
            dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
        else
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        fi
    fi
    systemctl enable --now docker
    if [ -n "${SUDO_USER:-}" ]; then
        usermod -aG docker "$SUDO_USER"
    fi
    print_info "Docker đã được cài đặt thành công"
}

install_nginx() {
    print_info "Đang cài đặt Nginx..."
    if command -v nginx &>/dev/null; then
        print_warning "Nginx đã được cài đặt"
        return
    fi
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        DEBIAN_FRONTEND=noninteractive apt install -y nginx
    else
        if command -v dnf >/dev/null 2>&1; then
            dnf -y install nginx
        else
            yum install -y nginx
        fi
    fi
    systemctl enable --now nginx
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head><title>Server Setup Complete</title></head>
<body>
  <h1>Server Setup Complete!</h1>
  <p>OS: $OS $OS_VERSION</p>
  <p>Hostname: $(hostname)</p>
  <p>IP: $(hostname -I 2>/dev/null | awk '{print $1}')</p>
  <p>Time: $(date)</p>
</body>
</html>
EOF
    print_info "Nginx đã được cài đặt thành công"
}

ask_yes() {
    local prompt="$1"
    local env_val="${2:-}"
    if [[ "${SETUP_NONINTERACTIVE:-0}" == "1" ]]; then
        [[ "${env_val}" == "y" || "${env_val}" == "Y" ]]
        return
    fi
    local ans
    read -r -p "$prompt (y/n): " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

main() {
    print_info "Bắt đầu cấu hình server (CORE base)..."
    check_root
    detect_os
    print_info "Đang cập nhật hệ thống..."
    pkg_update
    install_basic_packages
    configure_firewall
    configure_ssh
    configure_swap
    optimize_system
    systemctl enable --now fail2ban 2>/dev/null || true

    if ask_yes "Bạn có muốn cài đặt Docker không?" "${SETUP_INSTALL_DOCKER:-n}"; then
        install_docker
    fi
    if ask_yes "Bạn có muốn cài đặt Nginx không?" "${SETUP_INSTALL_NGINX:-n}"; then
        install_nginx
    fi

    print_info "Cấu hình server hoàn tất!"
    print_info "Nên reboot để áp dụng limits/sysctl."
    print_warning "Cấu hình SSH key trước khi tắt PasswordAuthentication!"
}

main
