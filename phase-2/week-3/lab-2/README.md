# Task: Kubernetes — Deployment & Rolling Update

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 2`
- **Branch**: `phase-2/week-3/day-2-kubernetes-deployment-rolling-update`
- **Submitted at**: `2026-07-06 21:49` (timezone +07)
- **Time spent**: `4 giờ`

## 1. Mục tiêu

Triển khai demo app bằng Deployment 3 replica và ClusterIP Service; thực hành rolling update `v1.1.0 → v1.2.0` và rollback.

## 2. Cách chạy

```bash
k3d cluster create dev --agents 2 -p "8080:80@loadbalancer"
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/deployment.yaml -f manifests/service.yaml
kubectl -n lab2 rollout status deployment/demo-app --timeout=120s
kubectl -n lab2 set image deployment/demo-app demo-app=ghcr.io/chiendz11/demo-app:v1.2.0
kubectl -n lab2 rollout status deployment/demo-app --timeout=120s
kubectl -n lab2 rollout undo deployment/demo-app
kubectl -n lab2 get deployment,pods,service -o wide
kubectl -n lab2 port-forward service/demo-app 8081:80
# Cleaning
kubectl delete namespace lab2
k3d cluster delete dev
```

## 3. Kết quả

- Deployment đạt `3/3`, Service có endpoint; rolling update và rollback thành công, với ảnh minh chứng trong [`screenshots/`](./screenshots/).

## 4. Khó khăn & cách giải quyết

- `runAsNonRoot` không xác minh được user `node` → đặt UID/GID `1000`.
- Service không có endpoint → đồng bộ selector với label của Pod.

## 5. Reference

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

## 6. Self-check

- [x] Code chạy được trên máy sạch.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại code 1 lượt.
