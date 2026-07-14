# Task: Supply Chain Security với Trivy, Cosign và SBOM

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 4 / Day 5`
- **Branch**: `phase-2/week-4/day-5-Trivy-cosign-SBOM`
- **Submitted at**: `2026-07-14` (timezone +07)
- **Time spent**: `~3 giờ`
- **Workflow repository**: [chiendz11/demo-app-ci](https://github.com/chiendz11/demo-app-ci)

## 1. Mục tiêu

Thêm các bước kiểm tra supply chain cho Docker image: tạo SPDX SBOM, scan lỗ hổng HIGH/CRITICAL bằng Trivy, ký image digest bằng Cosign keyless và bắt buộc CD verify chữ ký trước khi deploy.

## 2. Cách chạy

PR vào `main` chạy lint, test, build, tạo SBOM và Trivy scan. Sau khi merge, CI push image lên GHCR, ký digest và upload metadata; workflow CD tự tải artifact để verify.

```bash
gh run list --repo chiendz11/demo-app-ci --workflow ci-trivy.yml --limit 5
gh run list --repo chiendz11/demo-app-ci --workflow deploy.yml --limit 5

CI_RUN_ID=$(gh run list --repo chiendz11/demo-app-ci \
  --workflow ci-trivy.yml --branch main --event push --limit 1 \
  --json databaseId --jq '.[0].databaseId')

gh run view "$CI_RUN_ID" --repo chiendz11/demo-app-ci --web
gh run download "$CI_RUN_ID" --repo chiendz11/demo-app-ci --dir /tmp/day5-artifacts
find /tmp/day5-artifacts -type f -print
```

## 3. Kết quả

- PR pipeline chạy thành công: [ảnh pipeline](./screenshots/PR_CI_passed.png).
- CI tạo SPDX SBOM và Trivy chặn image nếu có CVE HIGH/CRITICAL.
- Image được ký bằng GitHub OIDC, không lưu private signing key trong secret.
- Metadata chứa `image@sha256:...` được upload: [ảnh artifact](./screenshots/signed_artifact.png).
- CD tải đúng artifact theo run ID/SHA, chạy `cosign verify` rồi mới deploy:
  [ảnh deploy](./screenshots/deploy_passed.png).
- Danh sách artifact của run: [ảnh artifact list](./screenshots/artifacts_pushed_list.png).

## 4. Khó khăn & cách giải quyết

- Tag Docker có thể bị ghi đè → CI truyền immutable digest qua GitHub Actions artifact.
- Artifact không tự chứng minh image đáng tin → CD kiểm tra metadata và verify Cosign lại.
- PR không có quyền push/ký image → chỉ scan ở PR; push, sign và upload khi merge `main`.

## 5. Reference

- [Trivy GitHub Action](https://github.com/aquasecurity/trivy-action)
- [Cosign keyless signing](https://docs.sigstore.dev/cosign/signing/signing_with_containers/)
- [Anchore SBOM Action](https://github.com/anchore/sbom-action)
- [GitHub Actions artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)

## 6. Self-check

- [x] Trivy và SBOM chạy trong CI.
- [x] Image được ký theo immutable digest và CD verify trước deploy.
- [x] Không hard-code registry token hoặc private signing key.
- [x] Screenshot minh chứng được lưu trong `screenshots/`.
