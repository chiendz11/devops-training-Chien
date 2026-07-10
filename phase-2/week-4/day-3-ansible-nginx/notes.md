# Notes - Ansible nginx lab

## 1. Inventory 2 Docker SSH host

Lab này không dùng VM thật mà giả lập 2 server bằng Docker container.

- `nginx1` expose SSH ra port `2221`, HTTP `8081`, HTTPS `8441`.
- `nginx2` expose SSH ra port `2222`, HTTP `8082`, HTTPS `8442`.

Ansible vẫn SSH vào như server bình thường, chỉ khác là `ansible_host` đều là `127.0.0.1` và khác `ansible_port`.

Lab dùng SSH key thay vì password:

- Private key nằm ở `.ssh/ansible_lab` trên máy local.
- Public key `.ssh/ansible_lab.pub` được mount read-only vào container.
- Container copy public key vào `/home/ansible/.ssh/authorized_keys`.
- File `.ssh/` bị `.gitignore`, nên không commit private key lên Git.

## 2. Role nginx

Role `roles/nginx` làm các việc chính:

- Cài package `nginx`.
- Render file HTML từ template.
- Render virtual host config từ template.
- Copy TLS certificate/key từ Ansible Vault.
- Validate config bằng `nginx -t`.
- Reload nginx khi config thay đổi.

## 3. Template config

File `roles/nginx/templates/demo.conf.j2` dùng biến như:

- `nginx_server_name`
- `nginx_http_port`
- `nginx_https_port`
- `nginx_tls_cert_path`
- `nginx_tls_key_path`

Nhờ template, cùng một role có thể chạy cho nhiều host nhưng mỗi host vẫn có config riêng.

## 4. Vault/cert

Private key TLS không commit lên Git.

Script `scripts/generate-vault-cert.sh` tạo self-signed cert local rồi encrypt thành `vault/cert.yml` bằng `ansible-vault`.

Trong lab này password mặc định được ghi vào `vault/.vault-pass` để dễ reproduce, nhưng file này bị `.gitignore`.

## 5. Idempotent

Idempotent nghĩa là chạy playbook nhiều lần thì lần sau không thay đổi gì nếu server đã đúng trạng thái mong muốn.

Kiểm tra bằng:

```bash
make apply
make idempotent
```

Lần thứ hai nên có `changed=0`.
