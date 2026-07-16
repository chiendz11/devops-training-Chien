# Task: Kubernetes — Ingress & TLS

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 2`
- **Branch**: `phase-2/week-3/day-2-kubernetes-ingress`
- **Submitted at**: `2026-07-07 01:07` (timezone +07)
- **Time spent**: `3 giờ`

## 1. Mục tiêu

Cài ingress-nginx, route `app.local` tới `demo-app:80` và terminate TLS bằng cert-manager với SelfSigned ClusterIssuer.

## 2. Cách chạy

```bash
k3d cluster create dev --agents 2 -p "8080:80@loadbalancer" -p "8443:443@loadbalancer" --k3s-arg "--disable=traefik@server:*"
kubectl apply -f ../lab-2/manifests/namespace.yaml && kubectl apply -f ../lab-2/manifests/deployment.yaml -f ../lab-2/manifests/service.yaml
helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace --version 4.15.1 --set controller.service.type=LoadBalancer --wait
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.3/cert-manager.yaml && kubectl wait -n cert-manager --for=condition=Available deployment --all --timeout=180s
kubectl apply -f manifests/cluster-issuer.yaml && kubectl wait --for=condition=Ready clusterissuer/selfsigned-cluster-issuer --timeout=60s
kubectl apply -f manifests/certificate.yaml && kubectl wait -n lab2 --for=condition=Ready certificate/app-local --timeout=120s
kubectl apply -f manifests/ingress.yaml
echo "127.0.0.1 app.local" | sudo tee -a /etc/hosts
curl --noproxy '*' http://app.local:8080/ && curl --noproxy '*' -k https://app.local:8443/health
# Cleaning
kubectl delete namespace lab2
k3d cluster delete dev
```

## 3. Kết quả

- Ingress route HTTP/HTTPS thành công; certificate và TLS Secret đều Ready. Minh chứng nằm trong [`screenshots/`](./screenshots/).

## 4. Khó khăn & cách giải quyết

- Traefik mặc định chiếm port `80/443` → tạo k3d cluster với `--disable=traefik`.
- Self-signed certificate không được client tin cậy → dùng `curl -k` cho môi trường local.

## 5. Reference

- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/deploy/), [cert-manager SelfSigned](https://cert-manager.io/docs/configuration/selfsigned/)

## 6. Self-check

- [x] Code chạy được trên máy sạch.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại code 1 lượt.
