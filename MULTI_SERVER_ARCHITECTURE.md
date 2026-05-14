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
