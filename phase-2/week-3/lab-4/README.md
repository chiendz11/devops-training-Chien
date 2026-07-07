# Task: Kubernetes Helm chart

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 3`
- **Branch**: `phase-2/week-3/day-3-kubernetes-helm-chart`
- **Submitted at**: `2026-07-07 21:34` (timezone +07)
- **Time spent**: `~2 giờ`

## 1. Mục tiêu

Tạo Helm chart cho `demo-app` và deploy được vào Kubernetes bằng `helm upgrade --install`.
Tách cấu hình `dev`, `stg`, `prd`, thực hành upgrade/rollback release và package chart.

## 2. Cách chạy

```bash
cd phase-2/week-3/lab-4
# Scaffold chart ban đầu: helm create demo-app
helm lint ./demo-app -f values/dev.yaml
helm upgrade --install demo-app ./demo-app -n lab4-dev --create-namespace -f values/dev.yaml --wait
helm upgrade --install demo-app ./demo-app -n lab4-stg --create-namespace -f values/stg.yaml --wait
helm upgrade --install demo-app ./demo-app -n lab4-prd --create-namespace -f values/prd.yaml --wait
kubectl -n lab4-dev rollout status deployment/demo-app
```

## 3. Kết quả

- Helm chart nằm trong `./demo-app`.
- Values theo môi trường nằm trong `./values/dev.yaml`, `./values/stg.yaml`, `./values/prd.yaml`.
- Screenshots/log output nằm trong `./screenshots/`.

## 4. Khó khăn & cách giải quyết

- Pod bị `CrashLoopBackOff` do app listen port `3000` nhưng chart probe vào port `80` → thêm `containerPort: 3000` và giữ Service port `80`.
- Rollback về revision cũ vẫn lỗi vì revision đó chứa chart sai port → uninstall release cũ, fix chart rồi install lại từ đầu.

## 5. Reference

- Helm chart template: https://helm.sh/docs/chart_template_guide/getting_started/
- Helm upgrade: https://helm.sh/docs/helm/helm_upgrade/
- Kubernetes Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

## 6. Self-check

- [x] Chart install được trên namespace sạch.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại chart/values 1 lượt.
