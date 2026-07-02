1. TLS 1.3 handshake đơn giản hóa

Ví dụ dưới đây mô tả lần đầu client truy cập:

```text
https://api.example.com
```

Trước TLS handshake, client đã tìm được IP qua DNS và thiết lập kết nối TCP tới server ở port `443`.

```text
Client / Browser                                      Server
      |                                                  |
      |  1. ClientHello                                  |
      |     - Hỗ trợ TLS 1.3                             |
      |     - Cipher suites                              |
      |     - Key Share của client                       |
      |     - SNI: api.example.com                       |
      |     - ALPN: h2, http/1.1                         |
      |------------------------------------------------->|
      |                                                  |
      |  2. ServerHello                                  |
      |     - Chọn TLS 1.3                               |
      |     - Chọn cipher suite                          |
      |     - Key Share của server                       |
      |<-------------------------------------------------|
      |                                                  |
      |  Client và server dùng hai Key Share để tự       |
      |  tính ra cùng một shared secret. Từ đây, phần    |
      |  còn lại của handshake được mã hóa.              |
      |                                                  |
      |  3. EncryptedExtensions                          |
      |     - ALPN được chọn: h2                         |
      |                                                  |
      |  4. Certificate                                  |
      |     - Certificate chain của server               |
      |     - SAN có api.example.com                     |
      |     - Có thể kèm OCSP stapling                   |
      |                                                  |
      |  5. CertificateVerify                            |
      |     - Server ký dữ liệu handshake bằng           |
      |       private key của certificate                |
      |                                                  |
      |  6. Finished                                     |
      |<=================================================|
      |          Các message trên đã được mã hóa          |
      |                                                  |
      |  Client kiểm tra:                                |
      |  - Certificate chain có về trusted CA không?     |
      |  - Certificate còn hạn không?                    |
      |  - SAN có khớp api.example.com không?            |
      |  - Certificate có bị revoke không?               |
      |  - Chữ ký CertificateVerify có đúng không?       |
      |  - Finished có khớp transcript không?            |
      |                                                  |
      |  7. Finished của client                          |
      |=================================================>|
      |                                                  |
      |  8. HTTP request/response đã mã hóa              |
      |<================================================>|
      |                                                  |
      |  9. NewSessionTicket (có thể gửi sau handshake)  |
      |<-------------------------------------------------|
```

Ký hiệu:

- `---->`: message vẫn có phần quan sát được trên mạng, điển hình là `ClientHello` và `ServerHello`.
- `====>`: message được bảo vệ bằng khóa tạo ra trong handshake.

2. Giải thích từng bước
a. Bước 1 — ClientHello

Client gửi các khả năng mà nó hỗ trợ cho server, ví dụ:

- Phiên bản TLS hỗ trợ.
- Cipher suite hỗ trợ, ví dụ `TLS_AES_128_GCM_SHA256`.
- `key_share` để thực hiện trao đổi khóa.
- SNI chứa hostname client muốn truy cập.
- ALPN chứa các application protocol client hỗ trợ.

Ở bước này client chưa nhận certificate của server và hai bên chưa hoàn thành trao đổi khóa, nên `ClientHello` truyền thống chưa được mã hóa toàn bộ. Vì vậy SNI thường có thể bị quan sát trên mạng. ECH là cơ chế mới giúp mã hóa phần nhạy cảm của `ClientHello`, nhưng không phải kết nối nào cũng đã sử dụng ECH.

b. Bước 2 — ServerHello và tạo khóa phiên

Server chọn các tham số phù hợp rồi trả về `ServerHello`, trong đó có key share của server.

Từ key share của hai bên, client và server tự tính ra cùng một shared secret. Shared secret không được gửi trực tiếp qua mạng. TLS dùng secret này để sinh ra các khóa phiên dùng cho việc mã hóa và kiểm tra tính toàn vẹn.

Điểm em thấy quan trọng là certificate không được dùng để mã hóa toàn bộ dữ liệu HTTP. Certificate chủ yếu giúp xác thực server và chứng minh server giữ private key tương ứng. Dữ liệu thực tế được mã hóa bằng symmetric session key vì cách này nhanh hơn.

c. Bước 3 đến 6 — Server xác thực với client

Sau `ServerHello`, server gửi:

- `EncryptedExtensions`: các extension server đã chọn, ví dụ ALPN là `h2`.
- `Certificate`: certificate của server và certificate trung gian để tạo certificate chain.
- `CertificateVerify`: chữ ký chứng minh server thật sự giữ private key tương ứng với public key trong certificate.
- `Finished`: xác nhận nội dung handshake trước đó không bị thay đổi.

Client không chỉ kiểm tra certificate có “hình ổ khóa” hay không mà phải kiểm tra nhiều điều kiện:

1. Certificate chain có dẫn tới CA mà máy tin tưởng không.
2. Certificate có đang trong thời gian hiệu lực không.
3. Hostname truy cập có xuất hiện trong SAN không.
4. Certificate có bị CA thu hồi không, nếu có thông tin revocation.
5. Chữ ký và message `Finished` có hợp lệ không.

d. Bước 7 — Client Finished

Client gửi `Finished` để server xác nhận phía client cũng đã tính được đúng key và nhìn thấy cùng một handshake transcript.

Sau bước này, hai bên đã có kênh TLS bảo mật và có thể truyền application data như HTTP request/response.

e. Bước 8 và 9 — Application Data và session resumption

HTTP data được mã hóa trước khi gửi qua mạng. Server cũng có thể gửi `NewSessionTicket` để lần kết nối sau thực hiện session resumption nhanh hơn.

TLS 1.3 còn hỗ trợ `0-RTT` trong một số kết nối resumed, nhưng 0-RTT có rủi ro replay nên không nên dùng cho thao tác không idempotent như tạo đơn hàng hoặc chuyển tiền.

2. Vai trò của SNI

SNI là viết tắt của **Server Name Indication**.

Một IP có thể phục vụ nhiều website:

```text
203.0.113.10
├── api.example.com
├── shop.example.com
└── admin.example.com
```

Khi client chỉ kết nối tới `203.0.113.10:443`, server chưa biết client muốn website nào. HTTP header `Host` chưa giúp được ở thời điểm này vì TLS handshake và certificate validation xảy ra trước khi HTTP request được gửi.

Client giải quyết việc đó bằng cách gửi hostname trong SNI:

```text
ClientHello
└── server_name: api.example.com
```

Server hoặc reverse proxy như Nginx dựa vào SNI để:

- Chọn virtual host đúng.
- Chọn certificate đúng cho `api.example.com`.
- Chuyển kết nối đến backend phù hợp nếu cần.

Nếu client không gửi SNI hoặc gửi hostname không tồn tại, server có thể trả certificate mặc định. Khi certificate mặc định không chứa hostname client truy cập, browser sẽ báo lỗi name mismatch.

Ví dụ thực tế:

```bash
openssl s_client \
  -connect example.com:443 \
  -servername example.com
```

Tham số `-servername` chính là giá trị SNI gửi trong `ClientHello`.

Lưu ý: SNI trả lời câu hỏi **“client muốn kết nối tới hostname nào?”**. Nó không tự chứng minh server là chủ sở hữu hợp lệ của hostname đó; phần chứng minh danh tính nằm ở certificate và SAN.

3. Vai trò của ALPN

- ALPN là viết tắt của **Application-Layer Protocol Negotiation**.

- Sau khi tạo được kết nối TLS, client và server vẫn cần thống nhất protocol ứng dụng nào sẽ chạy bên trong TLS. Ví dụ cùng port `443` nhưng có thể dùng:

`http/1.1`: HTTP/1.1.
`h2`: HTTP/2.
`h3`: HTTP/3 trong trường hợp QUIC.

- Client gửi danh sách nó hỗ trợ:

```text
ClientHello
└── ALPN: h2, http/1.1
```

- Server chọn một protocol:

```text
EncryptedExtensions
└── ALPN selected: h2
```

- Sau handshake, hai bên biết phải đọc và ghi dữ liệu theo format HTTP/2. Nhờ vậy client không cần tạo một kết nối thử bằng HTTP/1.1 rồi mới nâng cấp lên HTTP/2.

- Ví dụ thực tế:

```bash
openssl s_client \
  -connect example.com:443 \
  -servername example.com \
  -alpn "h2,http/1.1"
```

- Kết quả có thể hiển thị:

```text
ALPN protocol: h2
```

- Nếu client và server không có protocol chung, kết nối có thể thất bại hoặc ứng dụng dùng protocol mặc định tùy cấu hình và loại dịch vụ.

Theo cách em hiểu:

- SNI giúp server chọn đúng website/certificate.
- ALPN giúp hai bên chọn đúng protocol ứng dụng.

4. Vai trò của OCSP

- OCSP là viết tắt của **Online Certificate Status Protocol**.

- Một certificate vẫn có thể còn hạn nhưng private key đã bị lộ hoặc certificate bị cấp sai. Khi đó CA có thể revoke certificate trước ngày hết hạn.

- OCSP cho phép kiểm tra trạng thái certificate:

```text
good     = chưa bị revoke theo thông tin của OCSP responder
revoked  = đã bị thu hồi
unknown  = responder không biết certificate này
```

- Cách kiểm tra trực tiếp

Client đọc địa chỉ OCSP responder từ certificate rồi gửi request tới CA:

```text
Browser ── hỏi trạng thái certificate ──> OCSP responder của CA
Browser <──── good/revoked/unknown ────── OCSP responder của CA
```

+ Cách này có hai nhược điểm:

Tăng thêm request và độ trễ.
OCSP responder có thể biết client đang kiểm tra certificate của website nào.

- OCSP stapling

Với OCSP stapling, server định kỳ hỏi CA trước rồi “đính kèm” response đã được CA ký trong TLS handshake:

```text
CA OCSP responder
        |
        | signed OCSP response
        v
      Server ───────── stapled response ─────────> Client
```

Client kiểm tra chữ ký và thời gian hiệu lực của response mà không cần tự hỏi CA trong mỗi lần truy cập.

OCSP không thay thế các bước kiểm tra khác. Trạng thái 'good' không có nghĩa certificate chắc chắn hợp lệ; client vẫn phải kiểm tra chain, thời hạn và SAN.

Ví dụ kiểm tra OCSP stapling:

```bash
openssl s_client \
  -connect example.com:443 \
  -servername example.com \
  -status
```

Nếu server hỗ trợ stapling, output có thể chứa phần `OCSP Response Status`.

5. Vai trò của SAN

- SAN là viết tắt của Subject Alternative Name. Đây là extension trong certificate chứa các danh tính mà certificate được phép đại diện.

Ví dụ:

```text
X509v3 Subject Alternative Name:
    DNS:example.com
    DNS:www.example.com
    DNS:api.example.com
```

- Khi truy cập:

```text
https://api.example.com
```

client kiểm tra `api.example.com` có khớp với một SAN trong certificate hay không.

- Các trường hợp:

```text
SAN: DNS:api.example.com
→ khớp chính xác api.example.com

SAN: DNS:*.example.com
→ khớp api.example.com
→ không khớp dev.api.example.com

SAN: DNS:www.example.com
→ không khớp api.example.com
```

- SAN có thể chứa nhiều loại danh tính, thường gặp nhất là:

`DNS`: hostname/domain.
`IP Address`: địa chỉ IP.

- Nếu truy cập bằng IP:

```text
https://203.0.113.10
```

thì certificate cần có IP đó trong SAN dạng `IP Address`. Việc certificate chỉ có một DNS name không làm nó hợp lệ cho địa chỉ IP.

Trước đây Common Name (`CN`) thường được dùng để chứa hostname, nhưng trong hệ thống hiện đại hostname phải được kiểm tra dựa trên SAN. Vì vậy khi tự tạo certificate, em cần khai báo SAN chứ không nên chỉ đặt `CN=example.com`.

- Ví dụ xem SAN:

```bash
openssl s_client \
  -connect example.com:443 \
  -servername example.com \
  </dev/null 2>/dev/null |
openssl x509 -noout -ext subjectAltName
```

6. Mối liên hệ giữa SNI, ALPN, OCSP và SAN

- Với kết nối tới 'https://api.example.com', em có thể tóm tắt như sau:

| Thành phần | Câu hỏi nó giải quyết | Ví dụ |
|---|---|---|
| **SNI** | Client muốn website/hostname nào trên IP này? | api.example.com |
| **ALPN** | Hai bên sẽ nói protocol ứng dụng nào trong TLS? | Server chọn h2 |
| **SAN** | Certificate có hợp lệ cho hostname client truy cập không? | SAN chứa DNS:api.example.com |
| **OCSP** | Certificate có bị CA revoke trước khi hết hạn không? | Trạng thái good hoặc revoked |

- Flow thực tế:

```text
1. SNI  → server chọn virtual host và certificate
2. ALPN → client/server chọn HTTP/1.1 hay HTTP/2
3. SAN  → client kiểm tra certificate có đúng hostname
4. OCSP → client kiểm tra certificate có bị thu hồi
```

- SNI và SAN có liên quan nhưng không giống nhau:

SNI là thông tin client gửi để yêu cầu một hostname.
SAN là thông tin CA đã ký trong certificate để xác nhận certificate dùng được cho hostname nào.

- Ví dụ client gửi:

```text
SNI = api.example.com
```

nhưng server trả certificate chỉ có:

```text
SAN = DNS:www.example.com
```

thì TLS validation phải thất bại vì hostname không khớp.
