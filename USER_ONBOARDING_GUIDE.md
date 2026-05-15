# User Onboarding Guide - Thiết lập tự động cho người dùng

Hướng dẫn tích hợp auto-setup vào hệ thống đăng ký của bạn.

## Tổng quan

Người dùng không cần cấu hình thủ công. Khi đăng ký tài khoản, hệ thống tự động:

1. ✅ Tạo cấu hình Mesh Network (VPN keys)
2. ✅ Tạo cấu hình Federated Learning Client
3. ✅ Tải installer phù hợp với OS của user
4. ✅ User chỉ cần chạy installer
5. ✅ Tự động kết nối và bắt đầu training

## Flow Onboarding

```
User Đăng Ký
    ↓
Hệ thống tạo cấu hình tự động
    ↓
Gửi link download installer cho user
    ↓
User chạy installer (1-click)
    ↓
Tự động cài đặt và kết nối
    ↓
Bắt đầu training model
```

## Cấu hình Server

### Bước 1: Deploy Auto Client Setup API

```bash
# Cấu hình project-config.yml
install_auto_client_setup: true
auto_setup_api_port: 9000
mesh_server_endpoint: "192.168.1.100:51820"
mesh_server_public_key: "your_mesh_server_public_key"
fl_server_address: "10.0.0.1:8080"

# Deploy
ansible-playbook -i inventory.ini playbook.yml --limit allservers -e @project-config.yml
```

### Bước 2: Lấy Mesh Server Public Key

```bash
# Trên mesh server
cat /etc/wireguard/publickey
```

Cập nhật vào `mesh_server_public_key` trong `project-config.yml`.

### Bước 3: Kiểm tra Auto Setup API

```bash
# Test API
curl http://192.168.1.100:9000/

# Kết quả:
# {"service": "Auto Client Setup API", "status": "running"}
```

## Tích hợp vào hệ thống đăng ký của bạn

### Option 1: API Integration

Khi user đăng ký trong app của bạn, gọi Auto Setup API:

```python
import requests

# Khi user đăng ký
def on_user_signup(user_id, email, device_name, os_type):
    # Gọi Auto Setup API
    response = requests.post(
        "http://your-server.com:9000/register",
        json={
            "user_id": user_id,
            "email": email,
            "device_name": device_name,
            "os_type": os_type,  # windows, macos, linux
            "device_info": {}
        }
    )
    
    config = response.json()
    
    # Gửi link download cho user
    download_url = f"http://your-server.com:9000/download/{config['client_id']}"
    web_setup_url = f"http://your-server.com:9000/web-setup/{config['client_id']}"
    
    # Gửi email hoặc hiển thị trong app
    send_email(
        to=email,
        subject="Federated Learning Client Setup",
        body=f"""
        Chào {email},
        
        Cảm ơn bạn đã đăng ký!
        
        Để bắt đầu training model, hãy:
        1. Truy cập: {web_setup_url}
        2. Tải installer
        3. Chạy installer
        
        Installer sẽ tự động cấu hình mọi thứ.
        
        Client ID của bạn: {config['client_id']}
        """
    )
    
    return config
```

### Option 2: Web-based Setup

Redirect user đến web setup page sau khi đăng ký:

```python
def on_user_signup(user_id, email, device_name, os_type):
    # Gọi Auto Setup API
    response = requests.post(
        "http://your-server.com:9000/register",
        json={
            "user_id": user_id,
            "email": email,
            "device_name": device_name,
            "os_type": os_type
        }
    )
    
    config = response.json()
    
    # Redirect user đến web setup page
    web_setup_url = f"http://your-server.com:9000/web-setup/{config['client_id']}"
    
    return redirect(web_setup_url)
```

### Option 3: Mobile App Integration

Trong mobile app, tích hợp auto-setup:

```javascript
// React Native / Flutter / Swift / Kotlin
async function onUserSignup(userId, email) {
  // Detect OS
  const os = Platform.OS; // 'ios' or 'android'
  
  // Gọi Auto Setup API
  const response = await fetch('http://your-server.com:9000/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      user_id: userId,
      email: email,
      device_name: DeviceInfo.getDeviceName(),
      os_type: os === 'ios' ? 'macos' : 'linux'
    })
  });
  
  const config = await response.json();
  
  // Hiển thị nút download installer
  showDownloadButton(config.download_url);
  
  // Hoặc auto-download và cài đặt
  if (os === 'android') {
    downloadAndInstall(config.download_url);
  }
}
```

## Trải nghiệm người dùng

### Web-based Setup (Khuyên dùng)

1. User đăng ký tài khoản
2. Redirect đến web setup page
3. Page hiển thị 3 bước đơn giản:
   - Bước 1: Tải installer (1 click)
   - Bước 2: Chạy installer (double-click)
   - Bước 3: Hoàn tất (tự động)
4. Installer tự động cài đặt và kết nối
5. User thấy thông báo "✅ Đã kết nối!"

### Mobile App Setup

1. User đăng ký trong app
2. App hiển thị "Bắt đầu Training" button
3. User tap button
4. App tự động download và cài đặt
5. App hiển thị progress bar
6. Hoàn tất và bắt đầu training

### Email-based Setup

1. User đăng ký
2. Nhận email với link setup
3. Click link → web setup page
4. Tải và chạy installer
5. Hoàn tất

## Installer làm gì?

Installer tự động:

### Windows
- Download WireGuard installer
- Cài đặt WireGuard
- Configure WireGuard với keys đã tạo
- Install Python
- Install Python packages (flower, flwr, torch)
- Download Federated Learning client
- Configure client
- Start client service
- Connect to training server

### macOS
- Install Homebrew (nếu chưa có)
- Install WireGuard qua Homebrew
- Configure WireGuard
- Install Python qua Homebrew
- Install Python packages
- Download Federated Learning client
- Configure client
- Start client service
- Connect to training server

### Linux
- Install WireGuard qua apt/yum
- Configure WireGuard
- Install Python3 và pip
- Install Python packages
- Download Federated Learning client
- Configure client
- Start client service
- Connect to training server

## Monitoring User Setup

### Kiểm tra trạng thái user

```python
# Kiểm tra xem user đã setup chưa
def check_user_status(client_id):
    response = requests.get(f"http://your-server.com:9000/status/{client_id}")
    return response.json()

# Kết quả:
# {
#   "client_id": "client_123_abc12345",
#   "status": "active",  # hoặc "pending"
#   "created_at": "2024-01-15T10:30:00",
#   "setup_completed_at": "2024-01-15T10:35:00"
# }
```

### Dashboard cho admin

Tạo dashboard để xem:

```python
# Lấy tất cả configs
import os
import json

configs_dir = "/opt/auto-client-setup/configs"
all_configs = []

for filename in os.listdir(configs_dir):
    if filename.endswith('.json'):
        with open(os.path.join(configs_dir, filename)) as f:
            config = json.load(f)
            all_configs.append(config)

# Hiển thị trong dashboard
for config in all_configs:
    print(f"User: {config['email']}")
    print(f"Client ID: {config['client_id']}")
    print(f"Status: {'Active' if config.get('setup_completed') else 'Pending'}")
    print(f"Created: {config['created_at']}")
    print("---")
```

## Security Considerations

### 1. Authentication cho Auto Setup API

Thêm authentication:

```python
# Trong auto_setup_api.py
from fastapi import HTTPException, Header

async def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != "{{ auto_setup_api_key }}":
        raise HTTPException(status_code=403, detail="Invalid API key")
    return x_api_key

@app.post("/register")
async def register_user(
    user: UserRegistration,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    # ... registration logic
```

### 2. Rate Limiting

Giới hạn số request:

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/register")
@limiter.limit("5/minute")
async def register_user(user: UserRegistration):
    # ... registration logic
```

### 3. Validate User Input

Validate email, device name, etc.:

```python
from pydantic import EmailStr

class UserRegistration(BaseModel):
    user_id: str
    email: EmailStr  # Validate email format
    device_name: str
    os_type: str  # windows, macos, linux
```

## Troubleshooting

### User không thể download installer

```bash
# Kiểm tra Auto Setup API
curl http://your-server.com:9000/

# Kiểm tra firewall
ufw status
firewall-cmd --list-all

# Kiểm tra logs
tail -f /opt/auto-client-setup/logs/auto_setup.log
```

### Installer không chạy

- Kiểm tra quyền execute: `chmod +x installer.sh`
- Kiểm tra OS detection
- Xem logs trong installer

### Client không kết nối được

```bash
# Kiểm tra WireGuard
wg show

# Kiểm tra Federated Learning client
systemctl status fl-client

# Kiểm tra logs
tail -f /opt/federated-learning/logs/fl_client.log
```

## Best Practices

1. **Send confirmation email**: Gửi email xác nhận sau khi setup thành công
2. **Provide support**: Link đến hướng dẫn troubleshooting
3. **Monitor setup rate**: Theo dõi tỷ lệ setup thành công
4. **A/B test**: Test các phương pháp onboarding khác nhau
5. **Collect feedback**: Hỏi user về trải nghiệm setup

## Next Steps

1. **Custom installer**: Tùy chỉnh installer theo nhu cầu
2. **Progress tracking**: Hiển thị progress real-time cho user
3. **Auto-update**: Client tự động update khi có version mới
4. **Telemetry**: Collect anonymous usage data
5. **Multi-language**: Hỗ trợ nhiều ngôn ngữ
