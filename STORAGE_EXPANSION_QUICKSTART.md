# Storage Expansion - Quick Start

## Cấu Hình Cảnh Báo

```yaml
# Trong project-config.yml
storage_monitoring_enabled: true
storage_warning_threshold: 80  # Cảnh báo khi > 80%
storage_critical_threshold: 90  # Cảnh báo nghiêm trọng khi > 90%
storage_alert_email: "admin@example.com"

auto_archive_enabled: true
auto_archive_threshold: 85  # Archive khi > 85%
archive_target_disk: "archive"
```

## Workflow Khi Ổ Cứng Đầy

```
1. Monitoring phát hiện usage > 80%
   ↓
2. Gửi cảnh báo (email)
   ↓
3. Nếu usage > 85% → Auto-archive data cũ
   ↓
4. Nếu usage > 90% → Critical alert + Rebalance
   ↓
5. Nếu vẫn đầy → Cleanup data
   ↓
6. Nếu vẫn đầy → Cảnh báo admin thêm ổ cứng
   ↓
7. Admin thêm ổ cứng → Re-run Ansible
   ↓
8. Rebalance data sang ổ cứng mới
```

## Thêm Ổ Cứng Mới

### 1. Cài đặt vật lý

```bash
# Kiểm tra ổ cứng mới
lsblk
sudo fdisk -l /dev/sdf
```

### 2. Format và mount

```bash
# Format
sudo mkfs.xfs /dev/sdf1

# Tạo mount point
sudo mkdir -p /mnt/data-new

# Mount
sudo mount /dev/sdf1 /mnt/data-new

# Thêm vào fstab
echo "/dev/sdf1 /mnt/data-new xfs defaults,noatime 0 2" | sudo tee -a /etc/fstab

# Set permissions
sudo chown admin:admin /mnt/data-new
sudo chmod 755 /mnt/data-new
```

### 3. Cập nhật cấu hình

```yaml
# Thêm vào project-config.yml
storage_disks:
  - name: "new"
    device: "/dev/sdf1"
    mount_point: "/mnt/data-new"
    fstype: "xfs"
    disk_type: "SSD"
```

### 4. Re-run Ansible

```bash
ansible-playbook -i inventory.ini playbook.yml --tags data-storage -e @project-config.yml
```

## Scripts Có Sẵn

```bash
# Monitor storage (chạy mỗi 10 phút qua cron)
/opt/data-storage/monitor-disks.sh

# Auto-archive data cũ
/opt/data-storage/auto-archive.sh /mnt/data-primary

# Rebalance data giữa các ổ cứng
/opt/data-storage/rebalance-storage.sh

# Cleanup data không cần thiết
/opt/data-storage/cleanup-storage.sh
```

## LVM cho Flexible Storage

```bash
# Cài đặt LVM
sudo apt install lvm2

# Tạo physical volume
sudo pvcreate /dev/sdf1

# Tạo volume group
sudo vgcreate data_vg /dev/sdf1

# Tạo logical volume
sudo lvcreate -L 500G -n data_lv data_vg

# Mở rộng khi thêm ổ cứng mới
sudo pvcreate /dev/sdg1
sudo vgextend data_vg /dev/sdg1
sudo lvextend -L +500G /dev/data_vg/data_lv
sudo xfs_growfs /mnt/data-lvm
```

## Xem Logs

```bash
# Storage monitoring logs
tail -f /opt/data-storage/logs/storage-monitor.log

# Alert logs
tail -f /opt/data-storage/logs/storage-alerts.log

# Auto-archive logs
tail -f /opt/data-storage/logs/auto-archive.log

# Rebalance logs
tail -f /opt/data-storage/logs/rebalance.log
```

## Files Đã Tạo

- `STORAGE_EXPANSION_GUIDE.md` - Hướng dẫn chi tiết
- `roles/data-storage/tasks/main.yml` - Đã cập nhật với monitoring scripts
- `project-config.yml` - Đã thêm cấu hình monitoring & auto-archive
