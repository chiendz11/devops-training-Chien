# Task: Kubernetes — First Cluster

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 1`
- **Branch**: `phase-1/week-3/day-1-kubernetes-first-cluster`
- **Submitted at**: `2026-07-06` (timezone +07)
- **Time spent**: `4 giờ`

## 1. Mục tiêu

Tạo cluster k3d, deploy Pod Nginx và truy cập Pod qua ClusterIP Service.

## 2. Cách chạy

Máy mentor cần có Docker, k3d và kubectl:

```bash
k3d cluster create dev --agents 2 -p "8080:80@loadbalancer"
kubectl create namespace lab1
kubectl run web -n lab1 --image=nginx:alpine --port=80 --labels="app=web"
kubectl wait -n lab1 --for=condition=Ready pod/web --timeout=120s
kubectl expose pod web -n lab1 --type=ClusterIP --port=80 --target-port=80
kubectl get nodes && kubectl get all -n lab1
kubectl run curl-test -n lab1 --image=curlimages/curl --restart=Never --rm -i -- curl -fsS http://web
kubectl get pod web -n lab1 -o yaml > manifests/web-pod.yaml
kubectl get service web -n lab1 -o yaml > manifests/web-service.yaml
```

Dọn dẹp sau khi kiểm tra:

```bash
kubectl delete namespace lab1
k3d cluster delete dev
```

## 3. Kết quả

- Cluster gồm một server/control-plane và hai agent node đều `Ready`.
- Pod Nginx `web` ở trạng thái `Running`; ClusterIP Service chuyển port `80` tới Pod.
- Manifest được export sau khi tạo resource; ảnh minh chứng nằm trong [`screenshots/`](./screenshots/).

## 4. Khó khăn & cách giải quyết

- ClusterIP không truy cập trực tiếp từ host → kiểm tra bằng Pod `curl-test`.
- YAML export chứa state runtime → loại bỏ field do cluster tự sinh trước khi commit.

## 5. Reference

- [k3d](https://k3d.io/stable/), [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## 6. Self-check

- [x] Pod và Service được tạo bằng lệnh `kubectl`.
- [x] Service trả về trang Nginx trong cluster.
