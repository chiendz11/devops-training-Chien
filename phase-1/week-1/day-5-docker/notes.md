1. Image gồm những lớp gì? Vì sao layer được cache?
a. Docker image gồm:
+ Manifest
   - ghi image có những layer nào
   - thứ tự các layer
   - digest của từng layer
   - trỏ tới config của image

+ Config / metadata
   - CMD
   - ENTRYPOINT
   - ENV
   - WORKDIR
   - EXPOSE
   - USER
   - history build
   - danh sách diff_id của các filesystem layer

+ Filesystem layers
   - các layer read-only
   - mỗi layer là một filesystem diff
   - thường được lưu trong registry dưới dạng compressed tar blob
   - chứa file/folder được thêm hoặc sửa, metadata như permission/owner/symlink, và marker đặc biệt cho file bị xóa

- Mỗi filesystem layer là một diff của cây file(docker run image tạo ra trong container), thường được lưu trong registry dưới dạng compressed tar blob. Layer có thể chứa file/thư mục mới, file bị sửa, metadata như permission/owner/symlink, và whiteout marker để biểu diễn file bị xóa. Một layer riêng lẻ không nhất thiết là một filesystem hoàn chỉnh; root filesystem cuối cùng của image là kết quả khi apply tất cả layer theo đúng thứ tự.

- Các instruction như RUN, COPY, ADD thường tạo filesystem layer mới vì chúng thay đổi nội dung file. Các instruction như CMD, ENTRYPOINT, ENV, EXPOSE, LABEL chủ yếu thay đổi image config/metadata, không nhất thiết tạo filesystem layer mới.

- Ví dụ: 
```Dockerfile:

FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Phân tích chuẩn hơn:

FROM python:3.12-slim
→ lấy base image
→ base image này đã có nhiều filesystem layer read-only sẵn

WORKDIR /app
→ ghi metadata WORKDIR=/app
→ nếu /app chưa tồn tại thì có thể tạo thêm filesystem change

COPY requirements.txt .
→ tạo filesystem layer mới chứa /app/requirements.txt

RUN pip install -r requirements.txt
→ chạy lệnh trong container tạm
→ snapshot phần filesystem thay đổi
→ tạo layer mới chứa các package Python được cài

COPY . .
→ tạo layer mới chứa source code

CMD ["python", "app.py"]
→ chỉ là metadata trong image config
→ không tạo filesystem layer mới

b. Layer được cache để build nhanh hơn, tức là docker không build lại mọi thứ từ đầu mỗi lần chạy docker build. Nó kiểm tra từng bước trong Dockerfile. Nếu bước đó không đổi, Docker dùng lại layer cũ trong cache

- Ví dụ:

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

Nếu chỉ sửa source code, nhưng requirements.txt không đổi, Docker có thể dùng lại cache của bước:

RUN pip install -r requirements.txt

Nghĩa là Docker không cần cài lại toàn bộ dependency, chỉ cần chạy lại từ bước COPY . . trở xuống.


2. Sự khác nhau giữa COPY và ADD
- COPY lấy file/thư mục từ: build context, hoặc build stage khác qua COPY --from hoặc named context / image qua COPY --from. Rồi copy nguyên trạng vào rootfs state đang build, sau đó Docker/BuildKit snapshot phần thay đổi thành layer diff mới.

- ADD giống COPY, nhưng có thêm xử lý đặc biệt, ví dụ như: 
+ ADD app.py /app/app.py giống như COPY app.py /app/app.py

+ Nhưng nếu source là tar local: ADD archive.tar.gz /app/ thì ADD tự giải nén tar local vào /app/, thay vì copy nguyên file tar. Docker docs ghi local tar archive sẽ được decompress/extract vào destination nếu format được nhận diện.

+ Còn nếu source là URL: ADD https://example.com/file.txt /app/file.tx 1thì ADD tải nội dung URL rồi đặt vào destination. Docker docs ghi nếu source là URL thì nội dung URL được download và đặt ở destination.

3. CMD vs ENTRYPOINT — khi nào dùng cái nào?

1. CMD là default command hoặc default arguments

a. CMD dùng để đặt lệnh mặc định cho container.

- Ví dụ:

```Dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
CMD ["python", "app.py"]
```
+ Chạy bình thường 'docker run myapp' thì Docker chạy 'python app.py'

+ Nhưng CMD rất dễ bị override, ví dụ 'docker run myapp bash' lúc này lệnh bash thay thế CMD ["python", "app.py"]. Tức là CMD = default, user có thể thay bằng command khác ở cuối docker run
=> Nên dùng CMD khi muốn image có lệnh chạy mặc định, nhưng vẫn muốn người dùng dễ override để debug hoặc chạy lệnh khác

b. ENTRYPOINT là executable chính của image
- ENTRYPOINT dùng để khai báo chương trình chính mà container gần như luôn phải chạy
- Ví dụ:

```Dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
ENTRYPOINT ["python", "app.py"]
```
+ Chạy docker run myapp thì Docker chạy python app.py, nhưng nếu chạy docker run myapp --debug thì --debug không thay thế ENTRYPOINT, mà được đưa vào làm argument phía sau: python app.py --debug

+ Tức là ENTRYPOINT = executable chính

+ Còn phần command/argument ở cuối docker run sẽ được nối vào sau ENTRYPOINT

=> Nên dùng ENTRYPOINT khi image được thiết kế như một chương trình/tool cố định.

c. Dùng cả ENTRYPOINT và CMD
- Đây là cách rất phổ biến:

```Dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
ENTRYPOINT ["python", "app.py"]
CMD ["--host", "0.0.0.0", "--port", "8000"]
```
+ Ở đây:

ENTRYPOINT = chương trình chính
CMD        = argument mặc định

+ Chạy bình thường docker run myapp sẽ thành python app.py --host 0.0.0.0 --port 8000
+ Nhưng nếu chạy: docker run myapp --debug thì phần CMD ["--host", "0.0.0.0", "--port", "8000"] bị thay bằng --debug, còn ENTRYPOINT vẫn giữ nguyên.


4. Tại sao nên có .dockerignore?
- Vì khi build, Docker gửi cả build context cho builder trước, rồi các lệnh như COPY/ADD mới lấy file từ context đó. Nếu không có ingnore thi Docker phải xử lý toàn bộ các file không cần thiết được đưa vào build context context khiến build chậm, image nhỏ hơn nếu bạn có lệnh COPY . ., tránh lộ secret, tránh copy nhầm file rác/local dependency, cache build ổn định hơn
- Vi dụ: 

+ Khi chạy docker build -t myapp . (dấu . nghĩa là build context là thư mục hiện tại), nếu trong thư mục có:

├── Dockerfile
├── app.py
├── requirements.txt
├── .git/
├── venv/
├── node_modules/
├── __pycache__/
├── logs/
└── data/
└── env


mà không có .dockerignore, Docker có thể đưa cả đống thứ đó vào build context trong đó có cái folder venv(môi trường ảo python) rất nặng khiến build chậm. Nếu có dockerfile có lệnh COPY .. thì image sẽ rất nặng vì node_modules/ và venv/, chẳng may trong project có env thì cũng sẽ khiến lộ secret khi sau khi push image lên registry. Bên cạnh đó, các dir hay thay đổi như .git/ __pycache__/ có thể khiến cache của layer COPY .. bị fail => phải build lại. Cuối cùng là Nếu không ignore, app/venv/ có thể bị copy vào image Điều này sai vì dependency trong image nên được cài bằng: RUN pip install -r requirements.txt chứ không nên copy virtualenv từ máy host vào container. venv trên host có thể phụ thuộc OS, Python path, architecture khác.

5. EXPOSE thực sự làm gì? Có tự mở port không?
- EXPOSE không tự mở port ra ngoài host, Nó chỉ là metadata trong image, nói rằng container này dự kiến sẽ lắng nghe ở port này, còn việc expose port thật thì do đoạn -p 8080:3000 trong lệnh 'docker run -p 8080:3000 myapp' hoặc -P trong 'docker run -P myapp' 

6. Tại sao không nên chạy container as root?

- Container as root” là Dockerfile không có dòng USER, nên mặc định command CMD ["python", "app.py"] sẽ chạy bằng user root bên trong container

=> Không nên chạy container as root vì nếu ứng dụng bên trong container bị chiếm quyền điều khiển, attacker sẽ có quyền của root user trong container. Root trong container không tự động bằng root trên host, nhưng vẫn có quyền rất mạnh trong container và có thể trở nên nguy hiểm nếu container được mount volume, cấp capability, chạy privileged, hoặc có quyền truy cập Docker socket/Kubernetes API
