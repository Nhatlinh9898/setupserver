# Quick Start - Deploy AmazeBid

## Cách nhanh nhất để deploy

### 1. Cấu hình inventory.ini

```ini
[webservers]
server-01 ansible_host=YOUR_SERVER_IP ansible_user=admin
```

### 2. Deploy

```powershell
.\deploy-amazebid.ps1
```

Hoặc dùng Ansible trực tiếp:

```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

## Khi có thay đổi code

```powershell
# 1. Thay đổi code trong app-code/
# 2. Deploy
.\deploy-amazebid.ps1
```

## Rollback nếu có lỗi

```powershell
.\deploy-amazebid.ps1 -Action rollback
```

## Xem trạng thái

```powershell
.\deploy-amazebid.ps1 -Action status
```

## Các lệnh Ansible hữu ích

```bash
# Chỉ deploy code (không cài dependencies)
ansible-playbook -i inventory.ini playbook.yml --tags deploy,application -e @project-config.yml

# Chỉ cài dependencies
ansible-playbook -i inventory.ini playbook.yml --tags dependencies -e @project-config.yml

# Chỉ restart app
ansible-playbook -i inventory.ini playbook.yml --tags application-restart -e @project-config.yml

# Chỉ chạy migrations
ansible-playbook -i inventory.ini playbook.yml --tags prisma-migrate -e @project-config.yml
```

## Truy cập ứng dụng

- **App**: http://YOUR_SERVER_IP:3000
- **Cockpit**: https://YOUR_SERVER_IP:9090
- **Grafana**: http://YOUR_SERVER_IP:3000
- **Portainer**: https://YOUR_SERVER_IP:9443

## Lưu ý quan trọng

⚠️ **Trước khi deploy production:**
1. Thay đổi password trong `project-config.yml`
2. Cập nhật API keys (Firebase, Gemini, Stripe, etc.)
3. Test trên development server trước

📖 **Xem hướng dẫn chi tiết:** [DEPLOYMENT_GUIDE_AMAZEBID.md](DEPLOYMENT_GUIDE_AMAZEBID.md)
