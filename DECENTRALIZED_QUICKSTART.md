# Decentralized Neural Network Quickstart

Hướng dẫn nhanh để xây dựng mạng nơ-ron phân tán với fault tolerance.

## Cấu hình cho trường hợp của bạn

**Mục tiêu:** Hệ thống vẫn hoạt động ngay cả khi máy chủ không hoạt động

**Thành phần:**
- 1-2 Federated Learning Servers (có thể failover)
- Nhiều Federated Learning Clients (máy người dùng)
- Mesh Network kết nối tất cả nodes

## Bước 1: Cấu hình Inventory

Edit `inventory.ini`:

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

## Bước 2: Deploy Mesh Network

Tạo `project-config-mesh.yml`:

```yaml
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_wireguard_port: 51820
```

Deploy mesh network trên tất cả nodes:

```bash
ansible-playbook -i inventory.ini playbook.yml --limit mesh-nodes -e @project-config-mesh.yml
```

## Bước 3: Thu thập Public Keys

```bash
# Lấy public key từ mỗi node
ssh admin@192.168.1.100 "cat /etc/wireguard/publickey" > peer1.key
ssh admin@192.168.1.101 "cat /etc/wireguard/publickey" > peer2.key
ssh admin@192.168.1.200 "cat /etc/wireguard/publickey" > peer3.key
ssh admin@192.168.1.201 "cat /etc/wireguard/publickey" > peer4.key
ssh admin@192.168.1.202 "cat /etc/wireguard/publickey" > peer5.key
```

## Bước 4: Cấu hình Mesh Peers

Tạo `project-config-mesh-peers.yml` cho mỗi node:

**Node 1 (192.168.1.100):**
```yaml
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_node_name: "mesh-node-01"
mesh_wireguard_address: "10.0.0.1/24"
mesh_peers:
  - public_key: "peer2_key_here"
    endpoint: "192.168.1.101"
    allowed_ips: "10.0.0.2/32"
  - public_key: "peer3_key_here"
    endpoint: "192.168.1.200"
    allowed_ips: "10.0.0.10/32"
  - public_key: "peer4_key_here"
    endpoint: "192.168.1.201"
    allowed_ips: "10.0.0.11/32"
  - public_key: "peer5_key_here"
    endpoint: "192.168.1.202"
    allowed_ips: "10.0.0.12/32"
```

**Node 2 (192.168.1.101):**
```yaml
install_mesh_network: true
mesh_network_type: "wireguard"
mesh_node_name: "mesh-node-02"
mesh_wireguard_address: "10.0.0.2/24"
mesh_peers:
  - public_key: "peer1_key_here"
    endpoint: "192.168.1.100"
    allowed_ips: "10.0.0.1/32"
  - public_key: "peer3_key_here"
    endpoint: "192.168.1.200"
    allowed_ips: "10.0.0.10/32"
  # ... thêm các peers khác
```

Làm tương tự cho các nodes khác với mesh_wireguard_address khác nhau:
- Node 3: 10.0.0.10/24
- Node 4: 10.0.0.11/24
- Node 5: 10.0.0.12/24

## Bước 5: Re-deploy Mesh Network với Peers

```bash
ansible-playbook -i inventory.ini playbook.yml --limit mesh-nodes -e @project-config-mesh-peers.yml
```

## Bước 6: Kiểm tra Mesh Network

```bash
# Trên mỗi node
mesh-status

# Test connectivity
ping 10.0.0.1
ping 10.0.0.2
ping 10.0.0.10
```

## Bước 7: Deploy Federated Learning Servers

Tạo `project-config-fl-server.yml`:

```yaml
install_federated_learning: true
federated_node_type: "server"
federated_server_port: 8080
federated_num_rounds: 10
federated_min_clients: 2
federated_min_available_clients: 2
federated_fraction_fit: 1.0
```

Deploy:

```bash
ansible-playbook -i inventory.ini playbook.yml --limit federated-servers -e @project-config-fl-server.yml
```

## Bước 8: Deploy Federated Learning Clients

Tạo `project-config-fl-client-01.yml`:

```yaml
install_federated_learning: true
federated_node_type: "client"
federated_server_address: "10.0.0.1:8080"  # Mesh IP của server
federated_client_id: 1
federated_local_epochs: 5
federated_batch_size: 32
```

Tạo tương tự cho các clients khác với `federated_client_id` khác nhau (2, 3, ...).

Deploy:

```bash
ansible-playbook -i inventory.ini playbook.yml --limit fl-client-01 -e @project-config-fl-client-01.yml
ansible-playbook -i inventory.ini playbook.yml --limit fl-client-02 -e @project-config-fl-client-02.yml
ansible-playbook -i inventory.ini playbook.yml --limit fl-client-03 -e @project-config-fl-client-03.yml
```

## Bước 9: Kiểm tra Federated Learning

```bash
# Kiểm tra server
ssh admin@192.168.1.100 "systemctl status fl-server"
ssh admin@192.168.1.100 "tail -f /opt/federated-learning/logs/fl_server.log"

# Kiểm tra clients
ssh admin@192.168.1.200 "systemctl status fl-client"
ssh admin@192.168.1.200 "tail -f /opt/federated-learning/logs/fl_client.log"
```

## Bước 10: Test Fault Tolerance

### Test Server Down

```bash
# Stop server 1
ssh admin@192.168.1.100 "systemctl stop fl-server"

# Clients sẽ tự động reconnect đến server 2
# Hoặc server 2 sẽ tiếp tục aggregate

# Start server 1 lại
ssh admin@192.168.1.100 "systemctl start fl-server"
```

### Test Client Down

```bash
# Stop một client
ssh admin@192.168.1.200 "systemctl stop fl-client"

# Server sẽ tiếp tục với các clients khác
# Không ảnh hưởng đến global model

# Start client lại
ssh admin@192.168.1.200 "systemctl start fl-client"
```

### Test Mesh Network Node Down

```bash
# Stop mesh network trên một node
ssh admin@192.168.1.200 "systemctl stop wg-quick@wg0"

# Traffic sẽ tự động reroute qua các nodes khác
# Không có single point of failure

# Start lại
ssh admin@192.168.1.200 "systemctl start wg-quick@wg0"
```

## Cấu hình Failover Server

Để đảm bảo hệ thống luôn có server hoạt động, cấu hình 2 servers:

```yaml
# Server 1
federated_server_address: "10.0.0.1:8080"

# Server 2
federated_server_address: "10.0.0.2:8080"
```

Clients có thể cấu hình để tự động switch giữa servers:

```python
# Trong fl_client.py
servers = ["10.0.0.1:8080", "10.0.0.2:8080"]
for server in servers:
    try:
        fl.client.start_client(server_address=server, client=client)
        break
    except:
        continue
```

## Monitoring

### Script monitoring đơn giản

Tạo `/usr/local/bin/monitor-fl.sh`:

```bash
#!/bin/bash
echo "=== Federated Learning Status ==="
echo ""

# Check servers
for server in 192.168.1.100 192.168.1.101; do
    echo "Server $server:"
    ssh admin@$server "systemctl is-active fl-server" || echo "DOWN"
done

echo ""
echo "=== Mesh Network Status ==="
for node in 192.168.1.100 192.168.1.101 192.168.1.200 192.168.1.201 192.168.1.202; do
    echo "Node $node:"
    ssh admin@$node "wg show wg0 peer" || echo "DISCONNECTED"
done
```

## Troubleshooting

### Mesh Network không kết nối

```bash
# Kiểm tra WireGuard
wg show

# Kiểm tra firewall
ufw allow 51820/udp

# Kiểm tra IP forwarding
sysctl net.ipv4.ip_forward
```

### Federated Learning không aggregate

```bash
# Kiểm tra server logs
tail -f /opt/federated-learning/logs/fl_server.log

# Kiểm tra client logs
tail -f /opt/federated-learning/logs/fl_client.log

# Test connectivity
curl http://10.0.0.1:8080
```

## Ports Summary

| Port | Service | Protocol | Mô tả |
|------|---------|----------|-------|
| 51820 | WireGuard | UDP | Mesh network VPN |
| 8080 | Federated Learning | TCP | FL server/client |

## Next Steps

1. **Custom Model**: Thay thế SimpleModel với model của bạn
2. **Data Pipeline**: Implement data loading cho từng client
3. **Advanced Aggregation**: Sử dụng FedAvg, FedProx, v.v.
4. **Monitoring Dashboard**: Tích hợp với Grafana
5. **Auto-scaling**: Thêm/bớt clients dựa trên workload
