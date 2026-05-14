# Hệ thống Bảo mật Nhiều Lớp (Defense in Depth)

## Tổng quan

Hệ thống bảo mật được thiết kế theo mô hình **Defense in Depth** với nhiều lớp bảo vệ để đảm bảo rằng ngay cả khi AI có sai sót khi thực thi, hệ thống vẫn được bảo vệ.

```
┌─────────────────────────────────────────────────────────────┐
│                    LỚP 1: AI Security Response               │
│              (Phát hiện và phản hồi tấn công mạng)            │
│  - Phát hiện: DDoS, Brute Force, Malware, Port Scanning      │
│  - Phản hồi: Block IP, Isolate Server, Kill Process          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              LỚP 2A: App Hardening (Rào chắn bảo vệ)         │
│              (Bảo vệ code và app trực tiếp)                   │
│  - Integrity Checking: Kiểm tra hash của files               │
│  - Immutable Filesystem: Code read-only                      │
│  - Snapshots: Backup và rollback nhanh                       │
│  - AIDE/Tripwire: HIDS (Host-based Intrusion Detection)       │
│  - AppArmor: Mandatory Access Control                        │
│  - Audit Logging: Ghi log mọi thay đổi                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│            LỚP 2B: Container Isolation (Sandbox)             │
│          (Chạy app trong container để cô lập)                 │
│  - Docker Container: Cô lập app khỏi host                    │
│  - Read-only Root: Filesystem chỉ đọc                        │
│  - Non-root User: Không chạy với quyền root                  │
│  - Resource Limits: Giới hạn CPU/Memory                      │
│  - Seccomp/AppArmor: Giới hạn system calls                   │
│  - Network Isolation: Mạng riêng cho container                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│               LỚP 3: AI Security Policy Enforcement          │
│            (Giới hạn quyền của AI components)                 │
│  - Read-only Mode: AI chỉ đọc, không ghi                    │
│  - Forbidden Paths: Chặn truy cập source code                │
│  - Forbidden Commands: Chặn lệnh nguy hiểm                  │
│  - Approval Mechanism: Yêu cầu phê duyệt                    │
│  - Audit Logging: Ghi log mọi hành động                      │
└─────────────────────────────────────────────────────────────┘
```

## Lớp 1: AI Security Response

**Nhiệm vụ chính**: Phát hiện và phản hồi tấn công mạng

### Các loại tấn công được phát hiện
- Brute Force Attack
- DDoS Attack
- Port Scanning
- Malware/Rootkit
- Unauthorized Access
- Resource Abuse

### Các hành động phản hồi
- Block IP với iptables
- Block Port
- Restart Firewall
- Enable Fail2Ban
- Kill Suspicious Process
- Isolate Server (critical)
- Notify Admin
- Create Incident Report

### Cấu hình
```yaml
install_ai_security_response: true
ai_security_response_enabled: true
ai_security_response_interval: 30
ai_security_response_auto_enabled: true
```

### Monitoring
```bash
systemctl status ai-security-response
tail -f /opt/ai-security-response/logs/security_*.log
cat /opt/ai-security-response/incidents/incident_*.json
```

## Lớp 2A: App Hardening

**Nhiệm vụ**: Bảo vệ code và app trực tiếp với các rào chắn

### 1. Integrity Checking
- Tạo baseline hash cho tất cả files
- Kiểm tra integrity thường xuyên
- Phát hiện files bị sửa/xóa/thêm mới

**Sử dụng**:
```bash
# Tạo baseline
python3 /opt/app-hardening/hardener.py

# Kiểm tra integrity
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.verify_integrity()"
```

### 2. Immutable Filesystem
- Làm code trở thành read-only
- Sử dụng `chattr +i` (Linux ext4/xfs)
- Ngăn chặn sửa code bất ngờ

**Sử dụng**:
```bash
# Làm code read-only
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.make_code_readonly()"

# Làm code writable (khi cần update)
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.make_code_writable()"
```

### 3. Snapshots
- Tạo snapshots của code
- Restore nhanh khi có vấn đề
- Tự động cleanup snapshots cũ

**Sử dụng**:
```bash
# Tạo snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.create_snapshot('before-update')"

# Liệt kê snapshots
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.list_snapshots()"

# Restore snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.restore_snapshot('before-update')"
```

### 4. AIDE (Advanced Intrusion Detection Environment)
- HIDS để phát hiện thay đổi files
- Tự động kiểm tra integrity
- Cảnh báo khi có thay đổi

**Cấu hình**: `/etc/aide/aide.conf`

**Sử dụng**:
```bash
# Kiểm tra integrity
aide --check

# Cập nhật baseline
aide --update
```

### 5. Tripwire
- HIDS khác với AIDE
- Phát hiện unauthorized changes
- Tạo báo cáo chi tiết

**Sử dụng**:
```bash
# Kiểm tra
tripwire --check

# Cập nhật
tripwire --update
```

### 6. AppArmor
- Mandatory Access Control (MAC)
- Giới hạn quyền của processes
- Profile cho từng app

**Sử dụng**:
```bash
# Kiểm tra status
aa-status

# Load profile
apparmor_parser -r /etc/apparmor.d/profile

# Đặt mode complain (chỉ log, không block)
aa-complain /etc/apparmor.d/profile

# Đặt mode enforce (block)
aa-enforce /etc/apparmor.d/profile
```

### 7. Audit Logging
- Ghi log mọi thay đổi files
- Sử dụng Linux Audit System
- Track ai ai đã làm gì

**Sử dụng**:
```bash
# Xem audit logs
ausearch -k app_changes

# Xem logs real-time
aureport -ts today
```

### Cấu hình
```yaml
install_app_hardening: true
app_hardening_enabled: true
app_hardening_immutable: true
app_hardening_integrity_check: true
app_hardening_snapshots: true
app_hardening_max_snapshots: 10
```

## Lớp 2B: Container Isolation

**Nhiệm vụ**: Chạy app trong container để cô lập khỏi host

### 1. Docker Container
- App chạy trong container riêng
- Cô lập khỏi host system
- Dễ dàng rebuild/redeploy

### 2. Read-only Root Filesystem
- Root filesystem chỉ đọc
- Chỉ có /tmp và /run là writable
- Ngăn chặn malware persist

### 3. Non-root User
- App chạy với user thường
- Không có quyền root
- Giảm thiểu damage nếu bị compromise

### 4. Resource Limits
- Giới hạn CPU
- Giới hạn Memory
- Ngăn chặn resource exhaustion

### 5. Seccomp Profile
- Giới hạn system calls
- Chỉ cho phép calls cần thiết
- Ngăn chặn privilege escalation

### 6. AppArmor for Docker
- Profile riêng cho container
- Giới hạn quyền container
- Ngăn chặn escape

### 7. Network Isolation
- Bridge network riêng
- Không truy cập host network
- Có thể thêm firewall rules

### Cấu hình
```yaml
install_container_isolation: true
container_monitor_enabled: true
docker_base_image: "python:3.9-slim"
container_cpu_limit: "1.0"
container_memory_limit: "512M"
container_subnet: "172.20.0.0/16"
container_uid: "1000"
container_gid: "1000"
```

### Sử dụng
```bash
# Build và chạy container
cd /opt/container-isolation
docker-compose up -d

# Xem logs
docker-compose logs -f

# Kiểm tra security
python3 /opt/container-isolation/monitor.py

# Xem container stats
docker stats

# Vào container (debug)
docker exec -it my-app-secure bash
```

## Lớp 3: AI Security Policy Enforcement

**Nhiệm vụ**: Giới hạn quyền của AI components

### 1. Read-only Mode
- AI chỉ được phép đọc
- Không được sửa files
- An toàn nhất

### 2. Forbidden Paths
- Chặn truy cập source code
- Chặn truy cập git repos
- Chặn truy cập config files

### 3. Forbidden Commands
- Chặn lệnh nguy hiểm (rm, git, npm install)
- Chỉ cho phép lệnh an toàn
- Exception cho AI Security Response

### 4. Approval Mechanism
- Yêu cầu phê duyệt cho hành động nguy hiểm
- AI Security Response không cần (nhiệm vụ chính)
- AI components khác cần phê duyệt

### 5. Audit Logging
- Ghi log mọi hành động của AI
- Review thường xuyên
- Traceback nếu có vấn đề

### Cấu hình
```yaml
ai_security:
  operation_mode: "read_only"
  forbidden_paths:
    - "/opt/apps/*/src"
    - "/opt/apps/*/app"
    - "/var/www/html"
  forbidden_commands:
    - "rm"
    - "git"
    - "npm install"
```

## Quy trình Deploy với Bảo mật Nhiều Lớp

### 1. Deploy
```bash
ansible-playbook -i inventory.ini playbook.yml -e @project-config.yml
```

### 2. Verify từng lớp

**Lớp 1 - AI Security Response**:
```bash
systemctl status ai-security-response
tail -f /opt/ai-security-response/logs/security_*.log
```

**Lớp 2A - App Hardening**:
```bash
systemctl status app-hardening
python3 /opt/app-hardening/hardener.py
ls -la /opt/app-integrity/
ls -la /opt/app-snapshots/
```

**Lớp 2B - Container Isolation**:
```bash
systemctl status container-monitor
docker ps
docker stats
python3 /opt/container-isolation/monitor.py
```

**Lớp 3 - AI Security Policy**:
```bash
cat /opt/ai-security/security-policy.yml
tail -f /var/log/ai-audit.log
```

## Scenario: AI có sai sót

### Kịch bản 1: AI Security Response block nhầm IP

**Lớp 1**: AI block IP
- IP bị block với iptables

**Lớp 2**: App vẫn hoạt động bình thường
- Code không bị ảnh hưởng
- Container vẫn chạy
- Integrity không bị thay đổi

**Khắc phục**:
```bash
# Unban IP
iptables -D INPUT -s <IP> -j DROP
# Hoặc
fail2ban-client set sshd unbanip <IP>
```

### Kịch bản 2: AI Healing restart service nhầm

**Lớp 1**: AI restart service
- Service bị restart

**Lớp 2**: Code được bảo vệ
- Code không bị sửa
- Integrity check sẽ phát hiện nếu có thay đổi
- Có thể restore từ snapshot

**Khắc phục**:
```bash
# Restore snapshot nếu cần
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.restore_snapshot('before-incident')"
```

### Kịch bản 3: AI bị compromise

**Lớp 1**: AI bị hack
- Attacker có thể điều khiển AI

**Lớp 2**: App vẫn được bảo vệ
- Code immutable (read-only)
- Container isolation
- AppArmor giới hạn quyền
- Attacker không thể sửa code

**Lớp 3**: AI Security Policy
- AI bị giới hạn quyền
- Không thể truy cập source code
- Không thể thực thi lệnh nguy hiểm
- Audit log track mọi hành động

**Khắc phục**:
```bash
# Stop AI components
systemctl stop ai-security-response
systemctl stop ai-healing

# Review audit logs
tail -f /var/log/ai-audit.log

# Isolate server nếu cần
ufw default deny incoming
ufw allow from <ADMIN_IP> to any port 22
```

## Best Practices

### 1. Production
- Bật tất cả các lớp bảo vệ
- Review logs thường xuyên
- Test restore procedures
- Keep snapshots updated
- Monitor resource usage

### 2. Development
- Có thể tắt một số lớp để debug
- Sử dụng threat level thấp hơn
- Test từng lớp riêng biệt
- Document mọi changes

### 3. Incident Response
1. Xác định lớp bị ảnh hưởng
2. Isolate nếu cần
3. Review audit logs
4. Restore từ snapshot
5. Patch vulnerability
6. Update baseline
7. Document incident

## Troubleshooting

### App Hardening không hoạt động
1. Kiểm tra service: `systemctl status app-hardening`
2. Kiểm tra permissions: `ls -la /opt/app-hardening/`
3. Kiểm tra logs: `journalctl -u app-hardening`

### Container không chạy
1. Kiểm tra Docker: `systemctl status docker`
2. Kiểm tra images: `docker images`
3. Kiểm tra logs: `docker-compose logs`
4. Kiểm tra seccomp/AppArmor: `docker inspect <container>`

### AI bị chặn quá nhiều
1. Review `ai-security-policy.yml`
2. Điều chỉnh `operation_mode`
3. Thêm exceptions nếu cần
4. Review audit logs

## Kết luận

Hệ thống bảo mật nhiều lớp đảm bảo rằng:
- **Lớp 1**: AI phát hiện và phản hồi tấn công nhanh
- **Lớp 2**: Code và app được bảo vệ ngay cả khi AI sai
- **Lớp 3**: AI bị giới hạn quyền để giảm thiểu damage

Nếu một lớp thất bại, các lớp khác vẫn bảo vệ hệ thống.
