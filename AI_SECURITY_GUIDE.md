# AI Security Guide - Hướng dẫn bảo mật AI

## Tổng quan

Hệ thống AI Security được thiết kế để:
1. Ngăn chặn AI tự ý sửa code của ứng dụng trong server
2. **AI Security Response - Nhiệm vụ chính: Phát hiện và phản hồi tấn công mạng**

Các biện pháp bảo mật bao gồm:

1. **Read-only mode** - AI chỉ được phép đọc, không được ghi
2. **Forbidden paths** - Chặn AI truy cập vào thư mục source code
3. **Forbidden commands** - Chặn các lệnh nguy hiểm (rm, git, npm install, v.v.)
4. **Approval mechanism** - Yêu cầu phê duyệt cho các hành động nguy hiểm
5. **Audit logging** - Ghi log tất cả hành động của AI

### Cấu hình

### 1. Cấu hình trong `project-config.yml`

Đảm bảo các cài đặt sau:

```yaml
# Tắt auto-healing tự động
install_ai_healing: false
ai_healing_enabled: false
ai_healing_auto_enabled: false  # LUÔN ĐỂ FALSE

# AI Monitoring - an toàn, chỉ đọc
install_ai_monitoring: false
ai_monitoring_enabled: false

# AI Assistant - an toàn, chỉ trả lời câu hỏi
install_ai_assistant: false

# AI Security Response - NHIỆM VỤ CHÍNH: SECURITY
install_ai_security_response: true  # Bật AI Security Response
ai_security_response_enabled: true  # Bật service
ai_security_response_model: "llama2"
ai_security_response_interval: 30  # Kiểm tra mỗi 30 giây
ai_security_response_auto_enabled: true  # Bật auto-response
ai_security_response_admin_ip: "1.2.3.4/32"  # IP admin
```

**Xem chi tiết**: [AI_SECURITY_RESPONSE_GUIDE.md](AI_SECURITY_RESPONSE_GUIDE.md)

### 2. Cấu hình trong `ai-security-policy.yml`

File này định nghĩa các chính sách bảo mật chi tiết:

```yaml
ai_security:
  # Chế độ hoạt động
  operation_mode: "read_only"  # read_only, monitored, unrestricted
  
  # Đường dẫn bị cấm
  forbidden_paths:
    - "/opt/apps/*/src"      # Source code
    - "/opt/apps/*/app"      # App code
    - "/var/www/html"        # Web root
    - "/home/*/git"          # Git repos
  
  # Lệnh bị cấm
  forbidden_commands:
    - "rm"
    - "mv"
    - "cp"
    - "git"
    - "npm install"
    - "pip install"
    - "docker build"
  
  # Lệnh được phép (read-only mode)
  allowed_commands:
    - "systemctl status"
    - "journalctl"
    - "df -h"
    - "free -h"
    - "cat"
    - "ls"
    - "grep"
```

## Các chế độ hoạt động

### Read-Only Mode (Mặc định - Khuyên dùng)
- AI chỉ được phép đọc thông tin
- Không được sửa file, restart service, hay thực thi lệnh nguy hiểm
- An toàn nhất cho production

### Monitored Mode
- AI có thể thực hiện một số hành động
- Mọi hành động đều được ghi log
- Cần phê duyệt cho hành động nguy hiểm

### Unrestricted Mode (Không khuyến khích)
- AI có thể thực hiện mọi hành động
- Chỉ dùng cho testing/dev environment

## Audit Logging

Tất cả hành động của AI được ghi log tại `/var/log/ai-audit.log`:

```json
{
  "timestamp": "2026-05-14T11:00:00",
  "action": "command_blocked_ai-healing",
  "result": "denied",
  "details": "Command: rm -rf /opt/apps/myapp/src, Reason: Command contains forbidden: rm"
}
```

Xem log:
```bash
tail -f /var/log/ai-audit.log
```

## Kiểm tra Security Policy

Chạy script test:
```bash
python3 /opt/ai-security/enforcer.py
```

## Tích hợp vào AI Components

Để tích hợp security enforcer vào AI components, import và sử dụng:

```python
from ai_security.enforcer import AISecurityEnforcer

enforcer = AISecurityEnforcer()

# Kiểm tra trước khi thực thi lệnh
try:
    result = enforcer.execute_command("systemctl status nginx", ai_component="ai-healing")
except PermissionError as e:
    print(f"Lệnh bị chặn: {e}")

# Kiểm tra trước khi sửa file
try:
    enforcer.modify_file("/opt/apps/myapp/src/app.js", ai_component="ai-assistant")
except PermissionError as e:
    print(f"Sửa file bị chặn: {e}")
```

## Các biện pháp bổ sung

### 1. Giới hạn quyền user
Chạy AI với user có quyền hạn chế:
```bash
# Tạo user riêng cho AI
sudo useradd -r -s /bin/false ai-user
sudo chown -R ai-user:ai-user /opt/ai-*
```

### 2. Firewall rules
Chặn AI truy cập internet nếu không cần:
```bash
sudo ufw deny out from ai-user to any
```

### 3. Resource limits
Giới hạn CPU/memory cho AI processes:
```bash
# Thêm vào systemd service
CPUQuota=20%
MemoryLimit=512M
```

### 4. Containerization
Chạy AI trong container với quyền hạn chế:
```dockerfile
FROM python:3.9-slim
USER nobody
```

## Troubleshooting

### AI bị chặn khi cần thiết
1. Kiểm tra `operation_mode` trong `ai-security-policy.yml`
2. Thêm command/path vào `allowed_commands` hoặc bỏ khỏi `forbidden_paths`
3. Nếu cần, chuyển sang `monitored` mode

### Audit log không ghi
1. Kiểm tra quyền của `/var/log/ai-audit.log`
2. Đảm bảo directory tồn tại: `sudo mkdir -p /var/log/ai-audit`

### AI vẫn tự ý sửa code
1. Đảm bảo `ai_healing_auto_enabled: false` trong `project-config.yml`
2. Kiểm tra log để xem AI component nào đang hoạt động
3. Tắt service: `sudo systemctl stop ai-healing`

## Best Practices

1. **LUÔN để `ai_healing_auto_enabled: false`** trong production
2. Sử dụng **read-only mode** mặc định
3. Review audit log thường xuyên
4. Chỉ enable AI components khi thực sự cần
5. Test kỹ trong dev environment trước khi deploy
6. Sử dụng version control để revert changes nếu cần

## Liên hệ

Nếu có vấn đề về security, kiểm tra:
- Audit log: `/var/log/ai-audit.log`
- Security policy: `/opt/ai-security/security-policy.yml`
- AI component logs: `/opt/ai-*/logs/`
