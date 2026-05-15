# Decentralized Neural Network Architecture

Kiến trúc mạng nơ-ron phân tán với fault tolerance - hệ thống vẫn hoạt động ngay cả khi máy chủ không hoạt động.

## Tổng quan

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

## Các thành phần

### 1. Federated Learning (Training phân tán)

**Mô hình hoạt động:**
- Mỗi client (máy người dùng) train model trên data local
- Server aggregate model updates từ các clients
- Global model được cập nhật và phân phối lại
- Data không bao giờ rời khỏi máy người dùng (privacy)

**Ưu điểm:**
- **Privacy**: Data stays on user devices
- **Fault Tolerance**: Nếu một client down, các client khác vẫn train
- **Scalable**: Thêm/bớt clients dynamically
- **Bandwidth Efficient**: Chỉ gửi model updates, không raw data

### 2. Mesh Network (P2P VPN)

**Mô hình hoạt động:**
- Tất cả nodes kết nối với nhau qua P2P network
- Không có single point of failure
- Auto-reconnect khi connection bị mất

**Ưu điểm:**
- **Decentralized**: Không cần central server
- **Resilient**: Tự động route khi một node down
- **Secure**: End-to-end encryption
- **Flexible**: Có thể thêm/bớt nodes bất cứ lúc nào

### 3. Ray Cluster (Distributed Computing)

**Mô hình hoạt động:**
- Distributed computing framework
- Auto load balancing giữa nodes
- Fault tolerance với automatic retry

**Ưu điểm:**
- **Scalable**: Horizontal scaling dễ dàng
- **Flexible**: Hỗ trợ nhiều loại workloads
- **Monitoring**: Dashboard tích hợp

## Cấu trúc hệ thống

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

### Cấu hình Federated Learning Server

**project-config-fl-server.yml:**
```yaml
# Federated Learning
install_federated_learning: true
federated_node_type: "server"
federated_server_port: 8080
federated_num_rounds: 10
federated_min_clients: 2
federated_min_available_clients: 2
federated_fraction_fit: 1.0

# Mesh Network
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_node_name: "fl-server-01"
mesh_wireguard_address: "10.0.0.1/24"
```

### Cấu hình Federated Learning Client

**project-config-fl-client.yml:**
```yaml
# Federated Learning
install_federated_learning: true
federated_node_type: "client"
federated_server_address: "10.0.0.1:8080"  # Mesh network IP
federated_client_id: 1
federated_local_epochs: 5
federated_batch_size: 32

# Mesh Network
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_node_name: "fl-client-01"
mesh_wireguard_address: "10.0.0.10/24"
```

### Cấu hình Mesh Network Peers

Sau khi deploy tất cả nodes, thu thập public keys và cập nhật:

```yaml
mesh_peers:
  - public_key: "peer1_public_key_here"
    endpoint: "192.168.1.100"
    allowed_ips: "10.0.0.1/32"
  - public_key: "peer2_public_key_here"
    endpoint: "192.168.1.101"
    allowed_ips: "10.0.0.2/32"
  - public_key: "peer3_public_key_here"
    endpoint: "192.168.1.200"
    allowed_ips: "10.0.0.10/32"
```

## Deploy

### Bước 1: Deploy Mesh Network trên tất cả nodes

```bash
# Deploy mesh network
ansible-playbook -i inventory.ini playbook.yml --limit mesh-nodes -e @project-config-mesh.yml
```

### Bước 2: Thu thập Public Keys

```bash
# Lấy public key từ mỗi node
ssh admin@192.168.1.100 "cat /etc/wireguard/publickey"
ssh admin@192.168.1.101 "cat /etc/wireguard/publickey"
ssh admin@192.168.1.200 "cat /etc/wireguard/publickey"
# ... tiếp tục với các nodes khác
```

### Bước 3: Cập nhật Mesh Peers

Cập nhật `mesh_peers` trong `project-config.yml` với public keys thu thập được.

### Bước 4: Re-deploy Mesh Network với Peers

```bash
ansible-playbook -i inventory.ini playbook.yml --limit mesh-nodes -e @project-config-mesh.yml
```

### Bước 5: Deploy Federated Learning Servers

```bash
ansible-playbook -i inventory.ini playbook.yml --limit federated-servers -e @project-config-fl-server.yml
```

### Bước 6: Deploy Federated Learning Clients

```bash
ansible-playbook -i inventory.ini playbook.yml --limit federated-clients -e @project-config-fl-client.yml
```

## Kiểm tra hệ thống

### Kiểm tra Mesh Network

```bash
# Trên mỗi node
mesh-status

# Hoặc manual
wg show
ping 10.0.0.1  # Ping peer trong mesh network
```

### Kiểm tra Federated Learning

```bash
# Kiểm tra server
ssh admin@192.168.1.100 "systemctl status fl-server"
ssh admin@192.168.1.100 "tail -f /opt/federated-learning/logs/fl_server.log"

# Kiểm tra client
ssh admin@192.168.1.200 "systemctl status fl-client"
ssh admin@192.168.1.200 "tail -f /opt/federated-learning/logs/fl_client.log"
```

### Kiểm tra Model Aggregation

```bash
# Xem round history
ssh admin@192.168.1.100 "cat /opt/federated-learning/models/round_history.json"

# Xem model checkpoints
ssh admin@192.168.1.100 "ls -lh /opt/federated-learning/models/"
```

## Fault Tolerance

### Khi Server Down

- Clients tự động reconnect khi server up lại
- Local models vẫn được train
- Không mất data hay progress

### Khi Client Down

- Server tiếp tục aggregate từ các clients khác
- Các clients khác không bị ảnh hưởng
- Client down có thể reconnect bất cứ lúc nào

### Khi Mesh Network Node Down

- Tự động reroute qua các nodes khác
- Không có single point of failure
- Auto-reconnect khi node up lại

## Scaling

### Thêm Server Mới

```ini
[federated-servers]
fl-server-01 ansible_host=192.168.1.100 ansible_user=admin
fl-server-02 ansible_host=192.168.1.101 ansible_user=admin
fl-server-03 ansible_host=192.168.1.102 ansible_user=admin  # Mới
```

Deploy server mới và thêm vào mesh network.

### Thêm Client Mới

```ini
[federated-clients]
fl-client-01 ansible_host=192.168.1.200 ansible_user=admin
fl-client-02 ansible_host=192.168.1.201 ansible_user=admin
fl-client-03 ansible_host=192.168.1.202 ansible_user=admin
fl-client-04 ansible_host=192.168.1.203 ansible_user=admin  # Mới
```

Deploy client mới với unique `federated_client_id`.

## Security

### 1. Mesh Network Security
- WireGuard: End-to-end encryption
- Tailscale: Zero-trust networking
- Regular key rotation

### 2. Federated Learning Security
- Secure aggregation (model updates encrypted)
- Client authentication
- Rate limiting

### 3. Network Security
- Firewall rules
- VPN encryption
- SSH key authentication

## Monitoring

### Mesh Network Monitoring
```bash
# WireGuard status
wg show

# Connectivity test
ping -c 10 10.0.0.1
```

### Federated Learning Monitoring
```bash
# Server logs
tail -f /opt/federated-learning/logs/fl_server.log

# Client logs
tail -f /opt/federated-learning/logs/fl_client.log

# Model checkpoints
ls -lh /opt/federated-learning/models/
```

## Troubleshooting

### Mesh Network không kết nối

```bash
# Kiểm tra WireGuard service
systemctl status wg-quick@wg0

# Kiểm tra firewall
ufw status
firewall-cmd --list-all

# Kiểm tra port
netstat -ulnp | grep 51820
```

### Federated Learning không aggregate

```bash
# Kiểm tra server connectivity
curl http://10.0.0.1:8080

# Kiểm tra client connection
tail -f /opt/federated-learning/logs/fl_client.log

# Kiểm tra số clients
curl http://10.0.0.1:8080/metrics
```

## Use Cases

1. **Healthcare**: Train model trên patient data mà không cần centralize
2. **Finance**: Fraud detection với data từ multiple banks
3. **IoT**: Train model trên edge devices
4. **Mobile**: Train model trên user phones
5. **Enterprise**: Collaborative AI giữa các departments/companies

**📖 Xem chi tiết:** [DECENTRALIZED_NEURAL_NETWORK.md](DECENTRALIZED_NEURAL_NETWORK.md)
**🚀 Quickstart:** [DECENTRALIZED_QUICKSTART.md](DECENTRALIZED_QUICKSTART.md)

---

## Auto Client Setup - Thiết lập tự động cho người dùng

Người dùng không cần cấu hình thủ công. Khi đăng ký tài khoản, hệ thống tự động xử lý tất cả.

### Flow Onboarding

```
User Đăng Ký
    ↓
Hệ thống tạo cấu hình tự động (VPN keys, FL config)
    ↓
Gửi link download installer cho user
    ↓
User chạy installer (1-click)
    ↓
Tự động cài đặt và kết nối
    ↓
Bắt đầu training model
```

### Cấu hình Auto Setup API

**project-config.yml:**
```yaml
install_auto_client_setup: true
auto_setup_api_port: 9000
mesh_server_endpoint: "192.168.1.100:51820"
mesh_server_public_key: "your_mesh_server_public_key"
fl_server_address: "10.0.0.1:8080"
```

**Deploy:**
```bash
ansible-playbook -i inventory.ini playbook.yml --limit allservers -e @project-config.yml
```

### Tích hợp vào hệ thống đăng ký

**Khi user đăng ký, gọi Auto Setup API:**

```python
import requests

def on_user_signup(user_id, email, device_name, os_type):
    response = requests.post(
        "http://your-server.com:9000/register",
        json={
            "user_id": user_id,
            "email": email,
            "device_name": device_name,
            "os_type": os_type  # windows, macos, linux
        }
    )
    
    config = response.json()
    
    # Gửi link web setup cho user
    web_setup_url = f"http://your-server.com:9000/web-setup/{config['client_id']}"
    
    return redirect(web_setup_url)
```

### Trải nghiệm người dùng

**Web-based Setup:**
1. User đăng ký → redirect đến web setup page
2. Page hiển thị 3 bước đơn giản:
   - Bước 1: Tải installer (1 click)
   - Bước 2: Chạy installer (double-click)
   - Bước 3: Hoàn tất (tự động)
3. Installer tự động cài đặt WireGuard, Python, FL client
4. User thấy "✅ Đã kết nối!"

**Installer tự động làm gì:**
- Cài đặt WireGuard VPN
- Configure VPN với keys đã tạo
- Install Python và packages
- Download Federated Learning client
- Configure và start client
- Connect to training server

**📖 Xem chi tiết:** [USER_ONBOARDING_GUIDE.md](USER_ONBOARDING_GUIDE.md)

## Next Steps

1. **Custom Model**: Thay thế SimpleModel với model của bạn
2. **Data Pipeline**: Implement data loading cho từng client
3. **Advanced Aggregation**: Sử dụng FedAvg, FedProx, v.v.
4. **Monitoring Dashboard**: Tích hợp với Grafana
5. **Auto-scaling**: Thêm/bớt clients dựa trên workload
