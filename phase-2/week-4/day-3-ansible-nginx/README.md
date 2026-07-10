# Task: Ansible nginx role trên 2 Docker SSH host

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 4 / Day 3`
- **Branch**: `phase-2/week-4/day-3-ansible-nginx`
- **Submitted at**: `2026-07-09` (timezone +07)
- **Time spent**: `~3 giờ`

## 1. Mục tiêu

Thực hành Ansible cơ bản với inventory 2 host, playbook, role, template config và Ansible Vault. Lab dùng Docker container có SSH để giả lập 2 server rồi dùng role `nginx` cấu hình web server giống môi trường thật.

## 2. Cách chạy

Yêu cầu máy có Docker, Ansible, OpenSSH và openssl.

```bash
cd phase-2/week-4/day-3-ansible-nginx

# Arch Linux
sudo pacman -S ansible openssh openssl docker docker-compose

# Tạo SSH key local và 2 Docker SSH host
make up

# Kiểm tra Ansible SSH được vào 2 host
make ping

# Tạo self-signed cert và encrypt bằng ansible-vault
make cert

# Chạy playbook cài/cấu hình nginx
make apply

# Verify HTTP/HTTPS trên cả 2 host
make test

# Chạy lại để chứng minh idempotent
make idempotent
```

## 3. Kết quả

- `nginx1`: HTTP `http://127.0.0.1:8081`, HTTPS `https://127.0.0.1:8441`.
- `nginx2`: HTTP `http://127.0.0.1:8082`, HTTPS `https://127.0.0.1:8442`.
- Ansible SSH bằng private key `.ssh/ansible_lab`, container chỉ nhận public key.
- Role render config từ template và dùng cert/key lấy từ `vault/cert.yml`.
- Playbook chạy lại lần 2 không đổi state nếu cấu hình đã đúng.

## 4. Khó khăn & cách giải quyết

- Container không chạy systemd như VM thật → dùng `nginx`, `nginx -s reload` và `pgrep nginx` thay vì `systemctl`.
- Password SSH hard-code không an toàn → chuyển sang key pair local, private key bị `.gitignore`.
- Không muốn commit private key TLS → tạo cert local rồi encrypt bằng Ansible Vault, ignore file thật.
- SSH vào container local dễ bị host key warning → tắt strict host key checking trong inventory cho lab.

## 5. Reference

- [Ansible Inventory](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)
- [Ansible Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html)
- [Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [Nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)

## 6. Self-check

- [x] Có inventory 2 Docker SSH host.
- [x] SSH bằng private key/public key, không hard-code password.
- [x] Có role nginx, template config và handler reload.
- [x] Có Ansible Vault cho TLS cert/private key.
- [x] Có lệnh kiểm tra idempotent.
- [x] Không commit private key hoặc vault password thật.
