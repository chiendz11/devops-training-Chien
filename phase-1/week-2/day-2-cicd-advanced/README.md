# Task: Day 7 - CI/CD Advanced

- **Intern**: Bùi Anh Chiến
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 2`
- **Branch**: `phase-1/week-2/day-2-cicd-advanced`
- **Submitted at**: `2026-06-24 07:44` (timezone +07)
- **Time spent**: `~4 giờ`

## 1. Mục tiêu

Mở rộng repo `demo-app` của Day 6 để luyện các phần nâng cao hơn của GitHub Actions: matrix job, reusable workflow, environment approval, tag-based release và các tình huống debug khi pipeline fail.

Phần workflow chạy thật được làm ở repo riêng `demo-app-ci`, còn repo training này lưu README, notes và screenshot để mentor review lại.

## 2. Cách chạy

### 2.1. Clone repo nộp bài

```bash
git clone git@github.com:chiendz11/devops-training-Chien.git
cd devops-training-Chien

git switch phase-1/week-2/day-2-cicd-advanced

cd phase-1/week-2/day-2-cicd-advanced
ls -la
```

Kết quả mong đợi:

```text
README.md
notes.md
screenshots/
```

### 2.2. Xem repo demo-app chạy workflow thật

```bash
gh repo clone chiendz11/demo-app-ci
cd demo-app-ci

ls .github/workflows
```

Các workflow chính:

```text
.github/workflows/ci-trivy.yml
.github/workflows/reusable-build.yml
.github/workflows/deploy.yml
.github/workflows/release.yml
```

Trong đó:

- `ci-trivy.yml`: chạy lint, test matrix, gọi reusable workflow để build image.
- `reusable-build.yml`: nhận `image_name` và `image_tag`, build image, tạo SBOM, scan Trivy và push image khi chạy trên `main`.
- `deploy.yml`: deploy giả lập cho `staging` và `production`.
- `release.yml`: chạy khi push tag dạng `v*.*.*`, build release image và tạo GitHub Release tự động.

### 2.3. Xem lại workflow bằng GitHub CLI

```bash
gh workflow view ci-trivy.yml --repo chiendz11/demo-app-ci --yaml
gh workflow view reusable-build.yml --repo chiendz11/demo-app-ci --yaml
gh workflow view deploy.yml --repo chiendz11/demo-app-ci --yaml
gh workflow view release.yml --repo chiendz11/demo-app-ci --yaml
```

### 2.4. Xem lại các run đã pass / đang chờ approval

Xem CI matrix đã pass:

```bash
gh run view 28018137966 \
  --repo chiendz11/demo-app-ci \
  --log
```

Xem release workflow đã tạo GitHub Release:

```bash
gh run view 28021187055 \
  --repo chiendz11/demo-app-ci \
  --log
```

Xem deploy production đang chờ approval:

```bash
gh run view 28021187007 \
  --repo chiendz11/demo-app-ci
```

Xem release note được tạo tự động:

```bash
gh release view v1.0.1 \
  --repo chiendz11/demo-app-ci
```

### 2.5. Nếu mentor muốn reproduce lại từ đầu

Bước này dùng repo `demo-app-ci` vì workflow cần chạy thật trên GitHub Actions.

```bash
gh repo clone chiendz11/demo-app-ci
cd demo-app-ci

git switch -c feat/reproduce-day-7
```

Tạo hoặc kiểm tra matrix trong `ci-trivy.yml`:

```yaml
strategy:
  fail-fast: false
  matrix:
    node: ['18', '20', '22']
    os: [ubuntu-22.04, ubuntu-24.04]
    exclude:
      - node: '18'
        os: ubuntu-24.04
```

Tạo reusable workflow `.github/workflows/reusable-build.yml` có input:

```yaml
on:
  workflow_call:
    inputs:
      image_name:
        required: true
        type: string
      image_tag:
        required: true
        type: string
```

Trong `ci-trivy.yml`, gọi reusable workflow:

```yaml
docker:
  needs: test
  uses: ./.github/workflows/reusable-build.yml
  with:
    image_name: ghcr.io/${{ github.repository_owner }}/demo-app
    image_tag: sha-${{ github.sha }}
  secrets: inherit
```

Push branch và mở PR:

```bash
git add .github/workflows
git commit -m "feat(cicd): add advanced workflow features"
git push -u origin feat/reproduce-day-7

gh pr create \
  --repo chiendz11/demo-app-ci \
  --base main \
  --head feat/reproduce-day-7 \
  --title "feat(cicd): add advanced workflow features" \
  --body "Add matrix test, reusable build workflow, deployment environments and tag-based release."
```

Sau khi PR pass và merge vào `main`, tạo tag release:

```bash
git switch main
git pull origin main

git tag -a v1.0.2 -m "release: v1.0.2"
git push origin v1.0.2
```

Tag `v1.0.2` sẽ trigger:

- `release.yml`: tạo GitHub Release + release note tự động.
- `deploy.yml`: tạo job deploy production và chờ approval ở environment `production`.

Lưu ý: environment `production` cần tạo trên GitHub UI:

```text
Repo demo-app-ci
→ Settings
→ Environments
→ New environment: production
→ Required reviewers
→ chọn chính mình
```

## 3. Kết quả

### Part A - Matrix

Test job chạy theo matrix:

```text
Node 18 / ubuntu-22.04
Node 20 / ubuntu-22.04
Node 20 / ubuntu-24.04
Node 22 / ubuntu-22.04
Node 22 / ubuntu-24.04
```

Combo `Node 18 / ubuntu-24.04` đã bị loại bằng `exclude`, nên tổng cộng còn 5 combo.

- Screenshot: `./screenshots/matrix-run.png`
- CI run pass: https://github.com/chiendz11/demo-app-ci/actions/runs/28018137966
- Run number: `#10`

### Part B - Reusable workflow

Đã tách logic build image sang `.github/workflows/reusable-build.yml`.

Workflow `ci-trivy.yml` gọi lại bằng:

```yaml
uses: ./.github/workflows/reusable-build.yml
```

Reusable workflow nhận:

- `image_name`
- `image_tag`

Việc này giúp tránh copy lại logic build/scan/push ở nhiều workflow khác nhau.

- Screenshot: `./screenshots/reusable-workflow.png`

### Part C - Environment + approval

Đã tạo 2 environment trên GitHub:

- `staging`: chạy ngay khi merge vào `main`.
- `production`: chạy khi push tag `v*.*.*` và bị block để chờ approval.

Deploy hiện tại chỉ là giả lập bằng `echo log`, chưa SSH vào server thật.

- Screenshot: `./screenshots/production-approval.png`
- Deploy run đang chờ approval: https://github.com/chiendz11/demo-app-ci/actions/runs/28021187007
- Deploy run number: `#4`

### Part D - Tag-based release

Đã tạo workflow `release.yml` chạy khi push tag dạng:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

Khi push tag `v1.0.1`, workflow tự tạo GitHub Release bằng `softprops/action-gh-release`.

- Release page: https://github.com/chiendz11/demo-app-ci/releases/tag/v1.0.1
- Release workflow run: https://github.com/chiendz11/demo-app-ci/actions/runs/28021187055
- Release run number: `#1`
- Screenshot: `./screenshots/release-page.png`

GitHub Release page có phần `What's Changed`, đây chính là release note được GitHub sinh tự động từ PR/commit giữa 2 tag.

### Part E - Failure scenarios

Đã trả lời trong `notes.md`:

- Khi pipeline fail ở step push thì retry nhanh thế nào để không build lại quá nhiều.
- Cách debug job chỉ fail trên runner.
- So sánh `needs`, `if`, `concurrency group`.
- Vì sao nên dùng OIDC để auth AWS thay vì static access key.

### Link liên quan

- Repo có workflow: https://github.com/chiendz11/demo-app-ci
- GHCR image/package: https://github.com/users/chiendz11/packages/container/package/demo-app
- Repo nộp bài: https://github.com/chiendz11/devops-training-Chien

## 4. Khó khăn & cách giải quyết

- **Matrix ban đầu dễ nhầm số combo** → Ban đầu có 3 Node version × 2 OS = 6 combo. Sau khi exclude `node 18 + ubuntu-24.04` thì còn đúng 5 combo.

- **Reusable workflow cần khai báo đúng `workflow_call`** → Nếu thiếu `on.workflow_call` hoặc thiếu input `image_name`, `image_tag` thì workflow cha không gọi được. Em tách phần build image ra file riêng để `ci` và `release` đều có thể tái sử dụng.

- **Production job bị `waiting` không phải lỗi** → Vì environment `production` có required reviewer, nên job sẽ dừng lại để chờ approve. Đây là behavior đúng khi muốn kiểm soát deploy production.

- **Push tag có thể trigger nhiều workflow cùng lúc** → Khi push `v1.0.1`, cả `release.yml` và `deploy.yml` đều match event tag. Em tách rõ: `release.yml` tạo release note, còn `deploy.yml` xử lý deploy production và approval.

- **Trivy scan có thể làm pipeline fail do CVE từ base image** → Cần phân biệt lỗi code của mình với lỗi package từ base image. Cách xử lý là update base image, chạy `apk upgrade --no-cache`, hoặc chọn base image ít package hơn nếu phù hợp.

## 5. Reference

- GitHub Actions matrix: https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
- Reusing workflows: https://docs.github.com/en/actions/sharing-automations/reusing-workflows
- GitHub Actions environments: https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment
- Events that trigger workflows: https://docs.github.com/en/actions/reference/events-that-trigger-workflows
- softprops/action-gh-release: https://github.com/softprops/action-gh-release
- GitHub Actions OIDC: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect

## 6. Self-check

- [x] Code chạy được trên máy sạch.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại code 1 lượt.
- [x] Matrix chạy 5 combo sau khi exclude 1 combo.
- [x] Reusable workflow được gọi từ workflow chính.
- [x] Production deploy job bị block chờ approval.
- [x] Release tag tạo ra GitHub Release tự động.
