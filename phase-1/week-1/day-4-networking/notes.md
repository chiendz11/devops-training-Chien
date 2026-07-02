1. So sánh OSI 7 lớp với TCP/IP 4 lớp.
a. Số layer
OSI 7 lớp
Từ trên xuống dưới:
7. Application
6. Presentation
5. Session
4. Transport
3. Network
2. Data Link
1. Physical

TCP/IP 4 lớp
4. Application
3. Transport
2. Internet
1. Network Access / Link

-Mapping:

OSI Application     ┐
OSI Presentation    ├── TCP/IP Application 
OSI Session         ┘

OSI Transport       ─── TCP/IP Transport

OSI Network         ─── TCP/IP Internet

OSI Data Link       ┐
OSI Physical        ├── TCP/IP Network Access / Link


2. TCP 3-way handshake — vẽ ASCII diagram + giải thích cờ SYN/ACK/FIN/RST.

Client                                           Server
  |                                                
  |  1) SYN, Seq = x                               |
  |----------------------------------------------->|     
  |                                                |
  |  2) SYN + ACK, Seq = y, Ack = x + 1            |
  |<-----------------------------------------------|
  |                                                |
  |  3) ACK, Seq = x + 1, Ack = y + 1              |
  |----------------------------------------------->|
  |                                                |
  |            TCP connection established          |



- SYN dùng để bắt đầu kết nối TCP và đồng bộ sequence number ban đầu. Ví dụ ở bước Client -> Server: SYN, Seq = x, có nghĩa là Client muốn bắt đầu kết nối TCP với server với seq number = 1000 và Server cũng cũng đồng ý mở connection(gửi kèm cờ SYN và ACK xác nhận đã nhận được gói tin trước) bắt đầu với Seq number là y, sau 2 bước trong 3-way tcp handshake là cờ SYN sẽ không còn trong tcp header nữa
- ACK dùng để xác nhận rằng đã nhận được segment trước đó. Ví dụ Client gửi ACK, Seq = 1000, Ack = 2000, thì sau đó Server sẽ phải trả về ACK = 1000 + len của data segment
- FIN có nghĩa là " Tôi không gửi thêm data(payload) theo chiều của tôi nữa". tức nếu Client báo FIN thì chỉ có mỗi bên Server sẽ gửi segment(có data) đến Client thôi, còn Client sau lúc báo FIN thì sẽ chỉ gửi segments có ACK(không có data) để báo cho Server biết là đã nhận được data. Chứ không phải FIN = đóng kết nối, Client không response gì nữa.
- RST là hủy connection này ngay lập tức, không đóng lịch sự như FIN nữa. Khi đó chỉ cần 1 bên gửi RST là connection đóng luôn, bên còn lại sẽ không nhận được segment có ACK từ bên còn lại.

3. Khi nào chọn UDP thay TCP? Ví dụ thực tế.
a. UDP
- UDP rất “mỏng”. Nó gần như chỉ thêm port vào IP. Nó có một cục data, gắn source port, destination port rồi ném nó xuống IP.
- UDP không tạo/tracking một connection state trong transport layer như TCP
- UDP không đảm bảo:
Packet có tới nơi không
Packet có tới đúng thứ tự không
Packet có bị trùng không
Bên nhận có đang sẵn sàng nhận không
Tốc độ gửi có làm nghẽn mạng không
Nó chỉ có checksum để phát hiện lỗi cơ bản. Nếu packet lỗi, thường bị drop.
-Ví dụ: 
Gửi: 1, 2, 3, 4, 5
Bên nhận có thể thấy: 1, 3, 5 hoặc 2, 1, 3, 5
UDP không tự sửa những chuyện đó.
Nếu app cần sửa, app phải tự làm.

b. TCP
- TCP thì ngược lại. TCP không chỉ “ném data đi”. TCP tạo ra một reliable byte stream giữa hai process.
- TCP có connection state, trước khi gửi data, TCP tạo kết nối bằng 3-way handshake
- TCP tự gửi lại nếu mất hoặc data
- TCP có flow control, tức là TCP còn kiểm soát tốc độ gửi dựa trên khả năng nhận của bên kia dựa vào receive window size
- TCP cũng cố tránh làm nghẽn mạng. Nếu thấy mất packet, RTT tăng, hoặc dấu hiệu nghẽn, TCP giảm tốc độ gửi dựa vào congestion window
- Ví dụ server nói: receive window = 5000 bytes, nghĩa là: tôi hiện chỉ còn buffer nhận thêm 5000 bytes, đừng gửi quá mức đó.đ

=>  Chọn UDP thay TCP khi ứng dụng cần nhanh, ít độ trễ, và chấp nhận mất một vài packet hơn là chờ gửi lại bởi vì TCP = chắc chắn, đúng thứ tự, nhưng có thể chậm hơn, UDP = gửi nhanh, không đảm bảo, app tự xử lý nếu cần. 
* Ví dụ game bắn súng:
- Client gửi vị trí nhân vật:
t=1: x=10, y=20
t=2: x=11, y=20
t=3: x=12, y=20

- Nếu packet t=1 bị mất, server không nhất thiết cần nó nữa, vì packet t=3 mới hơn và quan trọng hơn.

- Nếu dùng TCP:

packet t=1 mất
TCP phải gửi lại t=1
server/app có thể bị kẹt chờ dữ liệu cũ

- Kết quả: game dễ bị delay / giật / input lag nhiều hơn là 1 quãng ngắn không đáng kể như UDP

- Nhưng các dữ liệu quan trọng như:

mua vật phẩm
đăng nhập
kết quả trận đấu
giao dịch tiền trong game

có thể dùng TCP hoặc dùng UDP nhưng tự thêm cơ chế xác nhận/gửi lại.UDP

4. CIDR /24, /16, /22 — số IP tương ứng?
- Thực chất IPv4 là 32 bit:
192.168.1.10
= 11000000.10101000.00000001.00001010

- Người ta viết dạng 192.168.1.10 chỉ để dễ đọc. Máy thì xử lý dạng bit.
- Một mạng IP lớn có thể được chia thành nhiều subnet/mạng con.
- Ký hiệu /24, /16, /22 gọi là CIDR prefix, dùng để nói:
Bao nhiêu bit đầu của IP thuộc về phần mạng/subnet.
Bao nhiêu bit sau còn lại để đánh địa chỉ host trong subnet đó.

- Ví dụ:

192.168.1.10/24

nghĩa là IP 192.168.1.10 đang nằm trong subnet:

192.168.1.0/24

Trong đó:

24 bit đầu = phần network/subnet
8 bit sau  = phần host

=> /24 có 2^8, /16 có 2^16, /22 có 2^10 mạng con trong subnet

5. Tại sao có private IP range (10/8, 172.16/12, 192.168/16)?
- Có private IP range vì IPv4 chỉ có khoảng 4.3 tỷ địa chỉ, không đủ để mỗi thiết bị trên thế giới đều có public IP riêng. 
- Nên người ta dành riêng vài dải IP để dùng bên trong mạng nội bộ, gọi là private IP:

10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
- Các IP này không được route trực tiếp trên Internet public.
- Server ngoài Internet chỉ thấy public IP của router, không thấy private IP thật của laptop.
6. NAT là gì? Phân biệt SNAT vs DNAT.
- NAT(Network Address Translation) là cơ chế sửa địa chỉ IP/port của packet khi packet đi qua gateway/router/firewall.
- Ví dụ:
NAT thường chạy ở thiết bị đứng giữa 2 mạng, ví dụ:

LAN nhà bạn  <-->  Router  <-->  Internet

Router có thể sửa packet kiểu:

Src IP: 192.168.1.10  ->  113.161.10.20

hoặc:

Dst IP: 113.161.10.20:8080  ->  192.168.1.100:80

NAT có thể sửa:

L3: IP address
L4: TCP/UDP port

a. SNAT 
- Source NAT,tức là sửa source IP/port, tức là sửa địa chỉ nguồn.

Dùng nhiều khi máy private đi ra Internet.

- Ví dụ laptop trong LAN truy cập Google:

Laptop: 192.168.1.10
Router public IP: 113.161.10.20
Google: 142.250.x.x

Packet ban đầu:

Src: 192.168.1.10:50000
Dst: 142.250.x.x:443

Router làm SNAT:

Src: 113.161.10.20:40001
Dst: 142.250.x.x:443

Tức là router đổi nguồn từ private IP sang public IP.

Lý do phải làm vậy:

192.168.1.10 là private IP, Internet không route về được.

Nên phải đổi source thành public IP để server ngoài Internet biết đường trả lời về router.

Router lưu bảng NAT:

113.161.10.20:40001 -> 192.168.1.10:50000

Khi response quay về, router dựa vào bảng này để chuyển lại cho laptop.

b. DNAT
- DNAT = Destination NAT tức là sửa destination IP/port, tức là sửa địa chỉ đích.

Dùng nhiều khi request từ ngoài Internet đi vào server bên trong private network.

Ví dụ bạn có web server trong nhà:

Router public IP: 113.161.10.20
Web server nội bộ: 192.168.1.100:80

Bạn cấu hình port forwarding:

113.161.10.20:8080 -> 192.168.1.100:80

Client ngoài Internet gửi request:

Src: 1.2.3.4:55000
Dst: 113.161.10.20:8080

Router làm DNAT:

Src: 1.2.3.4:55000
Dst: 192.168.1.100:80

Tức là router đổi đích từ public endpoint sang server nội bộ thật.

Tóm lại:

DNAT = sửa đích
Thường dùng để đón request từ ngoài vào service/server bên trong 

6. Sự khác nhau giữa Forward Proxy và Reverse Proxy.

- Proxy = một thằng trung gian nhận request từ một bên, rồi gửi tiếp request đó sang bên kia 

Client  --->  Proxy  --->  Server

- Proxy không chỉ sửa IP/port như NAT, proxy thật sự nhận request/connection, rồi tạo request/connection mới để gửi tiếp

- Forward Proxy = proxy đứng về phía client, đại diện cho client đi ra ngoài

Flow:

Client  --->  Forward Proxy  --->  Internet Server

Ví dụ:

Laptop của bạn
   |
   v
Forward Proxy
   |
   v
google.com

Ở đây proxy đang đại diện cho client.

Server bên ngoài thấy request đến từ:

IP của forward proxy

không phải IP thật của client.

- Reverse Proxy = proxy đứng về phía server, đại diện cho server/backend để đón request từ client
Flow:

Client  --->  Reverse Proxy  --->  Backend Server

Ví dụ website thật có nhiều backend:

User
 |
 v
Nginx / Load Balancer / Cloudflare
 |
 +--> Backend 1: 10.0.1.10:8000
 +--> Backend 2: 10.0.1.11:8000
 +--> Backend 3: 10.0.1.12:8000

User chỉ biết:

app.example.com

User không biết backend thật nằm ở IP nào.

Ở đây reverse proxy đang đại diện cho server/backend.
