# Kiến trúc Deploy cho Ứng dụng

## Tổng quan

Hỗ trợ 2 mô hình deploy:

### 1. Monolithic Architecture (Đơn giản)
- **App Servers**: UI + Logic cùng một server
- **Database Servers**: PostgreSQL/MySQL (có thể cùng server hoặc riêng)
- Phù hợp cho: PHP apps, Rails, Django, Express monolithic, v.v.

### 2. Multi-Server Architecture (Phức tạp)
- **Frontend Servers**: Chạy static files (React/Vue/Angular) với Nginx
- **Backend Servers**: Chạy API/Application logic
- **Database Servers**: PostgreSQL/MySQL
- **Cache Servers**: Redis
- **Load Balancer**: Phân phối traffic
- Phù hợp cho: SPA + API riêng biệt, microservices

---

## Monolithic Architecture (UI + Logic cùng server)

### Cấu trúc

```
┌─────────────────┐
│   App Server    │
│  (192.168.1.100)│
│                 │
│  ┌───────────┐  │
│  │   UI      │  │  Components + Views
│  │ (HTML/CSS)│  │
│  └───────────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │  Logic    │  │  Controllers/Services
│  │  (Server) │  │
│  └───────────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │ Database  │  │  (nếu cùng server)
│  └───────────┘  │
└─────────────────┘
         │
         │ (nếu database riêng)
         ▼
┌─────────────────┐
│  DB Server      │
│ (192.168.1.200) │
└─────────────────┘
```

### Cấu hình Inventory

```ini
[appservers]
app-01 ansible_host=192.168.1.100 ansible_user=admin
# app-02 ansible_host=192.168.1.101 ansible_user=admin  # Scale nếu cần

[dbservers]
db-master ansible_host=192.168.1.200 ansible_user=admin
```

### Cấu hình Project

```yaml
app_name: "my-app"
app_type: "nodejs"  # nodejs, python, php, go, java
app_framework: "express"  # express, flask, django, rails, laravel
project_path: "/opt/apps/my-app"
app_port: 3000

env_vars:
  NODE_ENV: "production"
  PORT: "3000"
  # Database riêng server
  DATABASE_URL: "postgresql://dbuser:password@192.168.1.200:5432/mydb"
  # Hoặc database local
  # DATABASE_URL: "postgresql://dbuser:password@localhost:5432/mydb"
```

### Deploy Commands

```bash
# Deploy tất cả
ansible-playbook -i inventory.ini playbook.yml

# Deploy chỉ app servers
ansible-playbook -i inventory.ini playbook.yml --limit appservers

# Deploy chỉ database servers
ansible-playbook -i inventory.ini playbook.yml --limit dbservers
```

### Các Framework phổ biến

**Node.js/Express (Monolithic)**:
- Components: Views (EJS/Pug/Handlebars) + Routes + Controllers
- File structure: `views/`, `routes/`, `controllers/`, `models/`

**Node.js/Express + React + TypeScript (Full-stack Monolithic)**:
- Components: React components (App.tsx, components/) + API routes (routes/) + Server (server.ts)
- File structure: `App.tsx`, `components/`, `hooks/`, `context/`, `routes/`, `server.ts`
- Build tool: Vite (vite.config.ts)
- Database: Prisma ORM (prisma/)
- Services: Firebase (firebase.ts, firebase-*.json)
- Cấu hình cần thiết:
  ```yaml
  app_type: "nodejs"
  app_framework: "express"
  use_typescript: true
  use_vite: true
  use_prisma: true
  use_firebase: true
  node_script: "server.ts"
  npm_build: true
  npm_build_command: "npm run build"
  use_ts_node: true
  prisma_generate: true
  prisma_migrate: true
  ```
- Environment variables cần thiết:
  ```yaml
  DATABASE_URL: "postgresql://user:password@host:5432/db"
  FIREBASE_API_KEY: "your-api-key"
  FIREBASE_PROJECT_ID: "your-project-id"
  FIREBASE_APP_ID: "your-app-id"
  ```

**Python/Django**:
- Components: Templates + Views + Models
- File structure: `templates/`, `views.py`, `models.py`

**PHP/Laravel**:
- Components: Blade templates + Controllers + Models
- File structure: `resources/views/`, `app/Http/Controllers/`

**Ruby on Rails**:
- Components: ERB templates + Controllers + Models
- File structure: `app/views/`, `app/controllers/`, `app/models/`

---

## Multi-Server Architecture (Frontend + Backend riêng biệt)

### Cấu trúc Server

```
                    ┌─────────────────┐
                    │   Load Balancer  │
                    │   (192.168.1.50) │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
      ┌───────▼──────┐ ┌─────▼──────┐ ┌────▼─────┐
      │  Frontend-01 │ │ Frontend-02│ │ Backend  │
      │ (192.168.1.100)│ │ (192.168.1.101)│ │ Servers  │
      └──────────────┘ └────────────┘ │ (192.168.1.110)│
                                      └─────┬─────┘
                                            │
                          ┌─────────────────┼─────────────────┐
                          │                 │                 │
                  ┌───────▼──────┐   ┌─────▼──────┐   ┌─────▼──────┐
                  │ DB Master    │   │ DB Slave   │   │ Redis      │
                  │ (192.168.1.200)│ │ (192.168.1.201)│ │ (192.168.1.210)│
                  └──────────────┘   └────────────┘   └────────────┘
```

## Cấu hình Inventory

File `inventory.ini` định nghĩa các server groups:

```ini
[frontends]
frontend-01 ansible_host=192.168.1.100 ansible_user=admin
frontend-02 ansible_host=192.168.1.101 ansible_user=admin

[backends]
backend-01 ansible_host=192.168.1.110 ansible_user=admin
backend-02 ansible_host=192.168.1.111 ansible_user=admin

[dbservers]
db-master ansible_host=192.168.1.200 ansible_user=admin
db-slave ansible_host=192.168.1.201 ansible_user=admin

[cacheservers]
redis-01 ansible_host=192.168.1.210 ansible_user=admin

[loadbalancers]
lb-01 ansible_host=192.168.1.50 ansible_user=admin
```

## Cấu hình Project

File `project-config.yml` chứa cấu hình chi tiết:

### Frontend Configuration
```yaml
frontend_name: "my-app-frontend"
frontend_path: "/opt/apps/my-app-frontend"
frontend_port: 80
frontend_repo: "https://github.com/yourusername/frontend-repo.git"
framework_type: "react"  # react, vue, angular, static
```

### Backend Configuration
```yaml
backend_name: "my-app-backend"
backend_path: "/opt/apps/my-app-backend"
backend_port: 3000
backend_repo: "https://github.com/yourusername/backend-repo.git"
backend_type: "nodejs"  # nodejs, python, go, java, php
```

### Environment Variables

**Backend** (kết nối đến các server khác):
```yaml
backend_env_vars:
  DATABASE_URL: "postgresql://dbuser:password@192.168.1.200:5432/mydb"
  REDIS_URL: "redis://192.168.1.210:6379"
  FRONTEND_URL: "http://192.168.1.100"
  BACKEND_URL: "http://192.168.1.110:3000"
```

**Frontend** (kết nối đến backend):
```yaml
frontend_env_vars:
  API_BASE_URL: "http://192.168.1.110:3000"
  # Hoặc qua load balancer: "http://192.168.1.50"
```

### Load Balancer Configuration
```yaml
loadbalancer_type: "nginx"
loadbalancer_port: 80
loadbalancer_backends:
  - name: "backend-01"
    host: "192.168.1.110"
    port: 3000
loadbalancer_frontends:
  - name: "frontend-01"
    host: "192.168.1.100"
    port: 80
```

## Deploy Commands

### Deploy tất cả servers
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### Deploy chỉ frontend servers
```bash
ansible-playbook -i inventory.ini playbook.yml --limit frontends
```

### Deploy chỉ backend servers
```bash
ansible-playbook -i inventory.ini playbook.yml --limit backends
```

### Deploy chỉ database servers
```bash
ansible-playbook -i inventory.ini playbook.yml --limit dbservers
```

### Deploy server cụ thể
```bash
ansible-playbook -i inventory.ini playbook.yml --limit backend-01
```

## Các Roles cần tạo

Để sử dụng kiến trúc này, bạn cần tạo các roles sau:

1. **loadbalancer**: Cấu hình Nginx/HAProxy
2. **frontend**: Deploy React/Vue/Angular app
3. **backend**: Deploy API application
4. **cache**: Cài đặt và cấu hình Redis
5. **deploy-frontend**: Deploy frontend từ Git
6. **deploy-backend**: Deploy backend từ Git
7. **deploy-frontend-local**: Deploy frontend từ local
8. **deploy-backend-local**: Deploy backend từ local

## Kết nối giữa các thành phần

### Frontend → Backend
Frontend gọi API thông qua:
- Trực tiếp: `http://192.168.1.110:3000`
- Qua Load Balancer: `http://192.168.1.50`

### Backend → Database
Backend kết nối database qua:
- `postgresql://dbuser:password@192.168.1.200:5432/mydb`

### Backend → Cache
Backend kết nối Redis qua:
- `redis://192.168.1.210:6379`

## Security Considerations

1. **SSH Keys**: Sử dụng SSH keys thay vì password
2. **Firewall**: Chỉ mở các port cần thiết giữa servers
3. **SSL/TLS**: Bật SSL cho load balancer
4. **Database Security**: Database chỉ chấp nhận kết nối từ backend servers
5. **Network Segmentation**: Đặt database và cache trong private network

## Scaling

### Horizontal Scaling
Thêm server mới vào inventory.ini:
```ini
[backends]
backend-01 ansible_host=192.168.1.110 ansible_user=admin
backend-02 ansible_host=192.168.1.111 ansible_user=admin  # Thêm mới
backend-03 ansible_host=192.168.1.112 ansible_user=admin  # Thêm mới
```

Cập nhật load balancer configuration trong project-config.yml:
```yaml
loadbalancer_backends:
  - name: "backend-01"
    host: "192.168.1.110"
    port: 3000
  - name: "backend-02"
    host: "192.168.1.111"
    port: 3000
  - name: "backend-03"
    host: "192.168.1.112"
    port: 3000
```

## Monitoring

Sử dụng các tools đã cài đặt:
- **Grafana + Prometheus**: Monitor metrics
- **Cockpit**: Web interface quản lý server
- **AI Security Response**: Auto-detect và response attacks

---

## GPU Computing - Kết nối GPU từ máy phụ

### Phương pháp 1: Ray Distributed Computing (Khuyên dùng)

Sử dụng Ray để phân phối tác vụ GPU tự động giữa các máy.

**Cấu trúc:**
```
Máy chủ chính (Head Node - 2 CPU, 256GB RAM)
    ↓ Ray Cluster
Máy phụ GPU (Worker Node - có GPU)
```

**Cấu hình Inventory:**
```ini
[ray-head]
head-node ansible_host=192.168.1.100 ansible_user=admin

[ray-workers]
gpu-worker-01 ansible_host=192.168.1.200 ansible_user=admin
```

**Cấu hình project-config.yml cho Head Node:**
```yaml
install_ray_cluster: true
ray_node_type: "head"
ray_cluster_name: "gpu-cluster"
ray_head_port: 6379
ray_dashboard_port: 8265
ray_cpu_resources: 2
ray_memory_resources: 256  # GB
```

**Cấu hình project-config.yml cho Worker Node (GPU):**
```yaml
install_ray_cluster: true
install_cuda: true
ray_node_type: "worker"
ray_head_address: "192.168.1.100"
ray_head_port: 6379
ray_worker_cpus: 4
ray_worker_gpus: 1
ray_worker_memory: 16
```

**Deploy:**
```bash
# Deploy head node
ansible-playbook -i inventory.ini playbook.yml --limit ray-head -e @project-config.yml

# Deploy worker node
ansible-playbook -i inventory.ini playbook.yml --limit ray-workers -e @project-config-worker.yml
```

**Sử dụng Ray từ máy chủ chính:**
```python
import ray

# Kết nối đến Ray cluster
ray.init(address="192.168.1.100:6379")

@ray.remote(num_gpus=1)
def train_on_gpu(data):
    import torch
    # Tác vụ GPU chạy trên máy phụ
    device = torch.device("cuda:0")
    model = YourModel().to(device)
    # ... training code
    return result

# Gọi từ máy chủ chính
result = train_on_gpu.remote(data)
print(ray.get(result))
```

**Truy cập Ray Dashboard:**
- URL: `http://192.168.1.100:8265`
- Xem cluster status, GPU usage, job progress

### Phương pháp 2: GPU API Service (REST API)

Tạo REST API trên máy GPU và gọi từ máy chính.

**Cấu trúc:**
```
Máy chủ chính (2 CPU, 256GB RAM)
    ↓ HTTP Request
Máy phụ GPU (GPU API Service)
```

**Cấu hình Inventory:**
```ini
[gpuservers]
gpu-server ansible_host=192.168.1.200 ansible_user=admin
```

**Cấu hình project-config.yml cho máy GPU:**
```yaml
install_gpu_api_service: true
install_cuda: true
gpu_api_port: 8000
gpu_api_memory_limit: "8G"
gpu_monitor_interval: 60
```

**Deploy:**
```bash
ansible-playbook -i inventory.ini playbook.yml --limit gpuservers -e @project-config-gpu.yml
```

**API Endpoints:**
- `GET /` - Service info
- `GET /health` - Health check
- `GET /gpu/info` - GPU information
- `POST /inference` - Run inference
- `POST /training` - Start training
- `POST /upload-model` - Upload model
- `GET /models` - List models

**Sử dụng từ máy chủ chính:**
```python
import requests
import json

# Health check
response = requests.get("http://192.168.1.200:8000/health")
print(response.json())

# GPU info
response = requests.get("http://192.168.1.200:8000/gpu/info")
print(response.json())

# Inference
data = {
    "model_name": "my_model",
    "input_data": {"tensor": [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]]}
}
response = requests.post("http://192.168.1.200:8000/inference", json=data)
print(response.json())

# Training
training_data = {
    "model_name": "my_model",
    "training_data": {"dataset": "path/to/data"},
    "epochs": 10,
    "batch_size": 32
}
response = requests.post("http://192.168.1.200:8000/training", json=training_data)
print(response.json())
```

**Upload model:**
```python
import requests

with open("model.pt", "rb") as f:
    response = requests.post(
        "http://192.168.1.200:8000/upload-model",
        files={"file": f},
        params={"model_name": "my_model.pt"}
    )
print(response.json())
```

### So sánh 2 phương pháp

| Tiêu chí | Ray Cluster | GPU API Service |
|----------|-------------|-----------------|
| **Độ phức tạp** | Trung bình | Đơn giản |
| **Tự động hóa** | Cao (auto load balancing) | Thấp (manual) |
| **Flexibility** | Cao (distributed computing) | Trung bình (REST API) |
| **Monitoring** | Dashboard tích hợp | Cần custom |
| **Khuyên dùng** | Distributed ML training | Simple inference |

### Cấu hình kết hợp cả 2 phương pháp

Bạn có thể dùng cả 2 phương pháp cùng lúc:

```ini
[ray-head]
head-node ansible_host=192.168.1.100 ansible_user=admin

[ray-workers]
gpu-worker-01 ansible_host=192.168.1.200 ansible_user=admin

[gpuservers]
gpu-server ansible_host=192.168.1.200 ansible_user=admin
```

**project-config.yml cho máy GPU:**
```yaml
# Ray Cluster
install_ray_cluster: true
install_cuda: true
ray_node_type: "worker"
ray_head_address: "192.168.1.100"

# GPU API Service
install_gpu_api_service: true
gpu_api_port: 8000
```

### Security cho GPU Computing

1. **Firewall**: Chỉ mở port cần thiết (6379, 8265, 8000)
2. **SSH Keys**: Sử dụng SSH keys thay vì password
3. **Network Segmentation**: Đặt GPU servers trong private network
4. **Authentication**: Thêm authentication cho GPU API Service
5. **Rate Limiting**: Giới hạn số request đến GPU API

---

## Decentralized Neural Network (Mạng nơ-ron phân tán)

Kiến trúc mạng nơ-ron phân tán với fault tolerance - hệ thống vẫn hoạt động ngay cả khi máy chủ không hoạt động.

### Tổng quan

```
┌─────────────────────────────────────────────────────────────┐
│                  Decentralized Neural Network                │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  User 1  │  │  User 2  │  │  User 3  │  │  User N  │  │
│  │ (Client) │  │ (Client) │  │ (Client) │  │ (Client) │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │              │              │              │         │
│       └──────────────┼──────────────┼──────────────┘         │
│                      │              │                        │
│              ┌───────▼──────┐       │                        │
│              │ Mesh Network │       │                        │
│              │  (WireGuard  │       │                        │
│              │   /Tailscale)│       │                        │
│              └───────┬──────┘       │                        │
│                      │              │                        │
│       ┌──────────────┼──────────────┼──────────────┐         │
│       │              │              │              │         │
│  ┌────▼────┐  ┌────▼────┐  ┌────▼────┐  ┌────▼────┐      │
│  │ Server 1│  │ Server 2│  │ Server 3│  │ Server N│      │
│  │ (FL Agg)│  │ (FL Agg)│  │ (FL Agg)│  │ (FL Agg)│      │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
│       │              │              │              │         │
│       └──────────────┼──────────────┼──────────────┘         │
│                      │              │                        │
│              ┌───────▼──────┐       │                        │
│              │  Global Model│       │                        │
│              │  Aggregation │       │                        │
│              └──────────────┘       │                        │
│                                      │                        │
└──────────────────────────────────────┘                        │
```

### Các thành phần chính

**1. Federated Learning (Training phân tán)**
- Mỗi client train model trên data local
- Server aggregate model updates
- Data không bao giờ rời khỏi máy người dùng (privacy)
- Fault tolerance: Nếu một client down, các client khác vẫn train

**2. Mesh Network (P2P VPN)**
- Tất cả nodes kết nối P2P
- Không có single point of failure
- Auto-reconnect khi connection bị mất
- End-to-end encryption

**3. Ray Cluster (Distributed Computing)**
- Distributed computing framework
- Auto load balancing
- Fault tolerance với automatic retry

### Cấu hình Inventory

```ini
[federated-servers]
fl-server-01 ansible_host=192.168.1.100 ansible_user=admin
fl-server-02 ansible_host=192.168.1.101 ansible_user=admin

[federated-clients]
fl-client-01 ansible_host=192.168.1.200 ansible_user=admin
fl-client-02 ansible_host=192.168.1.201 ansible_user=admin
fl-client-03 ansible_host=192.168.1.202 ansible_user=admin

[mesh-nodes]
mesh-node-01 ansible_host=192.168.1.100 ansible_user=admin
mesh-node-02 ansible_host=192.168.1.101 ansible_user=admin
mesh-node-03 ansible_host=192.168.1.200 ansible_user=admin
mesh-node-04 ansible_host=192.168.1.201 ansible_user=admin
mesh-node-05 ansible_host=192.168.1.202 ansible_user=admin
```

### Cấu hình project-config.yml

**Federated Learning Server:**
```yaml
install_federated_learning: true
federated_node_type: "server"
federated_server_port: 8080
federated_num_rounds: 10
federated_min_clients: 2
```

**Federated Learning Client:**
```yaml
install_federated_learning: true
federated_node_type: "client"
federated_server_address: "10.0.0.1:8080"
federated_client_id: 1
federated_local_epochs: 5
```

**Mesh Network:**
```yaml
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_wireguard_address: "10.0.0.1/24"
mesh_peers:
  - public_key: "peer_public_key"
    endpoint: "192.168.1.100"
    allowed_ips: "10.0.0.1/32"
```

### Deploy Commands

```bash
# Deploy mesh network
ansible-playbook -i inventory.ini playbook.yml --limit mesh-nodes -e @project-config-mesh.yml

# Deploy federated learning servers
ansible-playbook -i inventory.ini playbook.yml --limit federated-servers -e @project-config-fl-server.yml

# Deploy federated learning clients
ansible-playbook -i inventory.ini playbook.yml --limit federated-clients -e @project-config-fl-client.yml
```

### Fault Tolerance

**Khi Server Down:**
- Clients tự động reconnect khi server up lại
- Local models vẫn được train
- Không mất data hay progress

**Khi Client Down:**
- Server tiếp tục aggregate từ các clients khác
- Các clients khác không bị ảnh hưởng
- Client down có thể reconnect bất cứ lúc nào

**Khi Mesh Network Node Down:**
- Tự động reroute qua các nodes khác
- Không có single point of failure
- Auto-reconnect khi node up lại

### Use Cases

1. **Healthcare**: Train model trên patient data mà không cần centralize
2. **Finance**: Fraud detection với data từ multiple banks
3. **IoT**: Train model trên edge devices
4. **Mobile**: Train model trên user phones
5. **Enterprise**: Collaborative AI giữa các departments/companies

**📖 Xem chi tiết:** [DECENTRALIZED_NEURAL_NETWORK.md](DECENTRALIZED_NEURAL_NETWORK.md)
**🚀 Quickstart:** [DECENTRALIZED_QUICKSTART.md](DECENTRALIZED_QUICKSTART.md)
