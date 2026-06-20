# Task: Networking Fundamentals, DNS, TLS và Packet Capture

- **Intern**: Bùi Anh Chiến
- **Phase / Week / Day**: `Phase 1 / Week 1 / Day 4`
- **Branch**: `phase-1/week-1/day-4-networking`
- **Submitted at**: `2026-06-21 00:22` (timezone +07)
- **Time spent**: khoảng 3 giờ

## 1. Mục tiêu

Task này giúp em hiểu luồng kết nối mạng từ IP, TCP/UDP, DNS cho tới HTTP/HTTPS và TLS. Em cũng thực hành bắt packet HTTP bằng `tcpdump`, đọc payload trong Wireshark/tcpdump và dùng `nc`, `ss` để quan sát port cùng trạng thái socket trên Linux.

## 2. Cách chạy

### 2.1. Yêu cầu

Các lệnh bên dưới được thực hiện trên Linux. Máy mentor cần có:

- `dig`, `nslookup`
- `curl`
- `openssl`
- `tcpdump`
- `nc`
- `ss`
- Wireshark (không bắt buộc)

Trên Ubuntu/Debian có thể cài bằng:

```bash
sudo apt update
sudo apt install -y \
  dnsutils \
  curl \
  openssl \
  tcpdump \
  netcat-openbsd \
  iproute2
```

Clone đúng branch:

```bash
git clone \
  --branch phase-1/week-1/day-4-networking \
  --single-branch \
  git@github.com:chiendz11/devops-training-Chien.git

cd devops-training-Chien/phase-1/week-1/day-4-networking
```

### 2.2. Part A — Networking primer

Phần lý thuyết được trình bày trong [notes.md](./notes.md), gồm:

- Mapping OSI 7 lớp với TCP/IP 4 lớp.
- TCP 3-way handshake và các cờ `SYN`, `ACK`, `FIN`, `RST`.
- Trường hợp nên chọn UDP thay vì TCP.
- Cách tính số IP của CIDR `/24`, `/16`, `/22`.
- Mục đích của private IP.
- NAT, SNAT và DNAT.
- Forward Proxy và Reverse Proxy.

Kết quả tính CIDR:

| CIDR | Số bit host | Tổng số địa chỉ | Số địa chỉ host truyền thống |
|---|---:|---:|---:|
| `/24` | 8 | `2^8 = 256` | 254 |
| `/16` | 16 | `2^16 = 65,536` | 65,534 |
| `/22` | 10 | `2^10 = 1,024` | 1,022 |

Số host truyền thống đã trừ network address và broadcast address. Một số trường hợp đặc biệt như subnet `/31` dùng cho point-to-point sẽ có cách sử dụng khác.

### 2.3. Part B — DNS lab

Chạy lần lượt:

```bash
dig google.com
dig +trace google.com
dig MX gmail.com
dig TXT google.com
dig @8.8.8.8 example.com
nslookup example.com
```

Nếu DNS của router làm `+trace` bị timeout, có thể chỉ định resolver khác:

```bash
dig @1.1.1.1 +trace google.com
```

Luồng `+trace` em quan sát được:

```text
Root name server
       ↓
.com TLD name server
       ↓
Authoritative name server của google.com
       ↓
Trả về record cuối cùng
```

Map domain giả vào loopback bằng `/etc/hosts`:

```bash
echo "127.0.0.1 testdomain" |
  sudo tee -a /etc/hosts

ping -c 4 testdomain
```

Kết quả cần thấy:

```text
PING testdomain (127.0.0.1)
```

Xóa cấu hình sau khi kiểm tra để không để lại record cũ:

```bash
sudo sed -i '/127\.0\.0\.1 testdomain/d' /etc/hosts
```

Giải thích chi tiết `+trace`, `/etc/hosts`, `/etc/resolv.conf` và `systemd-resolved` được ghi trong [dns-lab.md](./dns-lab.md).

### 2.4. Part C — HTTP/HTTPS và TLS

Quan sát toàn bộ quá trình truy cập HTTPS:

```bash
curl -v https://example.com
```

Trong output của `curl -v`:

| Dấu hiệu | Ý nghĩa |
|---|---|
| `Host example.com was resolved` hoặc danh sách IPv4/IPv6 | DNS resolution |
| `Trying <IP>:443` và `Connected to example.com` | TCP connect |
| Các dòng `TLS`, protocol, cipher và certificate | TLS handshake |
| Dòng bắt đầu bằng `>` | HTTP request headers |
| Dòng bắt đầu bằng `<` | HTTP response headers |

Output có thể khác nhẹ tùy phiên bản curl, TLS backend và việc server chọn HTTP/1.1 hay HTTP/2.

Xem certificate chain:

```bash
openssl s_client \
  -connect example.com:443 \
  -servername example.com \
  -showcerts </dev/null
```

Tham số `-servername example.com` gửi SNI để server chọn đúng certificate khi một IP phục vụ nhiều hostname.

Sơ đồ TLS 1.3 và giải thích SNI, ALPN, OCSP, SAN nằm trong [tls-lab.md](./tls-lab.md).

### 2.5. Part D — Bắt packet HTTP bằng tcpdump

Mở terminal A tại thư mục task:

```bash
sudo tcpdump \
  -i any \
  -nn \
  -s 0 \
  -w trace.pcap \
  host example.com
```

Ý nghĩa:

- `-i any`: bắt packet trên tất cả interface.
- `-nn`: không resolve IP và port thành hostname/service name.
- `-s 0`: bắt toàn bộ packet thay vì cắt ngắn payload.
- `-w trace.pcap`: ghi packet vào file để đọc lại.
- `host example.com`: chỉ bắt traffic liên quan tới `example.com`.

Mở terminal B và gửi HTTP request không mã hóa:

```bash
curl http://example.com
```

Quay lại terminal A và nhấn `Ctrl+C` để dừng capture.

Đọc file bằng tcpdump:

```bash
tcpdump -nn -r trace.pcap
tcpdump -nn -A -r trace.pcap
```

Hoặc mở bằng Wireshark:

```bash
wireshark trace.pcap
```

Capture trong bài này có thứ tự:

```text
1. Client → Server: SYN
2. Server → Client: SYN-ACK
3. Client → Server: ACK
4. Client → Server: HTTP GET /
5. Server → Client: ACK
6. Server → Client: HTTP/1.1 200 OK + HTML payload
7. Client → Server: ACK
8. Client → Server: FIN-ACK
9. Server → Client: FIN-ACK
10. Client → Server: ACK
```

Request bắt được đầy đủ:

```http
GET / HTTP/1.1
Host: example.com
User-Agent: curl/8.20.0
Accept: */*
```

Response header và HTML cũng đọc được vì request sử dụng HTTP plain trên port `80`. Nếu dùng HTTPS, tcpdump vẫn nhìn thấy IP, port, TCP flags và một phần thông tin TLS handshake, nhưng HTTP header/body là TLS application data đã mã hóa nên không đọc được trực tiếp.

File [trace.pcap](./trace.pcap) chỉ khoảng 2.3 KB, nhỏ hơn giới hạn 5 MB nên được commit trực tiếp.

### 2.6. Part E — Port và socket

Mở ba terminal.

Terminal A tạo TCP listener:

```bash
nc -l 9000
```

Terminal B kiểm tra port:

```bash
ss -tlnp | grep 9000
```

Kết quả cần có trạng thái `LISTEN` và port `9000`. Tên process có thể chỉ hiện đầy đủ khi chạy bằng user sở hữu process hoặc dùng `sudo`.

Terminal C kết nối và gửi dữ liệu:

```bash
printf 'hello\n' | nc 127.0.0.1 9000
```

Terminal A phải nhận được:

```text
hello
```

Trong lúc hai đầu vẫn giữ kết nối, có thể kiểm tra:

```bash
ss -tnp | grep 9000
```

#### Phân biệt `ss -tln`, `ss -uln`, `ss -anp`

Các option được ghép lại:

- `-t`: chỉ hiển thị TCP socket.
- `-u`: chỉ hiển thị UDP socket.
- `-l`: chỉ hiển thị socket đang listen.
- `-a`: hiển thị cả listening và non-listening socket.
- `-n`: giữ IP/port ở dạng số, không resolve tên.
- `-p`: hiển thị process đang sử dụng socket nếu user có quyền xem.

| Lệnh | Nội dung hiển thị | Trường hợp sử dụng |
|---|---|---|
| `ss -tln` | Các TCP socket đang `LISTEN`, địa chỉ và port ở dạng số | Kiểm tra TCP service có mở port hay chưa |
| `ss -uln` | Các UDP socket đang bind/listen, địa chỉ và port ở dạng số | Kiểm tra DNS, DHCP hoặc service UDP |
| `ss -anp` | Tất cả socket mà `ss` có thể hiển thị, gồm listening/non-listening và process | Điều tra tổng quan socket và process trên máy |

UDP không tạo connection state giống TCP. Chữ `LISTEN` trong output UDP nên hiểu là socket đã bind và sẵn sàng nhận datagram, không có TCP 3-way handshake.

#### Các trạng thái socket

**`LISTEN`**

Process đã bind vào một TCP port và đang chờ client kết nối.

Ví dụ:

```text
nc -l 9000
```

làm socket `0.0.0.0:9000` hoặc `[::]:9000` chuyển sang `LISTEN`.

**`ESTABLISHED`**

TCP 3-way handshake đã hoàn thành và hai đầu có thể truyền dữ liệu hai chiều.

Ví dụ khi terminal C đang kết nối tới listener:

```text
127.0.0.1:<ephemeral-port> ↔ 127.0.0.1:9000
```

hai socket sẽ ở trạng thái `ESTABLISHED`.

**`TIME_WAIT`**

Thường xuất hiện ở phía chủ động đóng kết nối sau khi gửi ACK cuối. Kernel giữ socket một khoảng thời gian để:

- Chờ packet cũ còn trễ trong mạng hết hiệu lực.
- Có thể gửi lại ACK cuối nếu FIN bị retransmit.
- Tránh packet của connection cũ bị nhầm với connection mới có cùng 4-tuple.

Nhiều `TIME_WAIT` trên web server/client có nhiều kết nối ngắn không nhất thiết là lỗi. Không nên giảm timeout hoặc bật socket reuse một cách tùy tiện nếu chưa đo và hiểu ảnh hưởng.

**`CLOSE_WAIT`**

Máy local đã nhận `FIN` từ phía bên kia và kernel đã ACK, nhưng application local chưa gọi `close()` để đóng socket.

Một vài `CLOSE_WAIT` tồn tại ngắn là bình thường. Nếu số lượng tăng liên tục và không biến mất thì thường application đang quên đóng connection hoặc bị kẹt trong logic xử lý. Cách sửa nằm ở application lifecycle, không phải ép kernel xóa socket.

## 3. Kết quả

### Cấu trúc bài nộp

```text
day-4-networking/
├── README.md
├── notes.md
├── dns-lab.md
├── tls-lab.md
├── tcpdump-lab.md
├── trace.pcap
└── screenshots/
```

### Artifact và ảnh minh chứng

| Phần | Kết quả |
|---|---|
| Part A | [notes.md](./notes.md) |
| Part B | [dns-lab.md](./dns-lab.md), [dig trace](./screenshots/dig-trace.png), [ping testdomain](./screenshots/ping-test_domain.png) |
| Part C | [tls-lab.md](./tls-lab.md), [curl HTTPS](./screenshots/https-header.png), [certificate chain](./screenshots/cert-chain.png) |
| Part D | [tcpdump-lab.md](./tcpdump-lab.md), [trace.pcap](./trace.pcap), [chạy tcpdump](./screenshots/run-tcpdump.png), [curl HTTP](./screenshots/curl-example-part_D.png) |
| Part E | [TCP listener](./screenshots/nc%20-l%209000.png), [kết nối tới port 9000](./screenshots/nc%20127.0.0.1%209000%20%20.png), [port 9000](./screenshots/ss%20-tlnp%20%7C%20grep%209000.png) |

Kết quả chính:

- DNS trace đi qua root → TLD → authoritative server.
- `/etc/hosts` map được `testdomain` về `127.0.0.1`.
- `curl -v` hiển thị DNS, TCP, TLS và HTTP headers.
- `openssl s_client` hiển thị certificate chain.
- Capture HTTP đọc được cả request header, response header và HTML payload.
- `nc` mở được listener port `9000`; `ss` nhìn thấy port ở trạng thái `LISTEN`.

## 4. Khó khăn & cách giải quyết

- **`dig +trace` bị timeout khi dùng DNS từ router**: em chỉ định Cloudflare DNS bằng `dig @1.1.1.1 +trace google.com` để gửi query qua resolver hoạt động ổn định hơn.

- **Phân biệt DNS cache với `/etc/hosts`**: em kiểm tra `ping testdomain` sau khi thêm record và xóa record ngay sau lab để tránh hostname giả ảnh hưởng các lần kiểm tra sau.

- **Output `curl -v` có nhiều giai đoạn trộn chung**: em dựa vào các marker của curl: dòng `*` cho thông tin kết nối/TLS, `>` cho request và `<` cho response.

- **Không nhìn thấy HTTP payload khi bắt HTTPS**: đây không phải lỗi tcpdump. Payload đã được TLS mã hóa; vì vậy em dùng `http://example.com` ở Part D để quan sát request và response dạng plaintext.

- **Capture có IPv6 thay vì IPv4**: `example.com` có cả record IPv4 và IPv6, hệ điều hành có thể chọn IPv6. Cách đọc TCP flags và HTTP payload vẫn giống nhau. Nếu cần ép IPv4 có thể dùng `curl -4 http://example.com`.

- **Xem process bằng `ss -p` không đầy đủ**: thông tin process phụ thuộc quyền của user. Có thể dùng `sudo ss -tlnp | grep 9000` khi cần xác nhận process owner.

## 5. Reference

- [BIND 9 — dig manual](https://bind9.readthedocs.io/en/stable/manpages.html)
- [Linux hosts(5)](https://man7.org/linux/man-pages/man5/hosts.5.html)
- [Linux systemd-resolved(8)](https://man7.org/linux/man-pages/man8/systemd-resolved.service.8.html)
- [curl command-line manual](https://curl.se/docs/manpage.html)


## 6. Self-check

- [ ] Đã kiểm tra toàn bộ command trên một máy Linux sạch.
- [x] README có hướng dẫn mentor reproduce Part A–E.
- [x] Không hard-code secret.
- [x] `trace.pcap` nhỏ hơn 5 MB.
- [x] Commit message sử dụng Conventional Commits.
- [x] Đã review lại command, link artifact và ảnh minh chứng.
- [x] Đã bổ sung `tcpdump-lab.md` theo đúng cấu trúc yêu cầu.
