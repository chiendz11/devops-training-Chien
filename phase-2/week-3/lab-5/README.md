# Task: Kubernetes ConfigMap, Secret, env injection và projected volume

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 4`
- **Branch**: `phase-2/week-3/day-4-kubernetes-configmap-secret`
- **Submitted at**: `2026-07-12` (timezone +07)
- **Time spent**: `~2 giờ`

## 1. Mục tiêu

Refactor Helm chart `demo-app` để app lấy cấu hình từ `ConfigMap` và `Secret`. Pod vừa nhận config qua environment variables, vừa mount config/secret thành file bằng projected volume.

## 2. Cách chạy

```bash
cd phase-2/week-3/lab-4

helm lint ./demo-app -f values/dev.yaml
helm template demo-dev ./demo-app -f values/dev.yaml

helm upgrade --install demo-dev ./demo-app \
  -n lab4-dev \
  --create-namespace \
  -f values/dev.yaml \
  --set vpa.enabled=false \
  --wait

kubectl -n lab4-dev get configmap,secret,deploy,pod
kubectl -n lab4-dev describe deploy demo-dev-demo-app
```

Verify env injection:

```bash
POD=$(kubectl -n lab4-dev get pod -l app.kubernetes.io/instance=demo-dev -o jsonpath='{.items[0].metadata.name}')
kubectl -n lab4-dev exec "$POD" -- env | grep -E 'NAME|APP_ENV|LOG_LEVEL|FEATURE_GREETING|API_KEY|APP_CONFIG_DIR'
```

Verify projected volume:

```bash
kubectl -n lab4-dev exec "$POD" -- ls -l /etc/demo-app/config
kubectl -n lab4-dev exec "$POD" -- sh -c 'cat /etc/demo-app/config/APP_ENV && echo'
```

## 3. Kết quả

- `ConfigMap` chứa config không nhạy cảm: `NAME`, `APP_ENV`, `LOG_LEVEL`, `FEATURE_GREETING`.
- `Secret` chứa secret demo: `API_KEY`, `DB_PASSWORD`.
- `Deployment` dùng `envFrom` để inject env từ ConfigMap/Secret.
- `Deployment` dùng projected volume mount ConfigMap + Secret vào `/etc/demo-app/config`.
- Pod có checksum annotation để rollout khi ConfigMap/Secret thay đổi.
- Screenshots nằm trong `./screenshots/`.

## 4. Khó khăn & cách giải quyết

- Config và secret cần dùng được ở cả env var và file → dùng `envFrom` kết hợp `projected` volume.
- ConfigMap/Secret đổi nhưng Deployment không tự rollout → thêm `checksum/config` và `checksum/secret` annotation.
- Cluster chưa cài VPA CRD nên install bị lỗi `VerticalPodAutoscaler` → với Day 4 dùng `--set vpa.enabled=false` vì bài tập tập trung vào ConfigMap/Secret.
- Secret demo nằm trong values để dễ lab → ghi rõ không dùng secret thật trong Git.

## 5. Self-check

- [x] `helm lint` pass với `dev/stg/prd`.
- [x] Có ConfigMap template.
- [x] Có Secret template.
- [x] Có env injection.
- [x] Có projected volume.
