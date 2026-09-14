# app-code

Thư mục chứa cho mã nguồn ứng dụng khi dùng **deploy local**.

Trước đây `app-code` từng là gitlink/submodule trống — gây nhầm lẫn. Đây là thư mục hướng dẫn.

## Cách dùng

1. Clone hoặc copy code vào đây, ví dụ:
   ```bash
   git clone https://github.com/YOUR_ORG/YOUR_REPO.git app-code/
   ```
2. Trong `vars.yml`:
   ```yaml
   deploy_enabled: true
   deploy_method: local
   project_path: /opt/apps/my-app
   ```
3. Chạy:
   ```bash
   ansible-playbook -i inventory.ini playbook.yml --tags deploy,dependencies,application -e @vars.yml
   ```

## Lưu ý

- Không commit `.env`, key, hoặc mật khẩu thật.
- Role `deploy-local` (khi được dùng) sẽ đồng bộ từ máy control — xem tasks của role đó.
