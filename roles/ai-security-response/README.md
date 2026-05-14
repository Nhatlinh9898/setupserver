# AI Security Response Role

## Mô tả

AI Security Response là nhiệm vụ chính của AI trong hệ thống, chuyên trách phát hiện và phản hồi tự động các cuộc tấn công mạng.

## Nhiệm vụ

- Phát hiện các cuộc tấn công mạng (DDoS, Brute Force, Malware, Unauthorized Access)
- Phân tích mức độ nghiêm trọng với AI
- Tự động phản hồi để bảo vệ hệ thống
- Tạo báo cáo incident và thông báo admin

## Các loại tấn công được phát hiện

1. **Brute Force Attack** - >50 failed login attempts
2. **DDoS Attack** - >100 connections từ cùng một IP
3. **Port Scanning** - Kernel logs báo port scan
4. **Malware/Rootkit** - Process đáng ngờ
5. **Unauthorized Access** - Logs báo unauthorized
6. **Resource Abuse** - CPU/Memory >90%

## Các hành động phản hồi

- `block_ip` - Chặn IP với iptables
- `block_port` - Chặn port
- `restart_firewall` - Restart firewall
- `enable_fail2ban` - Bật fail2ban
- `ban_ip_fail2ban` - Ban IP với fail2ban
- `kill_suspicious_process` - Kill process
- `isolate_server` - Cô lập server (critical)
- `notify_admin` - Thông báo admin
- `create_incident_report` - Tạo báo cáo

## Cấu hình

### Variables

```yaml
install_ai_security_response: true
ai_security_response_enabled: true
ai_security_response_model: "llama2"
ai_security_response_interval: 30
ai_security_response_auto_enabled: true
ai_security_response_admin_ip: "0.0.0.0/0"
```

### Dependencies

- Ollama (để chạy AI model)
- Python 3 với các packages: langchain, psutil, requests
- Fail2ban
- UFW Firewall
- iptables-persistent

## Cấu trúc thư mục

```
roles/ai-security-response/
├── tasks/
│   └── main.yml
├── handlers/
│   └── main.yml
└── README.md
```

## Files được tạo

- `/opt/ai-security-response/responder.py` - Script chính
- `/opt/ai-security-response/logs/` - Security logs
- `/opt/ai-security-response/alerts/` - Alert files
- `/opt/ai-security-response/incidents/` - Incident reports
- `/etc/fail2ban/jail.local` - Fail2ban config
- `/etc/ufw/ai-security-rules` - UFW rules
- `/etc/systemd/system/ai-security-response.service` - Systemd service

## Sử dụng

### Deploy với Ansible

```bash
ansible-playbook -i inventory playbook.yml -e @project-config.yml
```

### Kiểm tra service

```bash
systemctl status ai-security-response
journalctl -u ai-security-response -f
```

### Xem logs

```bash
tail -f /opt/ai-security-response/logs/security_*.log
cat /opt/ai-security-response/alerts/alert_*.json
cat /opt/ai-security-response/incidents/incident_*.json
```

### Test

```bash
python3 /opt/ai-security-response/responder.py
```

## Security Policy

AI Security Response có quyền riêng được định nghĩa trong `ai-security-policy.yml`:

```yaml
ai_security_response_security:
  allowed_actions:
    - "block_ip"
    - "block_port"
    - "restart_firewall"
    - "enable_fail2ban"
    - "ban_ip_fail2ban"
    - "kill_suspicious_process"
    - "isolate_server"
    - "notify_admin"
    - "create_incident_report"
  
  threat_levels:
    critical:
      actions: ["notify_admin", "create_incident_report", "enable_fail2ban", "block_ip", "block_port", "kill_suspicious_process", "isolate_server"]
```

## Best Practices

1. Luôn bật AI Security Response trong production
2. Đặt `ai_security_response_admin_ip` đúng IP của admin
3. Review incident reports thường xuyên
4. Test response system trước khi deploy
5. Monitor security logs

## Xem thêm

- [AI_SECURITY_RESPONSE_GUIDE.md](../../AI_SECURITY_RESPONSE_GUIDE.md) - Hướng dẫn chi tiết
- [ai-security-policy.yml](../../ai-security-policy.yml) - Security policy
