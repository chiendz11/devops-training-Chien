# Part E — Failure scenarios

## 1. Khi pipeline thất bại ở step push, làm sao retry nhanh không build lại?

### a. Vấn đề khi build và push nằm trong cùng một job

- Ví dụ pipeline đã build Docker image thành công nhưng đến bước `docker push` thì lỗi do:

+ Mạng tạm thời bị gián đoạn.
+ Container registry timeout.
+ Token đăng nhập hết hạn hoặc thiếu quyền.
+ Registry tạm thời không phản hồi.

- Nếu em chọn **Re-run failed jobs** thì GitHub Actions sẽ chạy lại toàn bộ job bị fail từ step đầu tiên, chứ không chạy lại riêng step `push`.

- Có thể retry bằng giao diện GitHub:

```text
Actions
→ Chọn workflow run bị fail
→ Re-run jobs
→ Re-run failed jobs
```

- Hoặc dùng GitHub CLI:

```bash
gh run rerun <RUN_ID> --failed
```

- Nếu Docker Buildx đã cấu hình cache thì lần build lại thường nhanh hơn:

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

- Tuy nhiên cách này vẫn chạy lại step build. BuildKit chỉ restore layer từ cache nên nhìn giống build rất nhanh, không có nghĩa là pipeline đã bỏ qua job build.

### b. Muốn không build lại thì cần tách build và push

- Cách rõ ràng là:

```text
build-image
    ↓
upload image artifact
    ↓
push-image
```

- Job build xuất image thành file:

```yaml
jobs:
  build-image:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - name: Build image and export to file
        uses: docker/build-push-action@v6
        with:
          context: .
          outputs: type=docker,dest=/tmp/demo-app.tar
          tags: ghcr.io/example/demo-app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Upload image artifact
        uses: actions/upload-artifact@v4
        with:
          name: demo-app-image
          path: /tmp/demo-app.tar
          retention-days: 1
```

- Job push chỉ tải image đã build rồi push:

```yaml
  push-image:
    needs: build-image
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write

    steps:
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: demo-app-image
          path: /tmp

      - name: Load image
        run: docker load --input /tmp/demo-app.tar

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Push image
        run: docker push ghcr.io/example/demo-app:${{ github.sha }}
```

- Khi push fail, em chỉ retry job `push-image`. Job này dùng lại artifact, không cần build lại source code.

- Nhược điểm của cách lưu image thành artifact:

+ Docker image lớn thì upload/download artifact mất thời gian.
+ Tốn artifact storage.
+ Cần đặt retention ngắn nếu artifact chỉ dùng để retry.

- Với pipeline thông thường, Buildx cache thường đã đủ để retry nhanh. Với release quan trọng hoặc image build rất lâu, tách immutable artifact khỏi bước push sẽ an toàn và rõ ràng hơn.

## 2. Cách debug một job chỉ fail trên runner nhưng không tái hiện local

### a. Kiểm tra đúng môi trường runner

- Job có thể chỉ fail trên runner vì local và runner khác nhau về:

+ Hệ điều hành và architecture.
+ Phiên bản Node.js, npm, Docker hoặc dependency.
+ Environment variable và secret.
+ Quyền ghi file.
+ Đường dẫn file và tính phân biệt chữ hoa/chữ thường.
+ Network, DNS hoặc proxy.
+ CPU, RAM và disk.
+ Timezone hoặc locale.

- Em thêm một step in thông tin môi trường:

```yaml
- name: Show runner diagnostics
  shell: bash
  run: |
    echo "Runner OS: $RUNNER_OS"
    echo "Runner architecture: $RUNNER_ARCH"
    uname -a
    node --version
    npm --version
    docker version
    pwd
    df -h
    free -h
    env | sort
```

- Không nên in trực tiếp secret ra log. GitHub có cơ chế mask secret, nhưng vẫn không nên chủ động `echo` token hoặc credential.

### b. Re-run job với debug logging

- GitHub cho phép chạy lại workflow hoặc failed job với runner diagnostic log và step debug log:

```bash
gh run rerun <RUN_ID> --failed --debug
```

- Sau đó xem log:

```bash
gh run view <RUN_ID> --log-failed
```

- Debug log giúp em thấy chi tiết hơn về expression, action và quá trình runner thực hiện step.

### c. Lưu artifact khi job fail

- Nếu test tạo report, log hoặc file tạm thì nên upload dù job fail:

```yaml
- name: Upload debug artifacts
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: debug-output
    path: |
      logs/
      test-results/
      coverage/
```

- Nếu muốn step luôn chạy dù các step trước pass hay fail:

```yaml
if: always()
```

- Artifact giúp kiểm tra lỗi mà terminal log không hiển thị đầy đủ, ví dụ screenshot của browser test, core dump hoặc test report.

### d. Cố gắng tạo môi trường gần giống runner

- Nếu workflow dùng container thì có thể chạy local bằng cùng image:

```bash
docker run --rm -it \
  -v "$PWD:/workspace" \
  -w /workspace \
  node:20 \
  bash
```

- Trong container:

```bash
npm ci
npm test
```

- Có thể dùng `act` để mô phỏng GitHub Actions local, nhưng kết quả không giống runner GitHub hoàn toàn vì runner image, service và GitHub context có thể khác.

### e. SSH vào runner khi thật sự cần

- GitHub-hosted runner là máy tạm thời và GitHub không cung cấp sẵn SSH trực tiếp. Có thể dùng action bên thứ ba như `action-tmate` để mở phiên debug.

- Cách này cần thận trọng:

+ Chỉ dùng trong repo/branch đáng tin cậy.
+ Không dùng cho Pull Request từ source không tin cậy.
+ Không để session mở lâu.
+ Không để người khác nhìn thấy connection string.
+ Kiểm tra nguy cơ lộ secret trên runner.

- Thứ tự debug em ưu tiên là:

```text
Đọc log
→ thêm diagnostic
→ re-run với --debug
→ upload artifact
→ mô phỏng bằng container
→ cuối cùng mới mở interactive session
```

## 3. So sánh `needs`, `if` và `concurrency group`

### a. `needs`

- `needs` định nghĩa quan hệ phụ thuộc và thứ tự giữa các job.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: docker build -t demo-app .
```

- Luồng:

```text
test pass
    ↓
build chạy
```

- Mặc định, nếu job trong `needs` fail hoặc bị skip thì job phụ thuộc cũng bị skip.

- Có thể dùng kết hợp:

```yaml
cleanup:
  needs:
    - test
    - build
  if: always()
```

- Khi đó cleanup vẫn chạy để xóa resource hoặc upload log dù job trước fail.

### b. `if`

- `if` là điều kiện quyết định một job hoặc một step có được chạy hay không.

```yaml
deploy-production:
  if: startsWith(github.ref, 'refs/tags/v')
  runs-on: ubuntu-latest
```

- Ví dụ trên chỉ chạy khi workflow được trigger bởi tag bắt đầu bằng `v`.

- Một số status function thường dùng:

```yaml
if: success()
if: failure()
if: cancelled()
if: always()
```

- `if` không tự tạo thứ tự giữa các job. Nếu muốn vừa chờ job khác vừa kiểm tra điều kiện thì dùng cả hai:

```yaml
deploy:
  needs: build
  if: github.ref == 'refs/heads/main'
```

### c. `concurrency group`

- `concurrency` kiểm soát nhiều workflow run hoặc job có được chạy đồng thời hay không.

```yaml
concurrency:
  group: deploy-production
  cancel-in-progress: false
```

- Ví dụ production chỉ nên có một deployment tại một thời điểm:

```text
Deploy A đang chạy
Deploy B đến sau
→ Deploy B phải chờ
```

- Với CI trên cùng branch, có thể hủy run cũ khi có commit mới:

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

- Ví dụ:

```text
Commit A đang chạy CI
Commit B được push lên cùng branch
→ CI của A bị hủy
→ CI của B tiếp tục
```

- `concurrency` không nói job nào phụ thuộc job nào và cũng không kiểm tra branch/tag để quyết định nghiệp vụ. Nó chỉ ngăn hoặc hủy các run có cùng concurrency key.

### d. Bảng so sánh

| Thành phần | Mục đích | Ví dụ |
| :--- | :--- | :--- |
| `needs` | Tạo dependency và thứ tự giữa các job | Build chỉ chạy sau khi test pass |
| `if` | Quyết định job/step có chạy hay không | Production chỉ chạy với tag `v*` |
| `concurrency` | Hạn chế nhiều run chạy đồng thời | Chỉ một deploy production tại một thời điểm |

- Có thể kết hợp cả ba:

```yaml
deploy-production:
  needs: build-release
  if: startsWith(github.ref, 'refs/tags/v')
  concurrency:
    group: production
    cancel-in-progress: false
  runs-on: ubuntu-latest
```

- Ý nghĩa:

+ Chờ `build-release` thành công.
+ Chỉ chạy khi ref là release tag.
+ Không cho hai production deployment chạy cùng lúc.

## 4. Tại sao nên dùng OIDC để auth AWS thay vì static access key?

### a. Static access key

- Cách cũ thường tạo IAM user rồi lưu hai secret trong GitHub:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

- Đây là long-lived credential. Credential vẫn còn hiệu lực cho đến khi bị disable, rotate hoặc xóa.

- Rủi ro:

+ Secret có thể bị lộ qua log, cấu hình sai hoặc tài khoản GitHub bị compromise.
+ Phải tự rotate key định kỳ.
+ Key có thể tồn tại lâu dù workflow không chạy.
+ Khó giới hạn chính xác repo, branch hoặc environment nào được sử dụng key.
+ Nếu key có quyền quá lớn thì phạm vi ảnh hưởng khi bị lộ cũng lớn.

### b. OIDC hoạt động như thế nào?

- GitHub Actions phát hành một OIDC token cho workflow run.
- AWS kiểm tra token qua IAM OIDC identity provider.
- Nếu các claim như repository, branch hoặc environment đúng với trust policy, AWS STS cho workflow assume một IAM role.
- AWS trả về temporary credential có thời hạn ngắn.

```text
GitHub Actions
    ↓ OIDC token
AWS IAM kiểm tra trust policy
    ↓
Assume IAM role
    ↓
AWS STS temporary credentials
    ↓
Workflow gọi AWS API
```

- Workflow cần quyền lấy OIDC token:

```yaml
permissions:
  id-token: write
  contents: read
```

- Ví dụ:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v5
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions-deploy
    aws-region: ap-southeast-1
```

### c. Ưu điểm của OIDC

- Không lưu AWS secret key dài hạn trong GitHub.
- Credential được cấp khi workflow chạy và tự hết hạn.
- Có thể áp dụng least privilege bằng IAM role riêng cho từng mục đích.
- Trust policy có thể giới hạn:

+ GitHub organization.
+ Repository.
+ Branch hoặc tag.
+ GitHub Environment như `production`.

- Dễ thu hồi quyền bằng cách sửa trust policy hoặc IAM role, không phải tìm và rotate key ở nhiều repo.
- AWS CloudTrail ghi lại hoạt động của role session nên dễ audit hơn.
- Giảm nguy cơ một static key bị copy và sử dụng từ ngoài GitHub Actions.

### d. Ví dụ giới hạn production environment

- Trust policy có thể kiểm tra `sub` của GitHub OIDC token, ví dụ:

```json
{
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub": "repo:chiendz11/demo-app-ci:environment:production"
  }
}
```

- Khi đó chỉ job sử dụng GitHub Environment `production` trong đúng repository mới có thể assume role.

- OIDC không tự làm pipeline an toàn tuyệt đối. Vẫn cần:

+ IAM role theo least privilege.
+ Giới hạn trust policy cụ thể.
+ Environment approval cho production.
+ Pin hoặc kiểm soát third-party action.
+ Không cấp `id-token: write` cho job không cần truy cập AWS.

## Reference

- GitHub Actions re-run workflow và failed jobs: <https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs>
- GitHub Actions job dependency: <https://docs.github.com/actions/using-jobs/using-jobs-in-a-workflow>
- GitHub Actions job conditions: <https://docs.github.com/actions/using-jobs/using-conditions-to-control-job-execution>
- GitHub Actions concurrency: <https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs>
- AWS temporary credentials: <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html>
- AWS IAM security best practices: <https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html>
