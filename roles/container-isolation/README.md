# Container Isolation Role

## Mô tả

Container Isolation chạy app trong Docker container để cô lập khỏi host system (Lớp 2B trong hệ thống Defense in Depth).

## Nhiệm vụ

- Docker Container - App chạy trong container riêng
- Read-only Root - Filesystem chỉ đọc
- Non-root User - Không chạy với quyền root
- Resource Limits - Giới hạn CPU/Memory
- Seccomp/AppArmor - Giới hạn system calls
- Network Isolation - Mạng riêng cho container

## Các tính năng

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

## Cấu hình

### Variables

```yaml
install_container_isolation: true
container_monitor_enabled: true
docker_base_image: "python:3.9-slim"
container_cpu_limit: "1.0"
container_memory_limit: "512M"
container_cpu_reservation: "0.5"
container_memory_reservation: "256M"
container_subnet: "172.20.0.0/16"
container_uid: "1000"
container_gid: "1000"
```

### Dependencies

- Docker
- Docker Compose
- Python 3

## Cấu trúc thư mục

```
roles/container-isolation/
├── tasks/
│   └── main.yml
├── handlers/
│   └── main.yml
├── defaults/
│   └── main.yml
└── README.md
```

## Files được tạo

- `/opt/container-isolation/Dockerfile` - Dockerfile với security hardening
- `/opt/container-isolation/docker-compose.yml` - Docker Compose config
- `/opt/container-isolation/seccomp-profile.json` - Seccomp profile
- `/etc/apparmor.d/docker-default` - AppArmor profile cho Docker
- `/opt/container-isolation/monitor.py` - Container security monitor
- `/etc/systemd/system/container-monitor.service` - Systemd service

## Sử dụng

### Deploy với Ansible

```bash
ansible-playbook -i inventory.ini playbook.yml --tags container-isolation
```

### Kiểm tra service

```bash
systemctl status container-monitor
journalctl -u container-monitor -f
```

### Build và chạy container

```bash
cd /opt/container-isolation
docker-compose up -d
```

### Xem logs

```bash
docker-compose logs -f
docker logs <container_id>
```

### Kiểm tra security

```bash
python3 /opt/container-isolation/monitor.py
```

### Xem container stats

```bash
docker stats
docker ps
```

### Vào container (debug)

```bash
docker exec -it my-app-secure bash
```

### Stop và remove container

```bash
docker-compose down
```

### Rebuild container

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Security Features

### Dockerfile Security

```dockerfile
# Non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# Read-only filesystem (in docker-compose)
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

### Docker Compose Security

```yaml
# Drop all capabilities
cap_drop:
  - ALL
# Only add necessary capabilities
cap_add:
  - NET_BIND_SERVICE

# No privileged mode
privileged: false

# Read-only root filesystem
read_only: true
tmpfs:
  - /tmp
  - /run

# Resource limits
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M

# Non-root user
user: "1000:1000"

# Security options
security_opt:
  - no-new-privileges:true
  - apparmor=docker-default
  - seccomp=default.json
```

### Seccomp Profile

Giới hạn system calls mà container có thể thực hiện.

### AppArmor Profile

Giới hạn quyền của container với Mandatory Access Control.

## Monitoring

### Container Monitor Script

Kiểm tra:
- Resource usage (CPU, Memory)
- Privileged mode
- Capabilities
- Read-only root filesystem
- User running container

## Best Practices

1. Luôn chạy container với non-root user
2. Sử dụng read-only root filesystem
3. Giới hạn resources (CPU, Memory)
4. Sử dụng seccomp và AppArmor profiles
5. Network isolation với bridge network
6. Regular security scans
7. Keep images updated
8. Use specific image tags (not latest)
9. Scan images for vulnerabilities
10. Monitor container logs

## Troubleshooting

### Container không chạy
1. Kiểm tra Docker: `systemctl status docker`
2. Kiểm tra images: `docker images`
3. Kiểm tra logs: `docker-compose logs`
4. Kiểm tra seccomp/AppArmor: `docker inspect <container>`

### Resource limits không hoạt động
1. Kiểm tra Docker version (cần >= 1.20)
2. Kiểm tra cgroup v2 được enable
3. Kiểm tra docker-compose config

### AppArmor block container
1. Kiểm tra AppArmor status: `aa-status`
2. Đặt mode complain: `aa-complain /etc/apparmor.d/docker-default`
3. Review profile logs

## Xem thêm

- [MULTI_LAYER_SECURITY_GUIDE.md](../../MULTI_LAYER_SECURITY_GUIDE.md) - Hướng dẫn hệ thống bảo mật nhiều lớp
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
