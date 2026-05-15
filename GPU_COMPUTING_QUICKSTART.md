# GPU Computing Quickstart Guide

Hướng dẫn nhanh để kết nối GPU từ máy phụ sang máy chủ chính.

## Cấu hình cho trường hợp của bạn

**Máy chủ chính:** 2 CPU, 256GB RAM, không GPU
**Máy phụ GPU:** Có GPU NVIDIA

### Bước 1: Cấu hình Inventory

Edit file `inventory.ini`:

```ini
[ray-head]
head-node ansible_host=192.168.1.100 ansible_user=admin

[ray-workers]
gpu-worker-01 ansible_host=192.168.1.200 ansible_user=admin

[gpuservers]
gpu-server ansible_host=192.168.1.200 ansible_user=admin
```

### Bước 2: Cấu hình cho máy chủ chính (Head Node)

Tạo file `project-config-head.yml`:

```yaml
# Ray Cluster Configuration
install_ray_cluster: true
ray_node_type: "head"
ray_cluster_name: "gpu-cluster"
ray_head_port: 6379
ray_dashboard_port: 8265
ray_cpu_resources: 2
ray_memory_resources: 256

# Tắt các services không cần thiết
install_cuda: false
install_gpu_api_service: false
```

### Bước 3: Cấu hình cho máy phụ GPU

Tạo file `project-config-gpu.yml`:

```yaml
# Ray Cluster Configuration
install_ray_cluster: true
install_cuda: true
ray_node_type: "worker"
ray_head_address: "192.168.1.100"
ray_head_port: 6379
ray_worker_cpus: 4
ray_worker_gpus: 1
ray_worker_memory: 16

# GPU API Service
install_gpu_api_service: true
gpu_api_port: 8000
gpu_api_memory_limit: "8G"
gpu_monitor_interval: 60

# CUDA Configuration
cuda_version: "12-1"
nvidia_driver_version: "535"
install_pytorch_cuda: true
cuda_version_short: "121"
```

### Bước 4: Deploy

```bash
# Deploy head node (máy chủ chính)
ansible-playbook -i inventory.ini playbook.yml --limit ray-head -e @project-config-head.yml

# Deploy worker node (máy phụ GPU)
ansible-playbook -i inventory.ini playbook.yml --limit ray-workers -e @project-config-gpu.yml
```

### Bước 5: Kiểm tra

**Kiểm tra Ray Dashboard:**
- Truy cập: `http://192.168.1.100:8265`
- Xem cluster status, worker nodes, GPU availability

**Kiểm tra GPU API Service:**
```bash
curl http://192.168.1.200:8000/health
curl http://192.168.1.200:8000/gpu/info
```

### Bước 6: Sử dụng

#### Sử dụng Ray (từ máy chủ chính)

```python
import ray

# Kết nối đến Ray cluster
ray.init(address="192.168.1.100:6379")

@ray.remote(num_gpus=1)
def train_on_gpu(data):
    import torch
    device = torch.device("cuda:0")
    # Training code ở đây
    return result

# Gọi function
result = train_on_gpu.remote(data)
print(ray.get(result))
```

#### Sử dụng GPU API Service (từ máy chủ chính)

```python
import requests

# Inference
data = {
    "model_name": "my_model",
    "input_data": {"tensor": [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]]}
}
response = requests.post("http://192.168.1.200:8000/inference", json=data)
print(response.json())
```

## Troubleshooting

### Ray không kết nối được

```bash
# Kiểm tra Ray service trên head node
ssh admin@192.168.1.100 "systemctl status ray-head"

# Kiểm tra Ray service trên worker node
ssh admin@192.168.1.200 "systemctl status ray-worker"

# Kiểm tra port
telnet 192.168.1.100 6379
```

### GPU API Service không hoạt động

```bash
# Kiểm tra GPU trên máy phụ
ssh admin@192.168.1.200 "nvidia-smi"

# Kiểm tra GPU API service
ssh admin@192.168.1.200 "systemctl status gpu-api"

# Xem logs
ssh admin@192.168.1.200 "tail -f /opt/gpu-api/logs/gpu-api.log"
```

### Firewall block

```bash
# Mở port trên Ubuntu
ufw allow 6379/tcp
ufw allow 8265/tcp
ufw allow 8000/tcp

# Mở port trên CentOS
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --permanent --add-port=8265/tcp
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload
```

## Ports Summary

| Port | Service | Server | Mô tả |
|------|---------|--------|-------|
| 6379 | Ray Head/Worker | Head + Worker | Ray cluster communication |
| 8265 | Ray Dashboard | Head | Ray web UI |
| 8000 | GPU API Service | GPU Server | REST API cho GPU |

## Next Steps

1. **Custom model loading**: Sửa `/opt/gpu-api/app/gpu_api_main.py` để load model của bạn
2. **Authentication**: Thêm API key authentication cho GPU API Service
3. **Monitoring**: Tích hợp với Grafana/Prometheus để monitor GPU usage
4. **Load balancing**: Thêm nhiều GPU workers để scale
