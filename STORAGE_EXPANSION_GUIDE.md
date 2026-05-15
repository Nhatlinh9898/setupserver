# Hướng Dẫn Xử Lý Ổ Cứng Đầy và Nâng Cấp Storage

## Tổng Quan

Khi ổ cứng đầy, server cần:
1. **Monitoring**: Cảnh báo khi dung lượng thấp
2. **Auto-archive**: Di chuyển data cũ sang ổ cứng khác
3. **Expansion**: Thêm ổ cứng mới
4. **Rebalance**: Phân phối lại data giữa các ổ cứng
5. **Cleanup**: Xóa data không cần thiết

## Cấu Hình Cảnh Báo

### Cập nhật `project-config.yml`

```yaml
# Storage Monitoring & Alerts
storage_monitoring_enabled: true
storage_warning_threshold: 80  # Cảnh báo khi > 80%
storage_critical_threshold: 90  # Cảnh báo nghiêm trọng khi > 90%
storage_alert_email: "admin@example.com"
storage_alert_webhook: "https://hooks.slack.com/..."  # Optional Slack webhook

# Auto-archive khi đầy
auto_archive_enabled: true
auto_archive_threshold: 85  # Archive khi > 85%
archive_target_disk: "archive"  # Archive sang ổ cứng nào
```

## Script Monitoring Ổ Cứng

Tạo script `/opt/data-storage/monitor-disks.sh`:

```bash
#!/bin/bash
# Storage Monitoring Script với Alerts

LOG_FILE="/opt/data-storage/logs/storage-monitor.log"
ALERT_LOG="/opt/data-storage/logs/storage-alerts.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Configuration
WARNING_THRESHOLD={{ storage_warning_threshold | default(80) }}
CRITICAL_THRESHOLD={{ storage_critical_threshold | default(90) }}

echo "[$DATE] Storage Monitoring Check" >> $LOG_FILE

# Check each storage disk
for mount in /mnt/data-*; do
    if [ -d "$mount" ]; then
        # Get usage percentage
        USAGE=$(df -h "$mount" | tail -1 | awk '{print $5}' | sed 's/%//')
        DISK_NAME=$(basename "$mount")
        
        echo "[$DATE] $DISK_NAME usage: $USAGE%" >> $LOG_FILE
        
        # Warning alert
        if [ $USAGE -ge $WARNING_THRESHOLD ] && [ $USAGE -lt $CRITICAL_THRESHOLD ]; then
            echo "[$DATE] WARNING: $DISK_NAME usage is $USAGE% (threshold: $WARNING_THRESHOLD%)" >> $ALERT_LOG
            # Send email alert
            echo "WARNING: $DISK_NAME usage is $USAGE%" | mail -s "Storage Alert: $DISK_NAME" {{ storage_alert_email }}
            
            # Send Slack webhook (if configured)
            if [ -n "{{ storage_alert_webhook | default('') }}" ]; then
                curl -X POST -H 'Content-type: application/json' \
                    --data "{\"text\":\"⚠️ WARNING: $DISK_NAME usage is $USAGE%\"}" \
                    {{ storage_alert_webhook }}
            fi
        fi
        
        # Critical alert
        if [ $USAGE -ge $CRITICAL_THRESHOLD ]; then
            echo "[$DATE] CRITICAL: $DISK_NAME usage is $USAGE% (threshold: $CRITICAL_THRESHOLD%)" >> $ALERT_LOG
            # Send critical alert
            echo "CRITICAL: $DISK_NAME usage is $USAGE%" | mail -s "CRITICAL Storage Alert: $DISK_NAME" {{ storage_alert_email }}
            
            # Trigger auto-archive
            if [ "{{ auto_archive_enabled | default(false) }}" == "true" ]; then
                echo "[$DATE] Triggering auto-archive for $DISK_NAME" >> $LOG_FILE
                /opt/data-storage/auto-archive.sh "$DISK_NAME"
            fi
        fi
    fi
done

echo "[$DATE] Storage monitoring completed" >> $LOG_FILE
```

## Auto-Archive Data Cũ

Tạo script `/opt/data-storage/auto-archive.sh`:

```bash
#!/bin/bash
# Auto-archive script - Di chuyển data cũ sang ổ cứng archive

SOURCE_DISK=$1
LOG_FILE="/opt/data-storage/logs/auto-archive.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

if [ -z "$SOURCE_DISK" ]; then
    echo "[$DATE] Error: No source disk specified" >> $LOG_FILE
    exit 1
fi

ARCHIVE_DISK="{{ archive_target_disk | default('archive') }}"
ARCHIVE_DAYS={{ archive_after_days | default(90) }}

echo "[$DATE] Auto-archive started for $SOURCE_DISK" >> $LOG_FILE

# Archive data older than X days
if [ -d "$SOURCE_DISK/data" ] && [ -d "/mnt/data-$ARCHIVE_DISK/data" ]; then
    echo "[$DATE] Archiving data older than $ARCHIVE_DAYS days" >> $LOG_FILE
    
    # Find and move old files
    find "$SOURCE_DISK/data" -type f -mtime +$ARCHIVE_DAYS -print0 | while IFS= read -r -d '' file; do
        # Get relative path
        rel_path="${file#$SOURCE_DISK/data/}"
        target_dir="/mnt/data-$ARCHIVE_DISK/data/$(dirname "$rel_path")"
        
        # Create target directory if needed
        mkdir -p "$target_dir"
        
        # Move file
        mv "$file" "$target_dir/"
        echo "[$DATE] Archived: $rel_path" >> $LOG_FILE
    done
    
    echo "[$DATE] Auto-archive completed for $SOURCE_DISK" >> $LOG_FILE
else
    echo "[$DATE] Error: Source or archive directory not found" >> $LOG_FILE
    exit 1
fi
```

## Thêm Ổ Cứng Mới

### Bước 1: Cài đặt ổ cứng vật lý

1. Tắt server và cắm ổ cứng mới
2. Boot server và kiểm tra ổ cứng mới:

```bash
# Liệt kê tất cả disks
lsblk

# Kiểm tra disk mới (ví dụ /dev/sdf)
sudo fdisk -l /dev/sdf
```

### Bước 2: Format và Mount Ổ Cứng Mới

```bash
# Format disk (xfs cho SSD/NVMe, ext4 cho HDD)
sudo mkfs.xfs /dev/sdf1
# Hoặc
sudo mkfs.ext4 /dev/sdf1

# Tạo mount point
sudo mkdir -p /mnt/data-new

# Mount disk
sudo mount /dev/sdf1 /mnt/data-new

# Thêm vào /etc/fstab để auto-mount
echo "/dev/sdf1 /mnt/data-new xfs defaults,noatime 0 2" | sudo tee -a /etc/fstab

# Set permissions
sudo chown {{ app_user | default('admin') }}:{{ app_user | default('admin') }} /mnt/data-new
sudo chmod 755 /mnt/data-new

# Tạo data directory
sudo -u {{ app_user | default('admin') }} mkdir -p /mnt/data-new/data
```

### Bước 3: Cập nhật Cấu Hình

Thêm ổ cứng mới vào `project-config.yml`:

```yaml
storage_disks:
  # ... các ổ cứng cũ ...
  
  - name: "new"
    device: "/dev/sdf1"
    mount_point: "/mnt/data-new"
    fstype: "xfs"
    format: false
    mount_options: "defaults,noatime"
    disk_type: "SSD"
    is_primary: false
    is_hot_swap: true
```

### Bước 4: Re-run Ansible

```bash
ansible-playbook -i inventory.ini playbook.yml --tags data-storage -e @project-config.yml
```

## Rebalance Data Giữa Các Ổ Cứng

Tạo script `/opt/data-storage/rebalance-storage.sh`:

```bash
#!/bin/bash
# Rebalance storage - Phân phối lại data giữa các ổ cứng

LOG_FILE="/opt/data-storage/logs/rebalance.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Storage rebalance started" >> $LOG_FILE

# Get all storage disks
DISKS=($(ls -d /mnt/data-* 2>/dev/null))

if [ ${#DISKS[@]} -lt 2 ]; then
    echo "[$DATE] Need at least 2 disks for rebalancing" >> $LOG_FILE
    exit 1
fi

# Find disk with highest usage
MAX_USAGE=0
MAX_DISK=""
for disk in "${DISKS[@]}"; do
    USAGE=$(df -h "$disk" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -gt $MAX_USAGE ]; then
        MAX_USAGE=$USAGE
        MAX_DISK=$disk
    fi
done

echo "[$DATE] Highest usage disk: $MAX_DISK ($MAX_USAGE%)" >> $LOG_FILE

# Find disk with lowest usage
MIN_USAGE=100
MIN_DISK=""
for disk in "${DISKS[@]}"; do
    USAGE=$(df -h "$disk" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $USAGE -lt $MIN_USAGE ]; then
        MIN_USAGE=$USAGE
        MIN_DISK=$disk
    fi
done

echo "[$DATE] Lowest usage disk: $MIN_DISK ($MIN_USAGE%)" >> $LOG_FILE

# Move files from high usage to low usage disk
if [ -d "$MAX_DISK/data" ] && [ -d "$MIN_DISK/data" ]; then
    # Move recent files (last 30 days)
    find "$MAX_DISK/data" -type f -mtime -30 -print0 | while IFS= read -r -d '' file; do
        rel_path="${file#$MAX_DISK/data/}"
        target_dir="$MIN_DISK/data/$(dirname "$rel_path")"
        
        mkdir -p "$target_dir"
        mv "$file" "$target_dir/"
        echo "[$DATE] Moved: $rel_path from $MAX_DISK to $MIN_DISK" >> $LOG_FILE
    done
    
    echo "[$DATE] Rebalance completed" >> $LOG_FILE
fi
```

## LVM (Logical Volume Manager) cho Flexible Storage

### Cài đặt LVM

```bash
# Cài đặt LVM
sudo apt install lvm2

# Tạo physical volume
sudo pvcreate /dev/sdf1

# Tạo volume group
sudo vgcreate data_vg /dev/sdf1

# Tạo logical volume
sudo lvcreate -L 500G -n data_lv data_vg

# Format
sudo mkfs.xfs /dev/data_vg/data_lv

# Mount
sudo mkdir -p /mnt/data-lvm
sudo mount /dev/data_vg/data_lv /mnt/data-lvm
```

### Mở rộng LVM khi thêm ổ cứng mới

```bash
# Thêm physical volume mới
sudo pvcreate /dev/sdg1

# Mở rộng volume group
sudo vgextend data_vg /dev/sdg1

# Mở rộng logical volume
sudo lvextend -L +500G /dev/data_vg/data_lv

# Resize filesystem (xfs)
sudo xfs_growfs /mnt/data-lvm

# Hoặc (ext4)
sudo resize2fs /dev/data_vg/data_lv
```

## Ansible Tasks cho Storage Expansion

Cập nhật `roles/data-storage/tasks/main.yml`:

```yaml
- name: Check disk usage
  shell: df -h /mnt/data-* | tail -n +2 | awk '{print $5}' | sed 's/%//'
  register: disk_usage
  when: data_storage_enabled | default(false)

- name: Alert if disk usage is high
  debug:
    msg: "WARNING: Disk usage is {{ item }}%"
  loop: "{{ disk_usage.stdout_lines }}"
  when: 
    - data_storage_enabled | default(false)
    - item | int > storage_warning_threshold | default(80)

- name: Trigger auto-archive if critical
  command: /opt/data-storage/auto-archive.sh "{{ item }}"
  loop: "{{ disk_usage.stdout_lines }}"
  when: 
    - data_storage_enabled | default(false)
    - item | int > storage_critical_threshold | default(90)
    - auto_archive_enabled | default(false)

- name: Setup new disk if specified
  block:
    - name: Format new disk
      filesystem:
        fstype: "{{ item.fstype }}"
        dev: "{{ item.device }}"
      loop: "{{ storage_disks }}"
      when: item.format | default(false)
    
    - name: Create mount point for new disk
      file:
        path: "{{ item.mount_point }}"
        state: directory
        mode: '0755'
      loop: "{{ storage_disks }}"
    
    - name: Mount new disk
      mount:
        path: "{{ item.mount_point }}"
        src: "{{ item.device }}"
        fstype: "{{ item.fstype }}"
        opts: "{{ item.mount_options | default('defaults,noatime') }}"
        state: mounted
      loop: "{{ storage_disks }}"
    
    - name: Add to fstab
      lineinfile:
        path: /etc/fstab
        line: "{{ item.device }} {{ item.mount_point }} {{ item.fstype }} {{ item.mount_options | default('defaults,noatime') }} 0 2"
        state: present
      loop: "{{ storage_disks }}"
  when: data_storage_enabled | default(false)
```

## Cleanup Data Không Cần Thiết

### Script Cleanup Thông Minh

```bash
#!/bin/bash
# Smart cleanup script

LOG_FILE="/opt/data-storage/logs/cleanup.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Smart cleanup started" >> $LOG_FILE

# 1. Delete temporary files
find /mnt/data-* -name "*.tmp" -mtime +1 -delete
find /mnt/data-* -name "*.temp" -mtime +1 -delete

# 2. Delete old logs (> 30 days)
find /opt/data-storage/logs -name "*.log" -mtime +30 -delete

# 3. Delete old versions (> retention period)
for mount in /mnt/data-*; do
    if [ -d "$mount/versions" ]; then
        find "$mount/versions" -type f -mtime +{{ keep_versions_for_days | default(365) }} -delete
    fi
done

# 4. Delete duplicate files (based on checksum)
# Cần install fdupes trước
sudo apt install fdupes
for mount in /mnt/data-*; do
    if [ -d "$mount/data" ]; then
        fdupes -r -d -N "$mount/data"
    fi
done

# 5. Compress old text files
find /mnt/data-*/data -type f -mtime +30 \( -name "*.txt" -o -name "*.log" -o -name "*.json" \) -exec gzip {} \;

echo "[$DATE] Smart cleanup completed" >> $LOG_FILE
```

## Monitoring Dashboard

### Grafana Dashboard cho Storage

Tạo dashboard trong Grafana để monitor storage:

```json
{
  "dashboard": {
    "title": "Storage Monitoring",
    "panels": [
      {
        "title": "Disk Usage",
        "targets": [
          {
            "expr": "node_filesystem_size_bytes{mountpoint=~\"/mnt/data-.*\"}"
          }
        ]
      },
      {
        "title": "Disk Free Space",
        "targets": [
          {
            "expr": "node_filesystem_avail_bytes{mountpoint=~\"/mnt/data-.*\"}"
          }
        ]
      },
      {
        "title": "Disk I/O",
        "targets": [
          {
            "expr": "rate(node_disk_io_time_seconds_total[5m])"
          }
        ]
      }
    ]
  }
}
```

## Workflow Khi Ổ Cứng Đầy

### Quy trình xử lý tự động

```
1. Monitoring phát hiện usage > 80%
   ↓
2. Gửi cảnh báo (email/Slack)
   ↓
3. Nếu usage > 85% → Auto-archive data cũ
   ↓
4. Nếu usage > 90% → Critical alert + Rebalance
   ↓
5. Nếu vẫn đầy → Cleanup data không cần thiết
   ↓
6. Nếu vẫn đầy → Cảnh báo admin thêm ổ cứng
   ↓
7. Admin thêm ổ cứng mới → Re-run Ansible
   ↓
8. Rebalance data sang ổ cứng mới
```

### Quy trình thủ công

```bash
# 1. Kiểm tra usage
df -h

# 2. Archive data cũ
sudo /opt/data-storage/auto-archive.sh /mnt/data-primary

# 3. Cleanup
sudo /opt/data-storage/cleanup-storage.sh

# 4. Nếu vẫn đầy, thêm ổ cứng mới
# (xem phần "Thêm Ổ Cứng Mới" ở trên)

# 5. Rebalance
sudo /opt/data-storage/rebalance-storage.sh
```

## Best Practices

1. **Monitor thường xuyên**: Setup alerts ở 80% và 90%
2. **Archive tự động**: Di chuyển data cũ sang ổ cứng rẻ hơn
3. **Cleanup định kỳ**: Xóa temp files, old logs, duplicates
4. **LVM cho flexibility**: Dùng LVM để dễ mở rộng
5. **RAID cho reliability**: Dùng RAID cho data quan trọng
6. **Backup trước khi thao tác**: Luôn backup trước khi rebalance
7. **Test restore**: Định kỳ test restore từ backup
8. **Document changes**: Ghi log mọi thay đổi storage

## Troubleshooting

### Không thể mount ổ cứng mới

```bash
# Check disk status
lsblk
sudo fdisk -l

# Check filesystem type
sudo blkid /dev/sdf1

# Manual mount với debug
sudo mount -v /dev/sdf1 /mnt/data-new
```

### Rebalance bị lỗi

```bash
# Check permissions
ls -la /mnt/data-*

# Fix permissions
sudo chown -R admin:admin /mnt/data-*/data

# Check disk space
df -h
```

### LVM không mở rộng được

```bash
# Check volume group
sudo vgs

# Check physical volumes
sudo pvs

# Check logical volumes
sudo lvs

# Extend step by step
sudo vgextend data_vg /dev/sdg1
sudo lvextend -L +500G /dev/data_vg/data_lv
sudo xfs_growfs /mnt/data-lvm
```
