# Part C — Docker Network & Volume

## 1. Tạo bridge network và kết nối hai container

### Bridge network là gì?

Bridge network là một mạng ảo nằm trên Docker host. Các container trong cùng một user-defined bridge network có thể:

- Giao tiếp với nhau bằng IP nội bộ.
- Gọi nhau bằng container name nhờ DNS nội bộ của Docker.
- Không cần publish port ra host nếu chỉ giao tiếp container-to-container.

Em tạo network tên `demo-net`:

```bash
docker network create demo-net
```

Output:

```text
<network-id>
```

Kiểm tra network:

```bash
docker network ls
```

Output:

```text
NETWORK ID     NAME       DRIVER    SCOPE
<network-id>   demo-net   bridge    local
```

Ảnh minh chứng: [create-demo-net.png](./screenshots/create-demo-net.png).

### Chạy hai container trong cùng network

Trước đó em đã build image:

```bash
docker build -t demo-app:1.0.0 .
```

Chạy hai container:

```bash
docker run -d \
  --name app1 \
  --network demo-net \
  -e NAME=app1 \
  demo-app:1.0.0

docker run -d \
  --name app2 \
  --network demo-net \
  -e NAME=app2 \
  demo-app:1.0.0
```

Kiểm tra:

```bash
docker ps
```

Output chính:

```text
NAMES   IMAGE            STATUS                 NETWORKS
app2    demo-app:1.0.0   Up ... (healthy)       demo-net
app1    demo-app:1.0.0   Up ... (healthy)       demo-net
```

Ảnh minh chứng: [run-2-container.png](./screenshots/run-2-container.png).

Image `node:20-alpine` không có sẵn `curl`, nên lần đầu em chạy:

```bash
docker exec app1 curl http://app2:3000
```

thì gặp lỗi:

```text
exec: "curl": executable file not found in $PATH
```

Em cài tạm `curl` vào writable layer của container `app1`:

```bash
docker exec -u root app1 \
  apk add --no-cache curl
```

Sau đó gọi `app2` từ `app1`:

```bash
docker exec app1 \
  curl -s http://app2:3000
```

Output:

```json
{"msg":"hello from app2","ts":1782061873047}
```

Ảnh minh chứng: [curl app2 từ app1](./screenshots/curl-image-missing-fix-and-curl-app2%3A3000.png).

Ở đây `app2` không phải hostname được khai báo trong `/etc/hosts`. Docker DNS tự phân giải tên container `app2` thành IP của container trong `demo-net`.

Kiểm tra các container trong network:

```bash
docker network inspect demo-net \
  --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'
```

Output của em:

```text
postgres-demo 172.18.0.4/16
app2 172.18.0.3/16
app1 172.18.0.2/16
```

Hai app không cần dùng `-p 3000:3000` vì chúng giao tiếp bên trong Docker network qua container port `3000`. `-p` chỉ cần khi host hoặc client bên ngoài Docker cần truy cập container.

## 2. PostgreSQL với named volume

### Named volume là gì?

Filesystem bên trong container có tính tạm thời. Nếu dữ liệu chỉ nằm trong writable layer của container thì khi xóa container, dữ liệu đó cũng bị xóa theo.

Named volume là vùng lưu trữ do Docker quản lý và có vòng đời độc lập với container:

```text
postgres-demo container
          |
          v
pgdata volume
          |
          v
/var/lib/postgresql/data
```

Do volume tồn tại độc lập nên có thể xóa container PostgreSQL rồi tạo container mới, sau đó mount lại `pgdata` để đọc dữ liệu cũ.

### Tạo volume

```bash
docker volume create pgdata
```

Output:

```text
pgdata
```

Kiểm tra:

```bash
docker volume inspect pgdata
```

Output chính:

```text
name=pgdata
driver=local
mountpoint=/var/lib/docker/volumes/pgdata/_data
```

Ảnh minh chứng: [create-postgres-volume.png](./screenshots/create-postgres-volume.png).

### Chạy PostgreSQL

```bash
docker run -d \
  --name postgres-demo \
  --network demo-net \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo-password \
  -e POSTGRES_DB=demo \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine
```

Output:

```text
<container-id>
```

Ảnh minh chứng: [run-postgres-container.png](./screenshots/run-postgres-container.png).

Chờ PostgreSQL sẵn sàng:

```bash
until docker exec postgres-demo \
  pg_isready -U demo -d demo >/dev/null
do
  sleep 1
done
```

Tạo bảng:

```bash
docker exec postgres-demo \
  psql -U demo -d demo \
  -c "CREATE TABLE messages (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL
      );"
```

Output:

```text
CREATE TABLE
```

Thêm dữ liệu:

```bash
docker exec postgres-demo \
  psql -U demo -d demo \
  -c "INSERT INTO messages(content)
      VALUES ('data stored in pgdata');"
```

Output:

```text
INSERT 0 1
```

Kiểm tra:

```bash
docker exec postgres-demo \
  psql -U demo -d demo \
  -c "SELECT * FROM messages;"
```

Output:

```text
 id |        content
----+-----------------------
  1 | data stored in pgdata
(1 row)
```

### Restart và kiểm tra dữ liệu

```bash
docker restart postgres-demo
```

Output:

```text
postgres-demo
```

Sau khi PostgreSQL sẵn sàng, kiểm tra lại:

```bash
docker exec postgres-demo \
  psql -U demo -d demo \
  -c "SELECT * FROM messages;"
```

Dữ liệu vẫn còn:

```text
 id |        content
----+-----------------------
  1 | data stored in pgdata
(1 row)
```

Tuy nhiên, restart container chưa phải bằng chứng mạnh nhất vì writable layer của container vẫn còn. Vì vậy em xóa hẳn container:

```bash
docker rm -f postgres-demo
```

Sau đó tạo lại container mới và mount cùng volume `pgdata`:

```bash
docker run -d \
  --name postgres-demo \
  --network demo-net \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo-password \
  -e POSTGRES_DB=demo \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine
```

Kiểm tra lại:

```bash
docker exec postgres-demo \
  psql -U demo -d demo \
  -c "SELECT * FROM messages;"
```

Output vẫn là:

```text
 id |        content
----+-----------------------
  1 | data stored in pgdata
(1 row)
```

Điều này chứng minh dữ liệu nằm trong volume `pgdata`, không phụ thuộc vào container cũ.

Ảnh minh chứng: [mount-postgres-data-proof.png](./screenshots/mount-postgres-data-proof.png).

## 3. Bind mount với Nginx

### Bind mount là gì?

Bind mount ánh xạ trực tiếp một file hoặc thư mục trên host vào container:

```text
Host:
$PWD/site
     |
     v
Container:
/usr/share/nginx/html
```

Khi file trên host thay đổi, container nhìn thấy thay đổi ngay vì hai đường dẫn đang tham chiếu cùng dữ liệu.

Khác với named volume:

- Named volume do Docker chọn và quản lý vị trí lưu.
- Bind mount dùng chính đường dẫn cụ thể trên host.

### Tạo trang HTML ban đầu

```bash
mkdir -p site

printf '%s\n' \
  '<h1>Version 1</h1>' \
  '<p>Content from bind mount</p>' \
  > site/index.html
```

Chạy Nginx:

```bash
docker run -d \
  --name nginx-site \
  -p 8080:80 \
  -v "$PWD/site:/usr/share/nginx/html:ro" \
  nginx:alpine
```

Trong đó:

- `$PWD/site`: thư mục thật trên host.
- `/usr/share/nginx/html`: document root của Nginx trong container.
- `:ro`: container chỉ được đọc, không được sửa file trên host.
- `-p 8080:80`: map port `8080` trên host vào port `80` của Nginx.

Kiểm tra:

```bash
curl http://localhost:8080
```

Output ban đầu:

```html
<h1>Version 1</h1>
<p>Content from bind mount</p>
```

Ảnh minh chứng:

- [bind-mount.png](./screenshots/bind-mount.png)
- [before-reload-bind-mount.png](./screenshots/before-reload-bind-mount.png)

### Sửa file trên host

```bash
printf '%s\n' \
  '<h1>Version 2</h1>' \
  '<p>This file was updated on the host</p>' \
  > site/index.html
```

Gọi lại:

```bash
curl http://localhost:8080
```

Output mới:

```html
<h1>Version 2</h1>
<p>This file was updated on the host</p>
```

Ảnh minh chứng: [after-reload-bind-mount.png](./screenshots/after-reload-bind-mount.png).

Với static file, em không cần restart hoặc reload process Nginx. Nginx đọc lại file từ bind mount khi có request mới nên thay đổi được hiển thị ngay khi reload trang.

## 4. So sánh nhanh

| Thành phần | Mục đích | Ví dụ trong bài |
|---|---|---|
| Bridge network | Cho các container giao tiếp và resolve tên của nhau | `app1` gọi `http://app2:3000` |
| Named volume | Lưu dữ liệu độc lập với container | `pgdata:/var/lib/postgresql/data` |
| Bind mount | Chia sẻ trực tiếp file/thư mục giữa host và container | `$PWD/site:/usr/share/nginx/html:ro` |
| Port publishing | Cho host truy cập service trong container | `8080:80` |

## 5. Dọn dẹp

Xóa các container:

```bash
docker rm -f \
  app1 \
  app2 \
  postgres-demo \
  nginx-site
```

Xóa network:

```bash
docker network rm demo-net
```

Chỉ xóa volume nếu không cần giữ dữ liệu PostgreSQL:

```bash
docker volume rm pgdata
```

Xóa thư mục bind mount nếu không cần giữ trang HTML:

```bash
rm -rf site
```

Lưu ý: `docker rm` chỉ xóa container, không tự xóa named volume `pgdata`. Muốn xóa dữ liệu phải dùng riêng `docker volume rm pgdata`.
