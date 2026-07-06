# Task: Kubernetes — First Cluster

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 1 / Week 3 / Day 1`
- **Branch**: `phase-1/week-3/day-1-kubernetes-first-cluster`
- **Submitted at**: `2026-07-06` (timezone +07)
- **Time spent**: `2 giờ`

## 1. Mục tiêu

Tạo Kubernetes cluster local bằng k3d, làm quen với `kubectl`, deploy Pod Nginx
và dùng ClusterIP Service để truy cập Pod trong cluster.

## 2. Cách chạy

Máy mentor cần có Docker, k3d và kubectl:

```bash
k3d cluster create dev --agents 2 -p "8080:80@loadbalancer"
kubectl create namespace lab1
kubectl apply -f manifests/
kubectl wait -n lab1 --for=condition=Ready pod/web --timeout=120s
kubectl get nodes && kubectl get all -n lab1
kubectl run curl-test -n lab1 --image=curlimages/curl --restart=Never --rm -i -- curl -fsS http://web
```

Dọn dẹp sau khi kiểm tra: `kubectl delete namespace lab1`.

## 3. Kết quả

- Cluster gồm một server/control-plane và hai agent node đều `Ready`.
- Pod `web` chạy image `nginx:alpine` và có trạng thái `Running`.
- Service `web` loại ClusterIP chuyển traffic từ port `80` tới Pod.
- Manifest nằm trong [`manifests/`](./manifests/) và ảnh minh chứng trong [`screenshots/`](./screenshots/).

## 4. Khó khăn & cách giải quyết

- ClusterIP không truy cập trực tiếp từ host → kiểm tra bằng Pod `curl-test`.
- YAML export chứa state runtime → rút gọn thành manifest khai báo để chạy lại trên cluster sạch.

## 5. Reference

- [k3d](https://k3d.io/stable/), [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## 6. Self-check

- [x] Cluster có ba node `Ready`.
- [x] Pod và Service tạo được từ manifest.
- [x] Service trả về trang Nginx trong cluster.
