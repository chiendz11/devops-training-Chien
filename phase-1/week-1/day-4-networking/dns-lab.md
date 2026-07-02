1. Giải thích output của dns @1.1.1.1 +trace google.com(thêm 1.1.1.1 vì có vẻ như dns server của router nhà em bị lỗi gì đó khiến connection timeout, nên sẽ route query sang thẳng upstream luôn)

- Flow tổng thể:
  . dig hỏi 1.1.1.1:
   "." có root nameserver nào?
   → nhận a.root-servers.net ... m.root-servers.net
              |
              |
              +          
   dig hỏi m.root-servers.net:
   "google.com A là gì?"
   → root không biết IP, nhưng chỉ sang .com nameserver
              |
              |
              +   
   dig hỏi l.gtld-servers.net:
   "google.com A là gì?"
   → .com không biết IP, nhưng chỉ sang ns1/ns2/ns3/ns4.google.com
              |
              |
              +   

   dig hỏi ns1.google.com:
   "google.com A là gì?"
   → trả lời: 142.250.199.238

- RRSIG = chữ ký số dùng để chứng minh record DNS không bị giả mạo


2. Cấu hình /etc/hosts để map 1 domain giả sang 127.0.0.1, verify với ping

```bash
echo "127.0.0.1 testdomain" | sudo tee -a /etc/hosts                                       
                                                                                                                    
cat /etc/hosts                

ping testdomain
``` 

3. Phân biệt /etc/hosts, /etc/resolv.conf, systemd-resolved

a. /etc/hosts 
- Là file map tên miền/hostname sang IP cục bộ trên chính máy đó 
- Khi app dùng system resolver, máy sẽ có thể đọc /etc/hosts trước khi hỏi DNSL

b. /etc/resolv.conf 
- Là file cấu hình cho DNS resolver biết nếu cần hỏi DNS, thì hỏi DNS server nào
- Ví dụ: 
nameserver 192.168.1.1
nameserver 8.8.8.8
search localdomain
options edns0 trust-ad

c. systemd-resolved 
- Là một service resolver chạy trên Linux systemd
- Nó đứng giữa app và DNS server thật

Flow thường gặp:

App
 |
 v
systemd-resolved
 |
 v
DNS server thật: 192.168.1.1 / 8.8.8.8 / 1.1.1.1

- Nó làm nhiều việc hơn /etc/resolv.conf:
nhận DNS server từ DHCP / NetworkManager / systemd-networkd
cache kết quả DNS,..