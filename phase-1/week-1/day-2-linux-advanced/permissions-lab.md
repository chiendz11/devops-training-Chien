# Part C - Permission Lab

## Mục tiêu

- Tạo thư mục `/tmp/shared-lab`.
- Group `devops` có quyền đọc và ghi.
- File mới tự inherit group `devops` nhờ setgid bit.
- File `secret.txt` chỉ owner có quyền theo permission cơ bản.
- User `labreader` được cấp ACL chỉ đọc file, không được ghi.

## 1. Tạo group devops

Kiểm tra group trước khi tạo để tránh lỗi `group already exists`:

```bash
getent group devops > /dev/null || sudo groupadd devops
```

Kiểm tra:

```bash
getent group devops
```

## 2. Tạo thư mục shared-lab

Dùng `mkdir -p` để không báo lỗi nếu thư mục đã tồn tại:

```bash
sudo mkdir -p /tmp/shared-lab
```

Đặt user hiện tại làm owner và group sở hữu là `devops`:

```bash
sudo chown "$USER":devops /tmp/shared-lab
```

Đặt permission `2770`:

```bash
sudo chmod 2770 /tmp/shared-lab
```

Trong đó:

- `2`: bật setgid bit để file mới inherit group `devops`.
- Owner có quyền `rwx`.
- Group có quyền `rwx`.
- Other không có quyền.

Kiểm tra:

```bash
ls -ld /tmp/shared-lab
```

Kết quả mong đợi:

```text
drwxrws--- ... devops ... /tmp/shared-lab
```

## 3. Kiểm tra inherit group devops

Tạo file kiểm thử:

```bash
touch /tmp/shared-lab/inherit-test.txt
```

Kiểm tra:

```bash
ls -l /tmp/shared-lab/inherit-test.txt
stat -c 'owner=%U group=%G' /tmp/shared-lab/inherit-test.txt
```

Kết quả mong đợi:

```text
group=devops
```

## 4. Tạo file secret.txt

Tạo file:

```bash
touch /tmp/shared-lab/secret.txt
```

Đặt permission để chỉ owner đọc và ghi:

```bash
chmod 600 /tmp/shared-lab/secret.txt
```

Kiểm tra:

```bash
ls -l /tmp/shared-lab/secret.txt
```

Kết quả mong đợi trước khi cấp ACL:

```text
-rw------- ... secret.txt
```

Ghi nội dung kiểm thử:

```bash
echo "This is secret data" > /tmp/shared-lab/secret.txt
```

## 5. Tạo user labreader

Kiểm tra user trước khi tạo để tránh lỗi `user already exists`:

```bash
id labreader > /dev/null 2>&1 || sudo useradd -m labreader
```

Kiểm tra:

```bash
id labreader
```

## 6. Cấp ACL chỉ đọc

Cho `labreader` quyền đi xuyên qua thư mục:

```bash
sudo setfacl -m u:labreader:--x /tmp/shared-lab
```

Cho `labreader` quyền đọc file, không có quyền ghi:

```bash
sudo setfacl -m u:labreader:r-- /tmp/shared-lab/secret.txt
```

Lưu ý:

```bash
u:labreader:--x
```

chỉ dùng cho thư mục để user có thể truy cập file bên trong.

```bash
u:labreader:r--
```

dùng cho `secret.txt` để user có thể đọc nhưng không thể sửa file.

## 7. Kiểm tra ACL

```bash
getfacl /tmp/shared-lab
getfacl /tmp/shared-lab/secret.txt
```

Kết quả cần có:

```text
# Thư mục
user:labreader:--x

# File secret.txt
user:labreader:r--
```

## 8. Kiểm tra quyền đọc và ghi

Kiểm tra `labreader` đọc được:

```bash
sudo -u labreader cat /tmp/shared-lab/secret.txt
```

Kết quả mong đợi:

```text
This is secret data
```

Kiểm tra `labreader` không ghi được:

```bash
sudo -u labreader sh -c \
  'echo "unauthorized change" >> /tmp/shared-lab/secret.txt'
```

Kết quả mong đợi:

```text
Permission denied
```

## 9. Cleanup

Xóa thư mục lab:

```bash
sudo rm -rf /tmp/shared-lab
```

Nếu `labreader` chỉ được tạo để làm bài:

```bash
sudo userdel -r labreader
```

Nếu group `devops` chỉ được tạo để làm bài:

```bash
sudo groupdel devops
```

Không xóa user hoặc group nếu chúng đang được sử dụng cho mục đích khác.
