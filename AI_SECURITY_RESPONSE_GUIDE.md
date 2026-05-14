# AI Security Response Guide - Hướng dẫn AI Phản hồi Tấn công Mạng

## Tổng quan

**AI Security Response** là nhiệm vụ chính của AI trong hệ thống, chuyên trách phát hiện và phản hồi tự động các cuộc tấn công mạng. AI này có quyền cao hơn các AI components khác để thực hiện các hành động security cần thiết.

### Nhiệm vụ chính
- Phát hiện các cuộc tấn công mạng (DDoS, Brute Force, Malware, Unauthorized Access)
- Phân tích mức độ nghiêm trọng của mối đe dọa
- Tự động phản hồi để bảo vệ hệ thống
- Tạo báo cáo incident và thông báo admin

## Các loại tấn công được phát hiện

### 1. Brute Force Attack
- **Phát hiện**: >50 failed login attempts
- **Phản hồi**: Bật fail2ban, ban IP attacker
- **Mức độ**: Critical

### 2. DDoS Attack
- **Phát hiện**: >100 connections từ cùng một IP
- **Phản hồi**: Block IP, restart firewall, có thể isolate server
- **Mức độ**: Critical

### 3. Port Scanning
- **Phát hiện**: Kernel logs báo port scan
- **Phản hồi**: Block IP scanning, enable fail2ban
- **Mức độ**: High

### 4. Malware/Rootkit
- **Phát hiện**: Process đáng ngờ (miner, crypto, backdoor)
- **Phản hồi**: Kill process, notify admin
- **Mức độ**: Critical

### 5. Unauthorized Access
- **Phát hiện**: Logs báo unauthorized/permission denied
- **Phản hồi**: Block IP, notify admin, tạo incident report
- **Mức độ**: Critical

### 6. Resource Abuse
- **Phát hiện**: CPU/Memory >90%, connections >1000
- **Phản hồi**: Kill suspicious processes, notify admin
- **Mức độ**: High/Medium

## Cấu hình

### 1. Cấu hình trong `project-config.yml`

```yaml
# AI Security Response - NHIỆM VỤ CHÍNH: SECURITY
install_ai_security_response: true  # Bật AI Security Response
ai_security_response_enabled: true  # Bật service
ai_security_response_model: "llama2"  # Model AI
ai_security_response_interval: 30  # Kiểm tra mỗi 30 giây
ai_security_response_auto_enabled: true  # Bật auto-response
ai_security_response_admin_ip: "1.2.3.4/32"  # IP admin để SSH khi isolate
```

### 2. Cấu hình trong `ai-security-policy.yml`

AI Security Response có quyền riêng:

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
  
  # Threat levels và hành động tương ứng
  threat_levels:
    low:
      actions: ["notify_admin", "create_incident_report"]
    medium:
      actions: ["notify_admin", "create_incident_report", "enable_fail2ban"]
    high:
      actions: ["notify_admin", "create_incident_report", "enable_fail2ban", "block_ip", "kill_suspicious_process"]
    critical:
      actions: ["notify_admin", "create_incident_report", "enable_fail2ban", "block_ip", "block_port", "kill_suspicious_process", "isolate_server"]
```

## Các hành động phản hồi

### 1. Block IP
Chặn IP attacker với iptables:
```bash
iptables -A INPUT -s <IP> -j DROP
```

### 2. Block Port
Chặn port bị tấn công:
```bash
iptables -A INPUT -p tcp --dport <PORT> -j DROP
```

### 3. Enable Fail2Ban
Bật fail2ban để tự động ban IPs:
```bash
systemctl enable fail2ban
systemctl start fail2ban
```

### 4. Ban IP với Fail2Ban
Ban IP cụ thể:
```bash
fail2ban-client set sshd banip <IP>
```

### 5. Kill Suspicious Process
Kill process đáng ngờ:
```bash
kill -9 <PID>
```

### 6. Isolate Server
Cô lập server (hành động cực đoan):
```bash
ufw default deny incoming
ufw allow from <ADMIN_IP> to any port 22
```

### 7. Notify Admin
Tạo alert file:
```json
{
  "timestamp": "2026-05-14T11:00:00",
  "message": "CRITICAL THREAT DETECTED",
  "severity": "critical"
}
```

### 8. Create Incident Report
Tạo báo cáo chi tiết:
```json
{
  "timestamp": "2026-05-14T11:00:00",
  "threat_level": "critical",
  "alerts": [...],
  "ai_analysis": "...",
  "status": "open"
}
```

## Monitoring và Logs

### 1. Security Logs
```bash
# Xem security logs
tail -f /opt/ai-security-response/logs/security_*.log

# Xem alerts
ls -la /opt/ai-security-response/alerts/
cat /opt/ai-security-response/alerts/alert_*.json

# Xem incidents
ls -la /opt/ai-security-response/incidents/
cat /opt/ai-security-response/incidents/incident_*.json
```

### 2. Service Status
```bash
# Kiểm tra service status
systemctl status ai-security-response

# Xem logs
journalctl -u ai-security-response -f

# Restart service
systemctl restart ai-security-response
```

### 3. Fail2Ban Status
```bash
# Kiểm tra fail2ban status
fail2ban-client status

# Xem banned IPs
fail2ban-client status sshd

# Unban IP
fail2ban-client set sshd unbanip <IP>
```

### 4. Firewall Status
```bash
# Kiểm tra UFW status
ufw status verbose

# Xem iptables rules
iptables -L -n -v
```

## Quy trình phản hồi

### Quy trình tự động (Auto-response enabled)

```
1. Detect suspicious activity
   ↓
2. Analyze with AI
   ↓
3. Determine threat level (low/medium/high/critical)
   ↓
4. Execute response actions based on threat level
   ↓
5. Create incident report
   ↓
6. Notify admin
   ↓
7. Log all actions
```

### Quy trình manual (Auto-response disabled)

```
1. Detect suspicious activity
   ↓
2. Analyze with AI
   ↓
3. Create incident report
   ↓
4. Notify admin with recommendations
   ↓
5. Admin reviews and approves actions
   ↓
6. Execute approved actions
```

## Testing

### 1. Test Brute Force Detection
```bash
# Thử login sai nhiều lần từ IP khác
ssh root@server -o ConnectTimeout=5
# Lặp lại >50 lần
```

### 2. Test Port Scanning Detection
```bash
# Sử dụng nmap để scan ports
nmap -sS server_ip
```

### 3. Test DDoS Detection
```bash
# Tạo nhiều connections từ cùng IP
# Sử dụng tool như ab (Apache Benchmark)
ab -n 1000 -c 100 http://server_ip/
```

### 4. Test AI Response
```bash
# Kiểm tra AI response script
python3 /opt/ai-security-response/responder.py
```

## Best Practices

### 1. Production
- **LUÔN bật AI Security Response**
- Đặt `ai_security_response_admin_ip` đúng IP của admin
- Review incident reports thường xuyên
- Monitor security logs
- Test response system thường xuyên

### 2. Development
- Có thể tắt auto-response để test: `ai_security_response_auto_enabled: false`
- Sử dụng threat level thấp hơn để test
- Review AI analysis trước khi deploy

### 3. Security
- Đảm bảo AI Security Response chạy với user có đủ quyền
- Giới quyền user nhưng vẫn đủ để thực hiện security actions
- Sử dụng SSH keys thay vì passwords
- Enable 2FA cho admin access
- Regular security audits

## Troubleshooting

### AI không phản hồi
1. Kiểm tra service status: `systemctl status ai-security-response`
2. Kiểm tra logs: `journalctl -u ai-security-response -n 100`
3. Đảm bảo Ollama đang chạy: `systemctl status ollama`
4. Kiểm tra model đã pull: `ollama list`

### False positives
1. Review incident reports
2. Điều chỉnh thresholds trong script
3. Thêm IP vào whitelist nếu cần
4. Tắt auto-response tạm thời để điều chỉnh

### Không thể SSH sau isolate
1. Sử dụng console access từ cloud provider
2. Hoặc truy cập từ IP admin đã cấu hình
3. Reset firewall rules:
   ```bash
   ufw --force reset
   ufw allow 22/tcp
   ufw enable
   ```

### Fail2Ban không hoạt động
1. Kiểm tra service: `systemctl status fail2ban`
2. Kiểm tra config: `cat /etc/fail2ban/jail.local`
3. Restart: `systemctl restart fail2ban`

## Tích hợp với các công cụ khác

### 1. SIEM (Splunk, ELK)
Gửi alerts đến SIEM:
```python
# Thêm vào notify_admin function
import requests
requests.post("https://siem.example.com/api/alerts", json=alert)
```

### 2. Slack/Discord Notification
Gửi notification đến Slack:
```python
# Thêm webhook URL vào config
webhook_url = "https://hooks.slack.com/services/..."
requests.post(webhook_url, json={"text": message})
```

### 3. Email Notification
Gửi email:
```python
import smtplib
from email.mime.text import MIMEText
# Gửi email với alert details
```

### 4. Cloud Provider Security
- AWS GuardDuty
- Azure Security Center
- Google Cloud Security Command Center

## Kết luận

AI Security Response là nhiệm vụ chính của AI trong hệ thống, được thiết kế để:
- Phát hiện nhanh các cuộc tấn công
- Phản hồi tự động để giảm thiểu thiệt hại
- Tạo báo cáo chi tiết cho admin
- Học từ các incident để cải thiện

Đảm bảo cấu hình đúng và test kỹ trước khi deploy production.
