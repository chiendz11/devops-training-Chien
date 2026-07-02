# TCPdump Lab

## 1. Lệnh capture

Em chạy tcpdump để bắt traffic đi tới `example.com`:

```bash
sudo tcpdump -i any -nn -s 0 -w trace.pcap host example.com
```

Sau đó mở terminal khác và gửi request HTTP:

```bash
curl http://example.com
```

Sau khi request hoàn thành, em quay lại terminal tcpdump và nhấn `Ctrl+C`.

Đọc file capture:

```bash
tcpdump -nn -r trace.pcap
tcpdump -nn -A -r trace.pcap
```

Trong đó:

- `-i any`: bắt packet trên tất cả network interface.
- `-nn`: giữ IP và port ở dạng số, không resolve thành hostname/service.
- `-s 0`: bắt đầy đủ packet, không cắt ngắn payload.
- `-w trace.pcap`: ghi packet vào file.
- `-r trace.pcap`: đọc lại file capture.
- `-A`: hiển thị payload dạng ASCII.

## 2. Thứ tự packet bắt được

Capture của em sử dụng IPv6 nhưng flow TCP vẫn giống IPv4:

```text
Client                                                Server
  |                                                     |
  |  1. SYN                                              |
  |---------------------------------------------------->|
  |                                                     |
  |  2. SYN-ACK                                          |
  |<----------------------------------------------------|
  |                                                     |
  |  3. ACK                                              |
  |---------------------------------------------------->|
  |                                                     |
  |  4. HTTP GET /                                       |
  |---------------------------------------------------->|
  |                                                     |
  |  5. ACK                                              |
  |<----------------------------------------------------|
  |                                                     |
  |  6. HTTP/1.1 200 OK + HTML payload                   |
  |<----------------------------------------------------|
  |                                                     |
  |  7. ACK                                              |
  |---------------------------------------------------->|
  |                                                     |
  |  8. FIN-ACK                                          |
  |---------------------------------------------------->|
  |                                                     |
  |  9. FIN-ACK                                          |
  |<----------------------------------------------------|
  |                                                     |
  | 10. ACK                                              |
  |---------------------------------------------------->|
```

Giải thích:

1. Client gửi `SYN` để yêu cầu mở TCP connection.
2. Server trả `SYN-ACK` để đồng ý và xác nhận SYN của client.
3. Client gửi `ACK`, hoàn thành TCP 3-way handshake.
4. Client gửi HTTP request `GET /`.
5. Server ACK request đã nhận.
6. Server trả `HTTP/1.1 200 OK` cùng HTML của trang.
7. Client ACK dữ liệu response.
8. Client gửi `FIN-ACK` để chủ động đóng chiều gửi của mình.
9. Server gửi `FIN-ACK` để đóng chiều còn lại.
10. Client gửi ACK cuối, kết thúc connection.

Trong output tcpdump:

```text
[S]  = SYN
[S.] = SYN + ACK
[.]  = ACK
[P.] = PSH + ACK, thường có payload
[F.] = FIN + ACK
```

## 3. Request có bắt được đầy đủ không?

Có. Vì em dùng HTTP plain trên port `80`, request không được mã hóa nên `tcpdump -A` đọc được đầy đủ header:

```http
GET / HTTP/1.1
Host: example.com
User-Agent: curl/8.20.0
Accept: */*
```

Response cũng nhìn thấy được:

```http
HTTP/1.1 200 OK
Content-Type: text/html
Server: cloudflare
```

Sau phần response header là HTML payload của trang Example Domain.

Em dùng `-s 0` để tcpdump không cắt ngắn packet. Tuy nhiên trong trường hợp response lớn, dữ liệu có thể được chia thành nhiều TCP segment. Khi đó cần follow TCP stream trong Wireshark để xem application data theo đúng thứ tự dễ hơn.

## 4. Vì sao HTTPS không bắt được payload?

HTTPS là HTTP chạy bên trong TLS:

```text
HTTP request/response
        ↓
TLS mã hóa
        ↓
TCP
        ↓
IP
```

Nếu bắt traffic `https://example.com`, tcpdump vẫn thấy được:

- Source/destination IP.
- Source/destination port.
- TCP flags như SYN, ACK, FIN.
- Kích thước và thời điểm packet.
- Một số message của TLS handshake.

Nhưng phần HTTP request, response header và body đã được mã hóa thành TLS application data. Vì tcpdump chỉ capture packet trên mạng và không có session key nên nó không thể tự giải mã payload.

Ví dụ với HTTPS, thay vì thấy:

```http
GET / HTTP/1.1
Host: example.com
```

tcpdump chỉ thấy các byte mã hóa, không đọc được nội dung HTTP thật.

Điều này giúp bảo vệ các dữ liệu như:

- Cookie và session token.
- Username/password.
- Request body.
- Response body.
- HTTP header.

Muốn phân tích HTTPS trong môi trường lab do mình kiểm soát thì có thể export TLS session key từ client và cấu hình Wireshark đọc key log. Không nên tìm cách giải mã traffic của người khác khi không có quyền.

## 5. Kết quả

- Bắt được đầy đủ TCP 3-way handshake.
- Bắt được HTTP request `GET /`.
- Bắt được response `HTTP/1.1 200 OK` và HTML payload.
- Quan sát được quá trình đóng connection bằng FIN/ACK.
- Xác nhận HTTPS che nội dung HTTP bằng TLS encryption.

File capture: [trace.pcap](./trace.pcap).

Ảnh minh chứng:

- [Chạy tcpdump](./screenshots/run-tcpdump.png)
- [Gửi HTTP request bằng curl](./screenshots/curl-example-part_D.png)
