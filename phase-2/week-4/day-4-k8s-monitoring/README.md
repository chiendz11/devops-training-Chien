# Task: Kubernetes Monitoring với Prometheus, Grafana, Loki và Alloy

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 4 / Day 4`
- **Branch**: `phase-2/week-4/day-4-k8s-monitoring`
- **Submitted at**: `2026-07-14` (timezone +07)
- **Time spent**: `~3 giờ`

## 1. Mục tiêu

Cài monitoring stack trên Kubernetes bằng Helm gồm `kube-prometheus-stack`, Grafana, Loki và Alloy. Expose Grafana qua Ingress, import dashboard Node Exporter Full ID `1860`, và tạo alert rule `PodRestartHigh`.

## 2. Cách chạy

Tạo cluster k3d không cài Traefik để cổng `8080` được dùng bởi ingress-nginx:

```bash
k3d cluster create dev \
  --servers 1 \
  --agents 2 \
  -p "8080:80@loadbalancer" \
  -p "8443:443@loadbalancer" \
  --k3s-arg "--disable=traefik@server:*" \
  --wait
```

Thêm Helm repo:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

Cài ingress-nginx nếu cluster chưa có:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --wait \
  --timeout 10m
```

Cài monitoring namespace:

```bash
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
```

Tạo credential Grafana ở Kubernetes Secret. Password được sinh tại máy chạy lab và không ghi vào Git:

```bash
GRAFANA_ADMIN_USER="admin"
GRAFANA_ADMIN_PASSWORD="$(openssl rand -hex 24)"

kubectl -n monitoring create secret generic grafana-admin-credentials \
  --from-literal=admin-user="$GRAFANA_ADMIN_USER" \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

printf 'Grafana username: %s\n' "$GRAFANA_ADMIN_USER"
printf 'Grafana password: %s\n' "$GRAFANA_ADMIN_PASSWORD"
unset GRAFANA_ADMIN_PASSWORD
```

Cài Prometheus + Grafana + Alertmanager:

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values/kube-prometheus-stack.yaml \
  --wait \
  --timeout 15m
```

Cài Loki:

```bash
helm upgrade --install loki grafana/loki \
  -n monitoring \
  -f values/loki.yaml \
  --wait \
  --timeout 10m
```

Cài Alloy để thu Kubernetes logs và đẩy sang Loki:

```bash
helm upgrade --install alloy grafana/alloy \
  -n monitoring \
  -f values/alloy.yaml \
  --wait \
  --timeout 10m
```

Thêm host local để truy cập Grafana:

```bash
grep -q 'grafana.local' /etc/hosts || \
  echo '127.0.0.1 grafana.local' | sudo tee -a /etc/hosts
```

Truy cập:

```text
http://grafana.local:8080
```

Nếu cần xem lại credential trong cluster:

```bash
kubectl -n monitoring get secret grafana-admin-credentials \
  -o jsonpath='{.data.admin-user}' | base64 --decode
echo

kubectl -n monitoring get secret grafana-admin-credentials \
  -o jsonpath='{.data.admin-password}' | base64 --decode
echo
```

## 3. Kiểm tra

```bash
kubectl -n monitoring get pod,svc,ingress
kubectl -n monitoring get prometheusrule | grep pod-restart
kubectl -n monitoring get ds alloy
```

Kiểm tra dashboard `1860`:

```text
Grafana → Dashboards → Node Exporter Full
```

Kiểm tra Loki datasource:

```text
Grafana → Explore → Loki → query: {namespace="monitoring"}
```

## 4. Test alert PodRestartHigh

Tạo pod crashloop:

```bash
kubectl apply -f manifests/alert-test-crashloop.yaml
kubectl -n alert-test get pod -w
```

Port-forward Prometheus:

```bash
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Mở:

```text
http://localhost:9090/alerts
```

Tìm alert:

```text
PodRestartHigh
```

## 5. Kết quả

- `kube-prometheus-stack` cài Prometheus Operator, Prometheus, Alertmanager, Grafana, kube-state-metrics và node-exporter.
- Grafana expose qua Ingress host `grafana.local`.
- Dashboard Node Exporter Full ID `1860` được cấu hình sẵn bằng Helm values.
- Loki chạy dạng single-binary cho lab local.
- Alloy chạy dạng DaemonSet, đọc log Pod Kubernetes và push sang Loki.
- PrometheusRule `PodRestartHigh` cảnh báo khi container restart hơn 3 lần trong 10 phút.

## 6. Khó khăn & cách giải quyết

- `kube-prometheus-stack` sinh nhiều CRD nên cần cài bằng Helm chart chính thức thay vì manifest tự viết.
- Loki production có nhiều mode phức tạp, lab local dùng `SingleBinary` để đơn giản và dễ reproduce.
- Grafana dashboard 1860 dùng `gnetId` trong Helm values để không phải commit JSON dashboard lớn.
- Alloy cần RBAC để discovery Pod và DaemonSet để chạy trên node, nên cấu hình qua chart `grafana/alloy`.
- Credential Grafana không đặt trong values; chart chỉ tham chiếu Secret `grafana-admin-credentials` được tạo trực tiếp trên cluster.

## 7. Screenshot minh chứng

- `cluster_up_without_traefik.png`: cluster k3d gồm 1 server, 2 agent và không có Traefik.
- `monitoring_namespace_created.png`: namespace monitoring được tạo.
- `kube_prometheus_stack_chart_install.png`: kube-prometheus-stack cài thành công.
- `ingress_resource_created.png`: Ingress `grafana.local` dùng ingress-nginx.
- `loki_object_created.png`: Loki StatefulSet và PVC chạy ổn định.
- `alloy_object_created.png`: Alloy DaemonSet chạy trên các node.
- `grafana_dashboard.png`: dashboard Node Exporter Full ID 1860.
- `alert_firing.png`: alert `PodRestartHigh` chuyển sang trạng thái firing.

## 8. Dọn lab

```bash
kubectl delete -f manifests/alert-test-crashloop.yaml --ignore-not-found

helm uninstall alloy -n monitoring
helm uninstall loki -n monitoring
helm uninstall monitoring -n monitoring
kubectl delete namespace monitoring
```

Nếu không dùng ingress-nginx cho lab khác:

```bash
helm uninstall ingress-nginx -n ingress-nginx
kubectl delete namespace ingress-nginx
```

Hoặc xoá toàn bộ cluster lab:

```bash
k3d cluster delete dev
```

## 9. Reference

- kube-prometheus-stack Helm chart: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- Grafana Loki Helm chart: https://github.com/grafana/loki/tree/main/production/helm/loki
- Grafana Alloy Helm chart: https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy
- Dashboard 1860 Node Exporter Full: https://grafana.com/grafana/dashboards/1860-node-exporter-full/
