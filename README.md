# Linux Server Setup Configuration

Repository này chứa các file cấu hình để cài đặt tự động Linux Server (Ubuntu Server hoặc CentOS) cho mục đích Web Server, Database Server, và Application Server.

## 📋 Nội dung

**Cài đặt OS:**
- `ubuntu-server-cloud-init.yaml` - File cấu hình cài đặt tự động Ubuntu Server
- `centos-kickstart.cfg` - File cấu hình cài đặt tự động CentOS/RHEL

**Cấu hình Server:**
- `server-setup.sh` - Shell script cấu hình server cơ bản
- `ansible.cfg` - Cấu hình Ansible
- `inventory.ini` - Inventory file cho Ansible
- `playbook.yml` - Main Ansible playbook

**Ansible Roles:**
- `roles/web/` - Cài đặt Nginx/Apache
- `roles/database/` - Cài đặt MySQL/PostgreSQL
- `roles/app/` - Cài đặt Docker, Node.js, Python
- `roles/deploy/` - Clone code từ Git repository
- `roles/deploy-local/` - Copy code từ local directory
- `roles/dependencies/` - Cài đặt dependencies (npm, pip, composer, v.v.)
- `roles/application/` - Cấu hình và chạy ứng dụng
- `roles/cockpit/` - Cài đặt Cockpit web interface
- `roles/webmin/` - Cài đặt Webmin web interface
- `roles/monitoring/` - Cài đặt Grafana + Prometheus
- `roles/portainer/` - Cài đặt Portainer Docker management
- `roles/ai-ml/` - Cài đặt Ollama và AI/ML tools
- `roles/cuda/` - Cài đặt NVIDIA CUDA cho GPU support
- `roles/ai-chatops/` - Chat với AI để quản lý server
- `roles/ai-monitoring/` - AI phân tích logs và metrics tự động
- `roles/ai-healing/` - Auto-healing với AI
- `roles/ai-assistant/` - AI assistant với RAG
- `roles/ai-security/` - **Security policy enforcement cho AI**
- `roles/ai-security-response/` - **AI Security Response - NHIỆM VỤ CHÍNH: Phát hiện và phản hồi tấn công mạng**
- `roles/app-hardening/` - **App Hardening - LỚP 2: Rào chắn bảo vệ code/app**
- `roles/container-isolation/` - **Container Isolation - LỚP 2B: Container Sandbox**

**Cấu hình Project:**
- `project-config.yml` - File cấu hình dự án của bạn
- `vars.yml` - Variables tùy chỉnh chung

## 🚀 Hướng dẫn sử dụng

### Phương án 1: Clean Install (Cài đè Windows)

#### Bước 1: Tạo USB Bootable

**Đối với Ubuntu Server:**

1. Tải Ubuntu Server ISO từ: https://ubuntu.com/download/server
2. Sử dụng Rufus (Windows) hoặc Etcher (cross-platform) để tạo USB bootable
3. Copy file `ubuntu-server-cloud-init.yaml` vào USB với tên `user-data` trong thư mục `nocloud/`

**Đối với CentOS:**

1. Tải CentOS ISO từ: https://www.centos.org/download/
2. Sử dụng Rufus hoặc Etcher để tạo USB bootable
3. Copy file `centos-kickstart.cfg` vào USB với tên `ks.cfg`

#### Bước 2: Cài đặt từ USB

**Ubuntu Server:**

1. Boot từ USB
2. Khi màn hình cài đặt hiện ra, nhấn `e` để edit boot parameters
3. Thêm `cloud-init=nocloud-net;s=http://192.168.1.100:8000/` (hoặc sử dụng USB)
4. Nhấn `F10` để boot

**CentOS:**

1. Boot từ USB
2. Khi màn hình boot hiện ra, nhấn `Tab` để edit
3. Thêm `inst.ks=cdrom:/ks.cfg` vào cuối dòng
4. Nhấn Enter

#### Bước 3: Cấu hình sau khi cài đặt

Sau khi cài đặt xong, bạn có thể sử dụng một trong các phương pháp sau:

### Phương án 2: Sử dụng Shell Script

Sau khi cài đặt Linux, chạy script này để cấu hình server:

```bash
# Download script
wget https://raw.githubusercontent.com/yourusername/setup/main/server-setup.sh

# Chạy script với quyền root
sudo bash server-setup.sh
```

Script sẽ:
- Cập nhật hệ thống
- Cài đặt các package cơ bản
- Cấu hình firewall
- Cấu hình SSH
- Tạo swap
- Tối ưu hóa hệ thống
- (Tùy chọn) Cài đặt Docker
- (Tùy chọn) Cài đặt Nginx

### Phương án 3: Sử dụng Ansible

Nếu bạn muốn quản lý nhiều server, sử dụng Ansible:

#### Cài đặt Ansible trên máy local (Windows với WSL hoặc Linux/Mac):

```bash
pip install ansible
```

#### Cấu hình Inventory

Edit file `inventory.ini` và thay IP address của server:

```ini
[webservers]
server-01 ansible_host=192.168.1.100 ansible_user=admin
```

#### Chạy Playbook

```bash
# Chạy tất cả roles
ansible-playbook -i inventory.ini playbook.yml

# Chạy chỉ web server role
ansible-playbook -i inventory.ini playbook.yml --tags web

# Chạy chỉ database role
ansible-playbook -i inventory.ini playbook.yml --tags database
```

#### Tùy chọn Playbook

Bạn có thể tùy chọn cài đặt các service bằng cách thêm variables:

```bash
# Cài đặt cả MySQL và PostgreSQL
ansible-playbook -i inventory.ini playbook.yml -e "install_mysql=true install_postgresql=true"

# Chỉ cài đặt Apache thay vì Nginx
ansible-playbook -i inventory.ini playbook.yml -e "install_apache=true"

# Cài đặt Node.js
ansible-playbook -i inventory.ini playbook.yml -e "install_nodejs=true"
```

### Phương án 4: Deploy Ứng Dụng Tự Động

Ansible playbook hiện tại đã bao gồm các role để deploy ứng dụng tự động. Có 2 phương pháp deploy:

#### Phương pháp A: Deploy từ Git Repository (Khuyến khích)

Đây là phương pháp tốt nhất cho production và CI/CD.

**Bước 1: Đưa code lên Git repository**

```bash
# Trong thư mục project của bạn
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/your-repo.git
git push -u origin main
```

**Bước 2: Cấu hình Project**

Edit file `project-config.yml` để cấu hình dự án của bạn:

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

#### Bước 3: Chạy Playbook với Project Config

```bash
# Chạy playbook với file cấu hình project
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml

# Hoặc chạy chỉ các role deploy
ansible-playbook -i inventory.ini playbook.yml --tags deploy,dependencies,application -e @project-config.yml
```

#### Phương pháp B: Deploy từ Local Directory

Phù hợp cho development hoặc khi không muốn dùng Git.

**Bước 1: Đặt code trong thư mục setup**

Tạo thư mục `app-code` trong thư mục setup và đặt code của bạn vào đó:

```
setup/
├── app-code/          # Đặt code của bạn ở đây
│   ├── package.json   # (nếu Node.js)
│   ├── requirements.txt  # (nếu Python)
│   ├── composer.json  # (nếu PHP)
│   ├── app.py
│   └── ...
├── roles/
├── playbook.yml
└── ...
```

**Bước 2: Cấu hình trong project-config.yml**

```yaml
deploy_method: "local"  # Đổi thành "local"
local_code_path: "./app-code"  # Đường dẫn đến code

# Thông tin Project
app_name: "my-app"
app_user: "admin"
project_path: "/opt/apps/my-app"
app_port: 3000
```

**Bước 3: Chạy Playbook**

```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

Ansible sẽ tự động copy code từ thư mục `app-code` sang server.

#### Các Loại Ứng Dụng Hỗ Trợ

**Node.js Application:**
- Tự động detect `package.json`
- Cài đặt dependencies với `npm install` hoặc `npm ci`
- Chạy `npm run build` (nếu có)
- Quản lý với PM2
- Cấu hình trong `project-config.yml`:
  ```yaml
  node_script: "app.js"
  node_instances: 2
  use_pm2: true
  ```

**Python Application:**
- Tự động detect `requirements.txt` hoặc `pyproject.toml`
- Tạo virtual environment
- Cài đặt dependencies với pip
- Quản lý với Supervisor
- Hỗ trợ Django (tự động chạy migrations, collectstatic)
- Hỗ trợ Flask

**PHP Application:**
- Tự động detect `composer.json` hoặc `index.php`
- Cài đặt Composer nếu cần
- Cài đặt dependencies
- Cấu hình Nginx cho PHP
- Hỗ trợ Laravel, WordPress, v.v.

**Ruby/Rails Application:**
- Tự động detect `Gemfile`
- Cài đặt Bundler và gems
- Chạy Rails migrations
- Precompile assets
- Quản lý với Puma + Supervisor

**Go Application:**
- Tự động detect `main.go`
- Build application
- Tạo systemd service
- Tự động start

**Docker Application:**
- Tự động detect `Dockerfile` hoặc `docker-compose.yml`
- Build Docker image
- Start với Docker Compose

#### Deploy với Git Private Repository

Nếu repository của bạn là private, bạn có thể sử dụng SSH key:

```yaml
# Trong project-config.yml
git_repository: "git@github.com:yourusername/your-repo.git"
git_ssh_private_key: "-----BEGIN OPENSSH PRIVATE KEY-----..."
```

Hoặc sử dụng username/password (không khuyến khích):

```yaml
git_repository: "https://github.com/yourusername/your-repo.git"
git_password: "your_password"
```

#### Custom Install Script

Nếu dự án của bạn có script cài đặt riêng, đặt tên là `install.sh` hoặc `setup.sh` trong root directory của project. Ansible sẽ tự động chạy nó.

#### Health Check

Sau khi deploy, Ansible sẽ tự động kiểm tra health của ứng dụng:

```yaml
# Trong project-config.yml
health_check_enabled: true
health_check_path: "/health"
health_check_status: 200
app_port: 3000
```

#### Ví dụ Deploy Node.js App

```bash
# 1. Cấu hình project-config.yml cho Node.js app
git_repository: "https://github.com/yourusername/nodejs-app.git"
app_name: "nodejs-app"
app_port: 3000
node_script: "server.js"
use_pm2: true

# 2. Chạy playbook
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

#### Ví dụ Deploy Django App

```bash
# 1. Cấu hình project-config.yml cho Django app
git_repository: "https://github.com/yourusername/django-app.git"
app_name: "django-app"
app_port: 8000
django_settings_module: "myproject.settings"
install_postgresql: true

# 2. Chạy playbook
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

#### Ví dụ Deploy Laravel App

```bash
# 1. Cấu hình project-config.yml cho Laravel app
git_repository: "https://github.com/yourusername/laravel-app.git"
app_name: "laravel-app"
domain_name: "example.com"
php_version: "8.1"
install_mysql: true

# 2. Chạy playbook
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

### Phương án 5: Quản lý Server Từ Xa

Sau khi cài đặt hoàn tất, bạn có thể quản lý server từ bất kỳ thiết bị nào thông qua các công cụ web:

#### Cockpit - Web Interface Quản Lý Server

**Truy cập Cockpit:**
- URL: `https://server_ip:9090`
- Login: User admin hoặc user được tạo trong `project-config.yml`
- Password: Password của user

**Tính năng Cockpit:**
- Dashboard monitoring (CPU, RAM, Disk, Network)
- Quản lý services (start, stop, restart)
- Quản lý users và groups
- Quản lý storage và filesystems
- Terminal trên web
- Quản lý containers (Podman/Docker)
- Quản lý network
- Xem logs

**Cấu hình trong `project-config.yml`:**
```yaml
cockpit_allow_remote: false
cockpit_ssl_enabled: true
cockpit_create_user: false
cockpit_user: "cockpitadmin"
cockpit_password: "$6$rounds=4096$xyz$change_this_password"
```

#### Webmin - Web Interface Quản Lý Hệ Thống

**Truy cập Webmin:**
- URL: `https://server_ip:10000`
- Login: User có quyền sudo (thường là admin hoặc root)
- Password: Password của user

**Tính năng Webmin:**
- Quản lý Apache/Nginx
- Quản lý MySQL/PostgreSQL
- Quản lý BIND DNS
- Quản lý Firewall
- Quản lý Filesystem
- Quản lý Users và Groups
- Quản lý Cron jobs
- Quản lý Logs
- Quản lý System processes

**Cấu hình trong `project-config.yml`:**
```yaml
webmin_install_modules: false  # Cài thêm các modules
```

#### Grafana + Prometheus - Monitoring và Alerting

**Truy cập Grafana:**
- URL: `http://server_ip:3000`
- Login: admin
- Password: Đổi trong `project-config.yml`

**Truy cập Prometheus:**
- URL: `http://server_ip:9090`
- Không cần login (mặc định)

**Tính năng:**
- Real-time monitoring (CPU, RAM, Disk, Network)
- Custom dashboards
- Alerts và notifications
- Data visualization
- Export metrics
- Integration với nhiều data sources

**Cấu hình trong `project-config.yml`:**
```yaml
prometheus_version: "2.45.0"
node_exporter_version: "1.6.0"
grafana_version: "10.0.0"
grafana_admin_password: "admin"  # ĐỔI PASSWORD NÀY!
grafana_domain: "localhost"
grafana_config_datasource: true  # Tự động cấu hình Prometheus
```

**Tạo Dashboard trong Grafana:**
1. Login vào Grafana
2. Vào Configuration → Data Sources
3. Prometheus đã được cấu hình tự động
4. Vào Create → Dashboard để tạo dashboard mới
5. Import dashboard từ Grafana.com nếu cần

#### Portainer - Docker Management Web Interface

**Truy cập Portainer:**
- URL: `https://server_ip:9443`
- Login: Đặt password khi truy cập lần đầu
- Password: Tạo mới khi truy cập đầu tiên

**Tính năng Portainer:**
- Quản lý Docker containers
- Quản lý Docker images
- Quản lý Docker volumes
- Quản lý Docker networks
- Docker Compose management
- Container logs
- Container stats
- Deploy stacks
- User management

**Cấu hình trong `project-config.yml`:**
```yaml
portainer_version: "latest"
portainer_http_enabled: false  # Bật HTTP (không khuyến khích)
```

#### Chỉ Cài Đặt Một Số Công Cụ

Nếu bạn không muốn cài đặt tất cả, có thể chạy chỉ các role cần thiết:

```bash
# Chỉ cài Cockpit
ansible-playbook -i inventory.ini playbook.yml --tags cockpit

# Chỉ cài Webmin
ansible-playbook -i inventory.ini playbook.yml --tags webmin

# Chỉ cài Monitoring
ansible-playbook -i inventory.ini playbook.yml --tags monitoring

# Chỉ cài Portainer
ansible-playbook -i inventory.ini playbook.yml --tags portainer

# Cài Cockpit và Webmin
ansible-playbook -i inventory.ini playbook.yml --tags cockpit,webmin

# Cài Monitoring và Portainer
ansible-playbook -i inventory.ini playbook.yml --tags monitoring,portainer
```

#### Tóm Tắt Ports

Sau khi cài đặt tất cả, các ports sau sẽ được mở:

| Port | Service | Protocol | Mô tả |
|------|---------|-----------|-------|
| 22 | SSH | TCP | Remote shell access |
| 80 | HTTP | TCP | Web server |
| 443 | HTTPS | TCP | Web server (SSL) |
| 9090 | Cockpit | TCP | Web interface quản lý server |
| 10000 | Webmin | TCP | Web interface quản lý hệ thống |
| 3000 | Grafana | TCP | Monitoring dashboard |
| 9090 | Prometheus | TCP | Metrics collection |
| 9100 | Node Exporter | TCP | System metrics |
| 9443 | Portainer | TCP | Docker management |

### Phương án 6: Cài Đặt AI/ML Tools

Hệ thống hỗ trợ cài đặt các công cụ AI/ML như Ollama, PyTorch, TensorFlow, v.v.

#### Ollama - Local LLM Models

Ollama cho phép chạy các Large Language Models (LLM) locally trên server.

**Cấu hình trong `project-config.yml`:**
```yaml
install_ollama: true
ollama_models:
  - "llama2"
  - "mistral"
  - "codellama"
ollama_api_enabled: true
ollama_api_port: 11434
```

**Sử dụng Ollama:**
```bash
# Trên server
ollama run llama2

# Gọi API từ ứng dụng
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?"
}'
```

**Các models phổ biến:**
- `llama2` - Meta Llama 2
- `mistral` - Mistral AI
- `codellama` - Code generation
- `neural-chat` - Chat model
- `gemma` - Google Gemma

#### Python ML Libraries

Cài đặt các thư viện Machine Learning phổ biến cho Python.

**Cấu hình trong `project-config.yml`:**
```yaml
install_python_ml: true  # PyTorch, TensorFlow, scikit-learn
install_python_llm: true  # LangChain, Transformers, v.v.
```

**Thư viện được cài đặt:**
- PyTorch, TensorFlow, Keras
- Scikit-learn, Pandas, NumPy
- Transformers, Diffusers
- LangChain, OpenAI, Anthropic
- Jupyter, JupyterLab

#### Stable Diffusion WebUI

Cài đặt Stable Diffusion để tạo ảnh từ text.

**Cấu hình trong `project-config.yml`:**
```yaml
install_stable_diffusion: true
```

**Truy cập Stable Diffusion:**
- URL: `http://server_ip:7860`
- Web interface để tạo ảnh

#### CUDA - GPU Support

Nếu server có GPU NVIDIA, có thể cài đặt CUDA để tăng tốc AI/ML.

**Cấu hình trong `project-config.yml`:**
```yaml
install_cuda: true  # Cần GPU NVIDIA
cuda_version: "12-1"
nvidia_driver_version: "535"
install_pytorch_cuda: true  # PyTorch với CUDA
```

**Kiểm tra GPU:**
```bash
# Kiểm tra GPU
nvidia-smi

# Kiểm tra CUDA
nvcc --version

# Kiểm tra PyTorch CUDA
python3 -c "import torch; print(torch.cuda.is_available())"
```

#### Các AI/ML Tools Khác

```yaml
install_text_generation_webui: true  # Text Generation WebUI
install_whisper: true  # Speech-to-Text
install_tts: true  # Text-to-Speech
install_rag_tools: true  # RAG tools (LlamaIndex, ChromaDB)
```

#### Chạy chỉ AI/ML Tools

```bash
# Chỉ cài Ollama
ansible-playbook -i inventory.ini playbook.yml --tags ai-ml -e "install_ollama=true"

# Chỉ cài CUDA
ansible-playbook -i inventory.ini playbook.yml --tags cuda -e "install_cuda=true"

# Cài tất cả AI/ML
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

#### Ports cho AI/ML

| Port | Service | Mô tả |
|------|---------|-------|
| 11434 | Ollama API | LLM API server |
| 7860 | Stable Diffusion | Image generation web UI |

### Phương án 7: AI Ops - AI Tự Vận Hành Server

Hệ thống hỗ trợ AI để tự động vận hành và quản lý server.

#### AI ChatOps - Chat với AI để Quản lý Server

Chat với AI qua terminal để quản lý server.

**Cấu hình trong `project-config.yml`:**
```yaml
install_ai_chatops: true
chatops_service_enabled: false  # Bật service (hoặc chạy manual)
chatops_model: "llama2"
```

**Sử dụng ChatOps:**
```bash
# Chạy manual
python3 /opt/ai-chatops/chatops.py

# Hoặc dùng alias
chatops
```

**Lệnh ChatOps:**
- `status` - Xem trạng thái hệ thống
- `service restart nginx` - Restart service
- `service stop mysql` - Stop service
- `logs nginx` - Xem logs của service
- Chat tự nhiên với AI để quản lý

#### AI Monitoring - AI Phân Tích Logs và Metrics Tự Động

AI tự động phân tích logs và metrics, phát hiện anomalies.

**Cấu hình trong `project-config.yml`:**
```yaml
install_ai_monitoring: true
ai_monitoring_enabled: true  # Bật service
ai_monitoring_model: "llama2"
ai_monitoring_interval: 300  # Kiểm tra mỗi 5 phút
```

**Kiểm tra AI Monitoring:**
```bash
# Xem logs
tail -f /opt/ai-monitoring/logs/analysis_*.log

# Kiểm tra service
systemctl status ai-monitoring
```

**AI Monitoring sẽ:**
- Phân tích CPU, Memory, Disk, Network
- Phát hiện anomalies
- Phân tích errors từ logs
- Đề xuất giải pháp
- Lưu analysis vào logs

#### AI Healing - Auto-healing với AI

AI tự động phát hiện và fix lỗi.

**Cấu hình trong `project-config.yml`:**
```yaml
install_ai_healing: true
ai_healing_enabled: true  # Bật service
ai_healing_model: "llama2"
ai_healing_interval: 60  # Kiểm tra mỗi 1 phút
ai_healing_auto_enabled: false  # Bật auto-healing tự động (CẢNH BÁO)
```

**⚠️ CẢNH BÁO:** Khi bật `ai_healing_auto_enabled: true`, AI sẽ tự động restart services.

**Kiểm tra AI Healing:**
```bash
# Xem logs
tail -f /opt/ai-healing/logs/healing_*.log

# Kiểm tra service
systemctl status ai-healing
```

**AI Healing sẽ:**
- Phát hiện failed services
- Phân tích lỗi với AI
- Đề xuất hành động healing
- (Nếu enabled) Tự động thực hiện healing

#### AI Assistant - AI Assistant với RAG

AI assistant với knowledge base để trả lời câu hỏi về server.

**Cấu hình trong `project-config.yml`:**
```yaml
install_ai_assistant: true
ai_assistant_model: "llama2"
```

**Sử dụng AI Assistant:**
```bash
# Chạy manual
python3 /opt/ai-assistant/assistant.py

# Hoặc dùng alias
ai-assistant
```

**Thêm Knowledge:**
```bash
# Thêm documents vào knowledge base
cp your-document.md /opt/ai-assistant/knowledge/
```

**AI Assistant sẽ:**
- Trả lời câu hỏi về server
- Sử dụng RAG với knowledge base
- Hỗ trợ troubleshooting
- Đưa ra best practices

#### AI Security Response - NHIỆM VỤ CHÍNH: Phát Hiện và Phản Hồi Tấn Công Mạng

**🛡️ Đây là nhiệm vụ chính của AI trong hệ thống - chuyên trách bảo mật và phản hồi tấn công mạng.**

AI tự động phát hiện và phản hồi các cuộc tấn công mạng như: DDoS, Brute Force, Malware, Port Scanning, Unauthorized Access.

**Cấu hình trong `project-config.yml`:**
```yaml
# AI Security Response - NHIỆM VỤ CHÍNH: SECURITY
install_ai_security_response: true  # Bật AI Security Response
ai_security_response_enabled: true  # Bật service
ai_security_response_model: "llama2"
ai_security_response_interval: 30  # Kiểm tra mỗi 30 giây
ai_security_response_auto_enabled: true  # Bật auto-response tự động
ai_security_response_admin_ip: "1.2.3.4/32"  # IP admin để SSH khi isolate
```

**Các loại tấn công được phát hiện:**
- **Brute Force** - >50 failed login attempts → Ban IP, enable fail2ban
- **DDoS** - >100 connections từ cùng IP → Block IP, isolate server
- **Port Scanning** - Kernel logs báo scan → Block IP
- **Malware** - Process đáng ngờ → Kill process
- **Unauthorized Access** - Logs báo unauthorized → Block IP
- **Resource Abuse** - CPU/Memory >90% → Kill suspicious processes

**Các hành động phản hồi:**
- `block_ip` - Chặn IP với iptables
- `block_port` - Chặn port
- `restart_firewall` - Restart firewall
- `enable_fail2ban` - Bật fail2ban
- `ban_ip_fail2ban` - Ban IP
- `kill_suspicious_process` - Kill process
- `isolate_server` - Cô lập server (critical)
- `notify_admin` - Thông báo admin
- `create_incident_report` - Tạo báo cáo

**Kiểm tra AI Security Response:**
```bash
# Xem service status
systemctl status ai-security-response

# Xem security logs
tail -f /opt/ai-security-response/logs/security_*.log

# Xem alerts
cat /opt/ai-security-response/alerts/alert_*.json

# Xem incidents
cat /opt/ai-security-response/incidents/incident_*.json

# Xem Fail2Ban status
fail2ban-client status
```

**Threat Levels:**
- **Low** - Notify admin, create report
- **Medium** - + Enable fail2ban
- **High** - + Block IP, kill suspicious process
- **Critical** - + Block port, isolate server

**📖 Xem chi tiết:** [AI_SECURITY_RESPONSE_GUIDE.md](AI_SECURITY_RESPONSE_GUIDE.md)

#### AI Security - Security Policy Enforcement

Giới hạn quyền của AI để ngăn chặn AI tự ý sửa code.

**Cấu hình trong `ai-security-policy.yml`:**
- Read-only mode cho AI thông thường
- Forbidden paths (source code, git repos)
- Forbidden commands (rm, git, npm install)
- Approval mechanism cho hành động nguy hiểm
- Audit logging

**📖 Xem chi tiết:** [AI_SECURITY_GUIDE.md](AI_SECURITY_GUIDE.md)

#### Hệ thống Bảo mật Nhiều Lớp (Defense in Depth)

**🛡️ Hệ thống bảo mật được thiết kế với nhiều lớp để đảm bảo ngay cả khi AI có sai sót, hệ thống vẫn được bảo vệ.**

```
LỚP 1: AI Security Response (Phát hiện và phản hồi tấn công mạng)
    ↓
LỚP 2A: App Hardening (Rào chắn bảo vệ code/app)
    ↓
LỚP 2B: Container Isolation (Container Sandbox)
    ↓
LỚP 3: AI Security Policy (Giới hạn quyền AI)
```

**LỚP 2A: App Hardening - Bảo vệ code và app**

Bảo vệ code và app trực tiếp với các rào chắn:
- **Integrity Checking**: Kiểm tra hash của files, phát hiện thay đổi
- **Immutable Filesystem**: Code read-only, không thể sửa bất ngờ
- **Snapshots**: Backup và rollback nhanh khi có vấn đề
- **AIDE/Tripwire**: HIDS phát hiện unauthorized changes
- **AppArmor**: Mandatory Access Control
- **Audit Logging**: Ghi log mọi thay đổi files

**Cấu hình trong `project-config.yml`:**
```yaml
# App Hardening - LỚP 2: Rào chắn bảo vệ code/app
install_app_hardening: true
app_hardening_enabled: true
app_hardening_immutable: true  # Code read-only
app_hardening_integrity_check: true  # Kiểm tra integrity
app_hardening_snapshots: true  # Tạo snapshots
app_hardening_max_snapshots: 10
```

**Sử dụng App Hardening:**
```bash
# Kiểm tra service
systemctl status app-hardening

# Tạo integrity baseline
python3 /opt/app-hardening/hardener.py

# Kiểm tra integrity
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.verify_integrity()"

# Tạo snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.create_snapshot('before-update')"

# Restore snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.restore_snapshot('before-update')"

# Làm code read-only
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.make_code_readonly()"
```

**LỚP 2B: Container Isolation - Chạy app trong container**

Cô lập app khỏi host system:
- **Docker Container**: App chạy trong container riêng
- **Read-only Root**: Filesystem chỉ đọc
- **Non-root User**: Không chạy với quyền root
- **Resource Limits**: Giới hạn CPU/Memory
- **Seccomp/AppArmor**: Giới hạn system calls
- **Network Isolation**: Mạng riêng cho container

**Cấu hình trong `project-config.yml`:**
```yaml
# Container Isolation - LỚP 2B: Container Sandbox
install_container_isolation: true
container_monitor_enabled: true
docker_base_image: "python:3.9-slim"
container_cpu_limit: "1.0"
container_memory_limit: "512M"
container_subnet: "172.20.0.0/16"
container_uid: "1000"
container_gid: "1000"
```

**Sử dụng Container Isolation:**
```bash
# Kiểm tra service
systemctl status container-monitor

# Build và chạy container
cd /opt/container-isolation
docker-compose up -d

# Xem logs
docker-compose logs -f

# Kiểm tra security
python3 /opt/container-isolation/monitor.py

# Xem container stats
docker stats
```

**📖 Xem chi tiết:** [MULTI_LAYER_SECURITY_GUIDE.md](MULTI_LAYER_SECURITY_GUIDE.md)

#### Chạy chỉ AI Ops

```bash
# Chỉ ChatOps
ansible-playbook -i inventory.ini playbook.yml --tags ai-chatops

# Chỉ AI Monitoring
ansible-playbook -i inventory.ini playbook.yml --tags ai-monitoring

# Chỉ AI Healing
ansible-playbook -i inventory.ini playbook.yml --tags ai-healing

# Chỉ AI Assistant
ansible-playbook -i inventory.ini playbook.yml --tags ai-assistant

# Chỉ AI Security Response (NHIỆM VỤ CHÍNH)
ansible-playbook -i inventory.ini playbook.yml --tags ai-security-response

# Chỉ AI Security (Policy Enforcement)
ansible-playbook -i inventory.ini playbook.yml --tags ai-security

# Chỉ App Hardening (LỚP 2)
ansible-playbook -i inventory.ini playbook.yml --tags app-hardening

# Chỉ Container Isolation (LỚP 2B)
ansible-playbook -i inventory.ini playbook.yml --tags container-isolation

# Tất cả AI Ops + Security Layers
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

#### Cảnh Bảo Quan Trọng

**AI Ops có thể tự động thay đổi hệ thống:**
- ChatOps có thể thực hiện lệnh
- AI Healing có thể restart services
- AI Monitoring có thể đề xuất actions
- **AI Security Response có thể block IP, isolate server, kill processes** (NHIỆM VỤ CHÍNH)

**🛡️ Bảo vệ Nhiều Lớp (Defense in Depth):**
- **Lớp 1**: AI Security Response phát hiện và phản hồi tấn công
- **Lớp 2A**: App Hardening bảo vệ code/app (integrity, immutable, snapshots)
- **Lớp 2B**: Container Isolation cô lập app (sandbox, resource limits)
- **Lớp 3**: AI Security Policy giới hạn quyền AI

**Nếu AI có sai sót:**
- Code vẫn được bảo vệ bởi immutable filesystem
- Có thể restore từ snapshots
- Container isolation ngăn chặn ảnh hưởng host
- Audit logs track mọi hành động

**Luôn:**
- Test kỹ trong dev environment trước
- Review logs thường xuyên
- Giữ `ai_healing_auto_enabled: false` nếu không cần
- Đặt `ai_security_response_admin_ip` đúng IP admin
- Monitor security logs
- Verify integrity baseline sau mỗi update
- Test restore procedures thường xuyên

**Khuyến nghị:**
- Test kỹ trước khi bật auto-healing
- Review AI recommendations trước khi thực hiện
- Monitor AI Ops logs thường xuyên
- Giới hạn quyền của AI Ops user

## 🔐 Cấu hình SSH Key

**Tạo SSH key trên máy local:**

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**Copy SSH key sang server:**

```bash
ssh-copy-id admin@server_ip
```

Hoặc manual:

```bash
cat ~/.ssh/id_rsa.pub | ssh admin@server_ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Cập nhật SSH key vào file cấu hình:**

- Ubuntu: Thêm public key vào `ubuntu-server-cloud-init.yaml`
- CentOS: Thêm public key vào `centos-kickstart.cfg`

## 📝 Cấu hình Password Hash

Để tạo password hash cho file cấu hình:

**Ubuntu (cloud-init):**

```bash
# Tạo password hash
openssl passwd -6

# Hoặc sử dụng python3
python3 -c 'import crypt; print(crypt.crypt("your_password", crypt.mksalt(crypt.METHOD_SHA512)))'
```

**CentOS (kickstart):**

```bash
# Tạo password hash
openssl passwd -1

# Hoặc sử dụng python
python3 -c 'import crypt; print(crypt.crypt("your_password", crypt.mksalt(crypt.METHOD_MD5)))'
```

## 🔧 Cấu hình Tùy chỉnh

### Ubuntu Cloud-init

Edit file `ubuntu-server-cloud-init.yaml`:

```yaml
# Thay đổi hostname
hostname: server-01

# Thay đổi timezone
timezone: Asia/Ho_Chi_Minh

# Thay đổi locale
locale: vi_VN.UTF-8

# Thay đổi user
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    passwd: "$6$rounds=4096$xyz$your_hashed_password_here"
    ssh_authorized_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your_public_key_here"
```

### CentOS Kickstart

Edit file `centos-kickstart.cfg`:

```kickstart
# Thay đổi hostname
network --bootproto=dhcp --device=eth0 --hostname=server-01

# Thay đổi password
rootpw --iscrypted $6$rounds=4096$xyz$your_hashed_password_here

# Thay đổi partition
autopart --type=lvm --fstype=ext4
```

## 🌐 Kiểm tra sau khi cài đặt

Sau khi cài đặt xong, kiểm tra:

```bash
# Kiểm tra IP address
ip addr show

# Kiểm tra services
systemctl status nginx
systemctl status mysql
systemctl status docker

# Kiểm tra firewall
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # CentOS

# Test web server
curl http://localhost
```

## 📦 Các Service được cài đặt

### Web Server
- Nginx (mặc định)
- Apache (tùy chọn)
- HTTP/HTTPS ports mở

### Database
- MySQL (mặc định)
- PostgreSQL (tùy chọn)
- Remote access được cấu hình

### Application Server
- Docker & Docker Compose
- Node.js & npm (tùy chọn)
- Python 3 & pip
- Git
- PM2 (tùy chọn)
- Supervisor

### Remote Management Tools
- **Cockpit** - Web interface quản lý server (port 9090)
- **Webmin** - Web interface quản lý hệ thống (port 10000)
- **Grafana** - Monitoring dashboard (port 3000)
- **Prometheus** - Metrics collection (port 9090)
- **Node Exporter** - System metrics (port 9100)
- **Portainer** - Docker management web interface (port 9443)

### AI/ML Tools
- **Ollama** - Local LLM models (port 11434)
- **PyTorch/TensorFlow** - ML libraries
- **LangChain** - LLM framework
- **Stable Diffusion** - Image generation (port 7860)
- **CUDA** - GPU support (nếu có GPU NVIDIA)

### AI Ops (AI Tự Vận Hành Server)
- **AI ChatOps** - Chat với AI để quản lý server
- **AI Monitoring** - AI phân tích logs và metrics tự động
- **AI Healing** - Auto-healing với AI
- **AI Assistant** - AI assistant với RAG knowledge base

## 🔒 Security Recommendations

1. **Luôn sử dụng SSH key thay vì password**
2. **Tắt root login SSH**
3. **Cấu hình firewall chỉ mở các port cần thiết**
4. **Cập nhật hệ thống thường xuyên**
5. **Sử dụng fail2ban để chống brute-force**
6. **Đổi password mặc định**
7. **Sử dụng SSL/TLS cho web server**
8. **Đổi password mặc định cho Grafana, Cockpit, Webmin**
9. **Giới hạn truy cập đến các công cụ quản lý từ xa bằng firewall hoặc VPN**
10. **Sử dụng reverse proxy (Nginx) với SSL cho các công cụ web**
11. **Bật authentication cho Prometheus nếu cần**
12. **Regular backup configuration và data**
13. **CẢNH BÁO AI Ops:**
    - Test kỹ trước khi bật auto-healing
    - Review AI recommendations trước khi thực hiện
    - Monitor AI Ops logs thường xuyên
    - Giới hạn quyền của AI Ops user
    - Không bật auto-healing trong production nếu chưa test kỹ

## 🆘 Troubleshooting

### Không thể boot từ USB
- Kiểm tra BIOS/UEFI settings
- Tắt Secure Boot
- Thử USB khác

### Cloud-init không chạy
- Kiểm tra tên file là `user-data`
- Kiểm tra file nằm trong thư mục `nocloud/`
- Kiểm tra format file là YAML đúng

### Ansible không kết nối được
- Kiểm tra SSH key đã được copy
- Kiểm tra IP address trong inventory.ini
- Kiểm tra firewall cho phép SSH

### Service không start
- Kiểm tra log: `journalctl -u service_name`
- Kiểm tra port conflict: `netstat -tulpn`
- Kiểm tra configuration file

### Cockpit không truy cập được
- Kiểm tra service: `systemctl status cockpit`
- Kiểm tra firewall: `sudo ufw status` hoặc `sudo firewall-cmd --list-all`
- Kiểm tra port 9090 đã mở chưa
- Kiểm tra log: `journalctl -u cockpit`

### Webmin không truy cập được
- Kiểm tra service: `systemctl status webmin`
- Kiểm tra firewall cho phép port 10000
- Kiểm tra log: `/var/webmin/miniserv.error`

### Grafana không truy cập được
- Kiểm tra service: `systemctl status grafana-server`
- Kiểm tra firewall cho phép port 3000
- Kiểm tra log: `/var/log/grafana/grafana.log`
- Reset admin password nếu cần

### Prometheus không collect metrics
- Kiểm tra service: `systemctl status prometheus`
- Kiểm tra Node Exporter: `systemctl status node_exporter`
- Kiểm tra configuration: `/etc/prometheus/prometheus.yml`
- Kiểm tra targets trong Prometheus UI

### Portainer không chạy
- Kiểm tra Docker đang chạy: `systemctl status docker`
- Kiểm tra container: `docker ps -a`
- Kiểm tra logs: `docker logs portainer`
- Re-create container nếu cần

## 📚 Tài liệu tham khảo

- [Ubuntu Cloud-init Documentation](https://cloud-init.io/)
- [CentOS Kickstart Documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-commands-and-options_reference)
- [Ansible Documentation](https://docs.ansible.com/)
- [Cockpit Documentation](https://cockpit-project.org/guide/latest/)
- [Webmin Documentation](http://www.webmin.com/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Portainer Documentation](https://docs.portainer.io/)

## 📄 License

MIT License

## 👥 Contributing

Pull requests are welcome!

---

**Lưu ý quan trọng:**
- Backup dữ liệu trước khi cài đặt lại hệ điều hành
- Test trên môi trường development trước khi áp dụng production
- Đọc kỹ hướng dẫn trước khi thực hiện
- Không chịu trách nhiệm cho mất mát dữ liệu
