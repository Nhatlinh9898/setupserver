# Quick Start — CORE Server + Deploy

## A. CORE path (zero → base Linux server usable)

Mục tiêu: Nginx/web + runtime (Docker/Python) + MySQL/MariaDB **không** kéo AI/CUDA/mesh.

### 1. Chuẩn bị OS (một trong các cách)

```bash
# Trên máy vừa cài Ubuntu/Rocky:
sudo bash server-setup.sh
# Hoặc non-interactive:
sudo SETUP_NONINTERACTIVE=1 SETUP_INSTALL_DOCKER=y SETUP_INSTALL_NGINX=y bash server-setup.sh
```

Hoặc dùng template cài đặt:

- Ubuntu: `ubuntu-server-cloud-init.yaml` (đổi mọi `CHANGE_ME_*`)
- Rocky/Alma 9: `centos-kickstart.cfg` (đổi mọi `CHANGE_ME_*`; **không** dùng mirror CentOS 8 EOL)

### 2. Sửa inventory + vars

```bash
# inventory.ini — thay CHANGE_ME_*_IP
# vars.yml — đổi mysql_password / postgresql_password (bỏ CHANGE_ME)
```

All-in-one (app = db cùng máy): đặt `CHANGE_ME_APP_IP` và `CHANGE_ME_DB_IP` cùng một IP.

### 3. Chạy Ansible CORE thôi

```bash
# Từ máy control (có ansible)
ansible-galaxy collection install community.mysql community.general  # nếu thiếu module
ansible-playbook -i inventory.ini playbook.yml --tags core -e @vars.yml

# Hoặc không dùng tags — playbook mặc định chỉ chạy core
# vì các role extras đã bị gate bằng flag = false
ansible-playbook -i inventory.ini playbook.yml -e @vars.yml
```

### 4. Kiểm tra nhanh

```bash
ansible appservers -i inventory.ini -m ping
curl -I http://CHANGE_ME_APP_IP/
ssh admin@CHANGE_ME_APP_IP 'docker --version; systemctl is-active nginx || true'
```

---

## B. Deploy ứng dụng (tùy chọn — tắt mặc định)

Trong `vars.yml`:

```yaml
deploy_enabled: true
deploy_method: git   # hoặc local
project_path: /opt/apps/my-app
git_repository: "https://github.com/YOUR_ORG/YOUR_REPO.git"
git_branch: main
mysql_password: "your-real-password"
```

Local code: đặt mã nguồn vào `app-code/` rồi `deploy_method: local`.

```bash
ansible-playbook -i inventory.ini playbook.yml --tags deploy,dependencies,application -e @vars.yml
```

---

## C. AmazeBid / extras (ngoài CORE)

Giữ nguyên flow cũ nếu cần:

```powershell
.\deploy-amazebid.ps1
```

```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

Bật extras bằng flag trong `vars.yml` / `project-config.yml`, ví dụ:

- `install_remote_management: true` — Cockpit, Webmin, monitoring, Portainer
- `install_ai_ml: true`, `install_ai_ops: true`, … — **không** nằm trong CORE

### Lệnh Ansible hữu ích (khi đã bật deploy)

```bash
ansible-playbook -i inventory.ini playbook.yml --tags deploy,application -e @vars.yml
ansible-playbook -i inventory.ini playbook.yml --tags dependencies -e @vars.yml
ansible-playbook -i inventory.ini playbook.yml --tags core -e @vars.yml
```

### Truy cập (sau khi bật service tương ứng)

- App / Nginx: `http://YOUR_SERVER_IP/`
- Cockpit (nếu bật remote-mgmt): `https://YOUR_SERVER_IP:9090`

⚠️ **Production:** đổi mọi `CHANGE_ME`, không commit secret, test staging trước.

📖 Chi tiết AmazeBid: [DEPLOYMENT_GUIDE_AMAZEBID.md](DEPLOYMENT_GUIDE_AMAZEBID.md)
