1. CI / CD / Continuous Deployment khác nhau thế nào?
a. CI = Continuous Integration
- Nghĩa là tích hợp code liên tục. CI chủ yếu kiểm tra code, giúp phát hiện lỗi sớm. Có CI thì mỗi lần push code, mở PR commit lên PR hệ thống kiểm tra ngay.

b. CD thường là Continuous Delivery
- Nghĩa là phân phối liên tục và nó đi sau CI.Sau khi CI đã xác nhận code ổn, CD sẽ làm tiếp:
+ build artifact
+  build Docker image
+ push image lên registry
+ update Helm chart / manifest
+ deploy lên staging
+ chạy smoke test
+ chuẩn bị sẵn để deploy production

- CD thường chưa tự động deploy production, production vẫn cần người bấm approve/manual deploy.

c. Continuous Deployment 
- Nghĩa là triển khai liên tục tự động, nó giống CD, nhưng khác ở bước cuối:
+ Không cần người bấm approve.
+ Nếu tất cả test pass thì tự động deploy production.

2. DORA 4 key metrics là gì? Ý nghĩa từng metric
a. DORA 4 key metrics 
- Là 4 chỉ số chính để đo hiệu quả DevOps / CI/CD / software delivery. Google Cloud từng mô tả 4 metric này gồm Deployment Frequency, Lead Time for Changes, Change Failure Rate, và Time to Restore Service

b. Deployment Frequency 
- Đo tần suất team deploy code lên production, ví dụ: 1 ngày deploy 10 lần, 1 ngày deploy 1 lần, 1 tuần deploy 1 lần, 1 tháng deploy 1 lần
- Ý nghĩa: 
+ Deployment Frequency cao thường cho thấy:
team chia nhỏ thay đổi tốt
pipeline tự động hóa tốt
release ít đau đớn
ít phải chờ gom nhiều feature mới deploy

+ Deployment Frequency thấp thường có thể do:
deploy thủ công
sợ deploy
test yếu
mỗi lần release quá lớn
quy trình approval quá nặng

c. Lead Time for Changes
- Đo thời gian từ lúc code được commit cho đến lúc code đó chạy ở production, ví dụ: Ví dụ
10:00 dev commit code
10:05 push lên GitHub
10:10 CI chạy test
10:20 merge vào main
10:30 build image
10:45 deploy staging
11:00 deploy production

=> Lead Time for Changes là: từ 10:00 đến 11:00 = 1 giờ

- Ý nghĩa:
+ Lead Time ngắn thường cho thấy:
CI/CD nhanh
review nhanh
test tự động tốt
deploy ít thủ công
ít chờ đợi giữa các bước

+ Lead Time dài thường do:
PR bị chờ review lâu
CI chạy quá chậm
deploy thủ công
release theo batch lớn
phải đợi lịch release hàng tuần/hàng tháng

d. Change Failure Rate
- Đo trong phần trăm gây lỗi trong số các deployment lên production, lỗi có thể là:
production incident
rollback
hotfix
service down
API lỗi nhiều
latency tăng nghiêm trọng
database migration hỏng

- Ý nghĩa: 
+ Metric này đo độ an toàn của việc release, tức là Deployment Frequency cao chưa chắc đã tốt nếu Change Failure Rate cũng cao

e. Time to Restore Service
- Đo thời gian để khôi phục service về trạng thái bình thường khi production gặp sự cố, ví dụ:

Production lỗi lúc: 10:00

Team phát hiện, rollback, fix config, service bình thường lại lúc: 10:30

=> Time to Restore Service: 30 phút

- Ý nghĩa: 
+ Metric này đo khả năng phục hồi sau lỗi
+ Time to Restore thấp cho thấy:
monitoring tốt
alert tốt
rollback nhanh
deployment nhỏ
team phản ứng tốt

+ Time to Restore cao thường do:
không có alert
không biết lỗi từ đâu
log khó đọc
rollback thủ công
database migration khó revert
không có runbook

3. Pipeline as Code có ưu điểm gì so với cấu hình UI?

a. Pipeline as Code 
- Là quy trình CI/CD được viết bằng file code/config và lưu trong source control, thường là Git repository, thay vì bấm cấu hình thủ công trên giao diện UI, ví dụ: 

``` .github/workflows/app-ci.yml
name: App CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test

      - name: Build Docker image
        run: docker build -t my-app:test .
``` 
+ File này chính là pipeline nằm trong repo

+ Tức là thay vì vào UI rồi bấm:
Khi có PR thì chạy test
Dùng Ubuntu runner
Checkout code
Install dependencies
Run test
Build Docker image

thì mình viết toàn bộ logic đó vào file YAML.repo

b. Ưu điểm 1: Có version control
- Vì pipeline nằm trong Git nên mọi thay đổi đều có lịch sử nên nếu hôm nay pipeline đang chạy tốt run: npm test và mai ai đó sửa thành run: npm run test:ci thì pipeline bị lỗi, chúng ta có thể xem:

+ git log .github/workflows/app-ci.yml

+ Hoặc xem diff:

- run: npm test
+ run: npm run test:ci

- Cực kỳ quan trọng, vì pipeline cũng là một phần của hệ thống.

+ Với cấu hình UI, có thể xảy ra tình huống:

Ai đó sửa setting trên UI.
Pipeline bắt đầu fail.
Không ai biết chính xác sửa gì.
Không biết rollback thế nào.

=> Pipeline as Code giải quyết vấn đề đó.

c. Ưu điểm 2: Review được bằng Pull Request
- Pipeline as Code có thể được review như code bình thường, ví dụ:

+ Có ai đó sửa:
```
- name: Run tests
  run: pytest
```
thành:
```
- name: Run tests
  run: pytest tests/unit
```

thì reviewer có thể thấy ngay người kuachỉ chạy unit test, bỏ mất integration test.
=> Không được merge.

d. Ưu điểm 3: Dễ rollback
- Vì pipeline là file trong các file version control systemsystem, nếu sửa hỏng thì revert commit, ví dụ: 
``` bash
git revert <commit-id>
```
Hoặc checkout lại version cũ:
``` bash
git checkout HEAD~1 -- .github/workflows/app-ci.yml
```
- Với UI, rollback khó hơn vì phải nhớ trước đó mình đã bấm setting gì

e. Ưu điểm 5: Dễ tái sử dụng
- Vì pipeline là file nên có thể copy hoặc tạo template, ví dụ:
+ Nhiều repo backend đều cần:
checkout
setup python
install dependencies
run test
build docker image
scan image
push registry

=> có thể tạo reusable workflow:

jobs:
  call-backend-ci:
    uses: org/devops-templates/.github/workflows/backend-ci.yml@main

hoặc copy file YAML sang repo mới

f. Ưu điểm 6: Minh bạch hơn

- Khi pipeline nằm trong repo, dev có thể đọc được:
CI chạy khi nào?
Chạy test gì?
Deploy khi nào?
Deploy lên đâu?
Dùng image tag nào?
Có scan security không?
Có cần approval không?

- Ví dụ nhìn vào YAML là biết:

on:
  pull_request:
  push:
    branches: [main]

+ Tức là:
PR cũng chạy CI.
Push vào main cũng chạy CI.

+ Nhìn tiếp environment: production thì biết job này liên quan productio

- Nếu tất cả nằm trên UI, intern/dev mới vào team khó hiểu flow hơn

g. Ưu điểm 7: Giảm lỗi do thao tác tay
- Khi cấu hình pipeline bằng UI, người dùng có thể:
+ bấm nhầm checkbox
+ chọn nhầm branch
+ quên thêm biến môi trường
+ quên bật trigger
+ copy thiếu command

- Pipeline as Code giảm các lỗi này vì trigger, branch, command và environment đều được khai báo rõ trong file, ví dụ:

```yaml
on:
  push:
    branches:
      - main
```

- Nhìn vào file có thể biết pipeline chỉ chạy khi push vào `main`, rõ ràng hơn một setting trên UI mà có thể chỉ admin mới xem được

- Trong production, thao tác tay càng nhiều thì rủi ro càng cao. Ví dụ nếu deploy thủ công và chọn nhầm environment hoặc image tag thì có thể deploy nhầm version lên production

h. Ưu điểm 8: Dễ audit
- Audit nghĩa là có thể kiểm tra lại:
+ Ai thay đổi pipeline?
+ Thay đổi lúc nào?
+ Thay đổi nội dung gì?
+ Thay đổi có được review không?

- Vì pipeline nằm trong Git nên có thể dùng:

```bash
git blame .github/workflows/app-cd.yml
git log -- .github/workflows/app-cd.yml
git diff <commit-cu> <commit-moi> -- .github/workflows/app-cd.yml
```

- Từ đó có thể biết:
+ commit nào thêm bước deploy production
+ ai là người tạo commit
+ Pull Request nào chứa thay đổi
+ ai đã review và approve Pull Request
+ lý do thay đổi pipeline

- Với cấu hình UI, khả năng audit phụ thuộc vào từng tool. Có tool có audit log nhưng intern/dev có thể không có quyền xem, hoặc log không hiển thị đầy đủ diff trước và sau thay đổi

i. Ưu điểm 9: Dễ chuẩn hóa quy trình
- Trong team DevOps thường cần chuẩn hóa các rule như:
+ mọi repo phải chạy lint
+ mọi repo phải chạy test
+ mọi Docker image phải được scan
+ deploy production phải qua approval
+ image phải được tag theo commit SHA

- Pipeline as Code giúp tạo reusable workflow hoặc template dùng chung cho nhiều repository, tránh mỗi team tự cấu hình pipeline theo một cách khác nhau

- Ví dụ build image theo commit SHA:

```yaml
- name: Build image
  run: docker build -t ghcr.io/org/app:${{ github.sha }} .
```

- Dùng commit SHA làm image tag giúp trace được:
+ image được build từ commit nào
+ commit thuộc Pull Request nào
+ ai review Pull Request
+ version nào đang chạy trên production

- Ví dụ production đang chạy image:

```text
ghcr.io/org/app:a1b2c3d
```

thì có thể tìm lại commit:

```bash
git show a1b2c3d
```

=> Đây là cách liên kết artifact với source code, giúp debug và rollback rõ ràng hơn

j. Ưu điểm 10: Phù hợp với GitOps
- GitOps là cách làm trong đó Git được xem là source of truth. Muốn thay đổi trạng thái hệ thống thì sửa file trong Git, tạo Pull Request, review rồi để tool tự đồng bộ trạng thái thật theo Git

- Ví dụ:

```text
Sửa Helm values trong Git
        |
        v
Merge Pull Request
        |
        v
Argo CD phát hiện thay đổi
        |
        v
Argo CD đồng bộ Kubernetes cluster
```

- Pipeline as Code cũng dùng cùng tư duy:

```text
Muốn đổi CI/CD
        |
        v
Sửa workflow trong Git
        |
        v
Pull Request review
        |
        v
Merge
        |
        v
Pipeline chạy theo version mới
```

- Nhờ đó các thành phần của hệ thống có thể cùng được quản lý trong Git:
+ application code
+ infrastructure code
+ Kubernetes manifest hoặc Helm chart
+ CI/CD pipeline

- Lợi ích là trạng thái mong muốn được ghi rõ trong Git, thay đổi có lịch sử và có thể review

- Tuy nhiên Pipeline as Code không tự động biến hệ thống thành GitOps. Để triển khai GitOps còn cần tool reconciliation như Argo CD hoặc Flux đồng bộ cluster theo trạng thái trong Git

4. Khi nào dùng runs-on: self-hosted vs ubuntu-latest?
a. ubuntu-latest là gì?

```yaml
runs-on: ubuntu-latest
```

- Nghĩa là job sẽ chạy trên một máy Ubuntu do GitHub cấp sẵn. Loại runner này gọi là GitHub-hosted runner

- Em không cần tự tạo máy, cài runner hoặc bảo trì hệ điều hành. GitHub tạo một VM mới cho job, chạy các step rồi xóa VM sau khi job hoàn thành

- Ví dụ:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm test
```

- Flow:

```text
GitHub tạo VM Ubuntu
        |
        v
Checkout source code
        |
        v
Install dependencies
        |
        v
Run test
        |
        v
Xóa VM sau khi job hoàn thành
```

- Vì mỗi job được chạy trong môi trường mới nên giảm trường hợp file, dependency hoặc config từ job cũ ảnh hưởng job mới

b. self-hosted là gì?

```yaml
runs-on: self-hosted
```

- Nghĩa là job sẽ chạy trên máy runner do team tự cài đặt và quản lý

- Máy self-hosted runner có thể là:
+ laptop
+ server công ty
+ máy ảo AWS EC2
+ máy trong mạng nội bộ
+ bare-metal server
+ máy có GPU
+ runner chạy trong Kubernetes

- Ví dụ:

```yaml
jobs:
  build:
    runs-on: self-hosted

    steps:
      - uses: actions/checkout@v4
      - run: docker build -t my-app:test .
```

- Để job chạy được, trước đó phải đăng ký một máy làm runner với repository hoặc organization trên GitHub

- GitHub chỉ gửi job xuống runner. Team phải tự chịu trách nhiệm:
+ cài đặt và update OS
+ cài Docker, Node.js, Python hoặc các tool cần thiết
+ bảo vệ secret và network
+ theo dõi dung lượng disk
+ dọn workspace/cache
+ đảm bảo runner luôn online

c. Khi nào dùng ubuntu-latest?
- Dùng `ubuntu-latest` cho các job CI/CD thông thường, ví dụ:
+ lint
+ unit test
+ integration test đơn giản
+ build frontend/backend
+ Docker build cơ bản
+ security scan
+ `terraform fmt`, `validate` hoặc `plan`

- Ví dụ CI cho Node.js:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - run: npm ci
      - run: npm test
```

- Ưu điểm:
+ không cần quản lý máy runner
+ setup nhanh
+ môi trường sạch giữa các job
+ dễ reproduce hơn vì dùng image runner tiêu chuẩn
+ phù hợp phần lớn CI cơ bản
+ ít rủi ro hơn việc để một máy nội bộ chạy code từ nhiều Pull Request

=> Với intern mới học CI/CD, nếu đề bài không có yêu cầu đặc biệt thì mặc định nên chọn:

```yaml
runs-on: ubuntu-latest
```

d. Khi nào dùng self-hosted?

- Dùng self-hosted khi GitHub-hosted runner không đáp ứng được về network, phần cứng, môi trường hoặc chi phí

d.1. Cần truy cập hệ thống private/internal
- Ví dụ staging hoặc production Kubernetes API chỉ có thể truy cập từ mạng nội bộ công ty

- GitHub-hosted runner nằm ngoài mạng nội bộ nên không gọi được private Kubernetes API, private database hoặc private registry

- Khi đó có thể đặt self-hosted runner trong cùng network:

```yaml
jobs:
  deploy:
    runs-on: self-hosted

    steps:
      - uses: actions/checkout@v4
      - run: kubectl apply -f k8s/
```

- Flow:

```text
GitHub Actions gửi job
        |
        v
Self-hosted runner trong mạng nội bộ
        |
        v
Private Kubernetes API
        |
        v
Deploy vào cluster
```

d.2. Cần phần cứng đặc biệt
- Ví dụ:
+ NVIDIA GPU
+ CPU ARM
+ máy có nhiều RAM
+ disk dung lượng lớn
+ thiết bị IoT hoặc camera

- Ví dụ job AI/ML cần GPU:

```yaml
jobs:
  train-smoke-test:
    runs-on: [self-hosted, linux, gpu]

    steps:
      - uses: actions/checkout@v4
      - run: nvidia-smi
      - run: python test_model.py
```

- `[self-hosted, linux, gpu]` nghĩa là runner phải có đủ các label đó thì mới nhận job

d.3. Cần môi trường cài sẵn nặng
- Ví dụ project cần:
+ Android SDK
+ CUDA
+ model hoặc dataset lớn
+ private compiler
+ tool nội bộ
+ private CA certificate

- Nếu dùng `ubuntu-latest`, mỗi job phải tải và cài lại nhiều dependency nên có thể chậm

- Self-hosted runner có thể cài sẵn:
+ Docker
+ kubectl
+ Helm
+ Terraform
+ CUDA
+ model cache

- Tuy nhiên môi trường cài sẵn cũng có nhược điểm là dễ sinh configuration drift. Team phải quản lý version của tool và dọn dữ liệu từ job cũ

d.4. Muốn tiết kiệm GitHub-hosted runner minutes
- GitHub-hosted runner của private repository có quota và có thể phát sinh phí nếu sử dụng vượt mức của plan

- Self-hosted runner không dùng GitHub-hosted runner minutes theo cách đó, nhưng team vẫn phải trả:
+ tiền server hoặc EC2
+ tiền điện
+ storage
+ network
+ chi phí vận hành và bảo trì

- Tóm lại:

```text
ubuntu-latest:
trả theo GitHub-hosted usage nếu vượt quota

self-hosted:
không trả GitHub-hosted runner minutes
nhưng tự trả chi phí máy và vận hành
```

d.5. Cần deploy từ IP cố định
- Một số hệ thống chỉ cho phép IP đã whitelist truy cập:
+ SSH vào production server
+ truy cập private registry
+ gọi database
+ gọi firewall hoặc Kubernetes API

- IP của GitHub-hosted runner có thể thay đổi theo hạ tầng của GitHub

- Self-hosted runner có thể đặt trên:
+ EC2 có Elastic IP
+ server công ty có IP cố định
+ máy kết nối VPN nội bộ

e. So sánh nhanh

| Tiêu chí | `ubuntu-latest` | `self-hosted` |
|---|---|---|
| Ai quản lý máy? | GitHub | Team tự quản lý |
| Môi trường | VM mới cho mỗi job | Có thể là máy dùng lại nhiều lần |
| Cài đặt ban đầu | Hầu như không cần | Phải cài và đăng ký runner |
| Bảo trì OS/tool | GitHub | Team |
| Truy cập mạng nội bộ | Thường không trực tiếp | Có thể đặt trong private network |
| Phần cứng đặc biệt | Hạn chế theo runner GitHub cung cấp | Tự chọn GPU, ARM, RAM, disk |
| IP cố định | Khó kiểm soát hơn | Có thể cấu hình |
| Chi phí | Theo quota/usage của plan | Tự trả hạ tầng và vận hành |
| Mức độ cách ly | VM sạch theo job | Phải tự cấu hình và dọn dẹp |

f. Kết luận
- Chọn `ubuntu-latest` khi job CI thông thường, không cần network nội bộ hoặc phần cứng đặc biệt

- Chọn `self-hosted` khi cần:
+ truy cập private network
+ phần cứng riêng
+ tool nội bộ
+ IP cố định
+ kiểm soát môi trường runner

- Self-hosted không phải lúc nào cũng tốt hơn hoặc rẻ hơn. Nó đổi sự tiện lợi của GitHub-hosted runner lấy quyền kiểm soát cao hơn và trách nhiệm vận hành lớn hơn
