# App Hardening Role

## Mô tả

App Hardening bảo vệ code và app với các rào chắn bảo mật (Lớp 2A trong hệ thống Defense in Depth).

## Nhiệm vụ

- Integrity Checking - Kiểm tra hash của files
- Immutable Filesystem - Làm code read-only
- Snapshots - Backup và rollback nhanh
- AIDE/Tripwire - HIDS phát hiện unauthorized changes
- AppArmor - Mandatory Access Control
- Audit Logging - Ghi log mọi thay đổi

## Các tính năng

### 1. Integrity Checking
- Tạo baseline hash cho tất cả files
- Kiểm tra integrity thường xuyên
- Phát hiện files bị sửa/xóa/thêm mới

### 2. Immutable Filesystem
- Làm code trở thành read-only
- Sử dụng `chattr +i` (Linux ext4/xfs)
- Ngăn chặn sửa code bất ngờ

### 3. Snapshots
- Tạo snapshots của code
- Restore nhanh khi có vấn đề
- Tự động cleanup snapshots cũ

### 4. AIDE (Advanced Intrusion Detection Environment)
- HIDS để phát hiện thay đổi files
- Tự động kiểm tra integrity
- Cảnh báo khi có thay đổi

### 5. Tripwire
- HIDS khác với AIDE
- Phát hiện unauthorized changes
- Tạo báo cáo chi tiết

### 6. AppArmor
- Mandatory Access Control (MAC)
- Giới hạn quyền của processes
- Profile cho từng app

### 7. Audit Logging
- Ghi log mọi thay đổi files
- Sử dụng Linux Audit System
- Track ai ai đã làm gì

## Cấu hình

### Variables

```yaml
install_app_hardening: true
app_hardening_enabled: true
app_hardening_immutable: true
app_hardening_integrity_check: true
app_hardening_snapshots: true
app_hardening_max_snapshots: 10
```

### Dependencies

- Python 3
- AIDE
- Tripwire
- AppArmor
- Auditd
- Chkrootkit
- Rkhunter

## Cấu trúc thư mục

```
roles/app-hardening/
├── tasks/
│   └── main.yml
├── handlers/
│   └── main.yml
├── defaults/
│   └── main.yml
└── README.md
```

## Files được tạo

- `/opt/app-hardening/hardener.py` - Script chính
- `/opt/app-backups/` - Backup directory
- `/opt/app-integrity/` - Integrity baseline files
- `/opt/app-snapshots/` - Snapshot directories
- `/etc/aide/aide.conf` - AIDE configuration
- `/etc/tripwire/twcfg.txt` - Tripwire configuration
- `/etc/systemd/system/app-hardening.service` - Systemd service

## Sử dụng

### Deploy với Ansible

```bash
ansible-playbook -i inventory.ini playbook.yml --tags app-hardening
```

### Kiểm tra service

```bash
systemctl status app-hardening
journalctl -u app-hardening -f
```

### Sử dụng hardener script

```bash
# Tạo integrity baseline
python3 /opt/app-hardening/hardener.py

# Kiểm tra integrity
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.verify_integrity()"

# Tạo snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.create_snapshot('before-update')"

# Liệt kê snapshots
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.list_snapshots()"

# Restore snapshot
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.restore_snapshot('before-update')"

# Làm code read-only
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.make_code_readonly()"

# Làm code writable
python3 -c "from app_hardening.hardener import AppHardener; h = AppHardener(); h.make_code_writable()"
```

### Sử dụng AIDE

```bash
# Kiểm tra integrity
aide --check

# Cập nhật baseline
aide --update

# Xem báo cáo
aide --compare
```

### Sử dụng Tripwire

```bash
# Kiểm tra
tripwire --check

# Cập nhật
tripwire --update

# Xem báo cáo
tripwire --report
```

### Sử dụng AppArmor

```bash
# Kiểm tra status
aa-status

# Load profile
apparmor_parser -r /etc/apparmor.d/profile

# Đặt mode complain
aa-complain /etc/apparmor.d/profile

# Đặt mode enforce
aa-enforce /etc/apparmor.d/profile
```

### Xem audit logs

```bash
# Xem audit logs
ausearch -k app_changes

# Xem logs real-time
aureport -ts today
```

## Best Practices

1. Luôn tạo integrity baseline sau mỗi deploy
2. Tạo snapshot trước khi update code
3. Review integrity violations thường xuyên
4. Test restore procedures
5. Giữ số lượng snapshots trong giới hạn
6. Monitor AIDE/Tripwire reports
7. Review audit logs thường xuyên

## Xem thêm

- [MULTI_LAYER_SECURITY_GUIDE.md](../../MULTI_LAYER_SECURITY_GUIDE.md) - Hướng dẫn hệ thống bảo mật nhiều lớp
