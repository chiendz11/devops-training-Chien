# Notes: Kubernetes Monitoring Stack

## 1. Thành phần chính

```text
kube-prometheus-stack
├── Prometheus Operator
├── Prometheus
├── Alertmanager
├── Grafana
├── kube-state-metrics
└── node-exporter

Loki
└── lưu log dạng label + stream

Alloy
└── collect log từ Pod rồi push sang Loki
```

## 2. Vì sao dùng kube-prometheus-stack?

Chart này đóng gói sẵn nhiều thành phần monitoring chuẩn cho Kubernetes. Thay vì tự tạo từng Deployment/ServiceMonitor/PrometheusRule, mình dùng chart để có cấu hình gần thực tế hơn và dễ upgrade.

## 3. Vì sao thêm Loki + Alloy?

Prometheus phù hợp cho metric, còn Loki phù hợp cho log. Alloy đóng vai trò collector, chạy trên cluster, discovery Pod log rồi push về Loki.

Flow log:

```text
Pod logs
  ↓
Alloy DaemonSet
  ↓
Loki
  ↓
Grafana Explore
```

## 4. Grafana ingress

Grafana được expose bằng Ingress host `grafana.local`. Với k3d đã map loadbalancer `8080:80`, truy cập bằng:

```text
http://grafana.local:8080
```

Credential admin nằm trong Kubernetes Secret `grafana-admin-credentials`. File values chỉ lưu tên Secret và key cần đọc, không lưu password thật trong Git.

## 5. Dashboard 1860

Dashboard 1860 là Node Exporter Full. Dashboard này đọc metric từ node-exporter để xem CPU, memory, disk, network của node.

## 6. Alert PodRestartHigh

Rule:

```promql
increase(kube_pod_container_status_restarts_total[10m]) > 3
```

Ý nghĩa: nếu container restart hơn 3 lần trong 10 phút thì có thể đang CrashLoopBackOff hoặc app lỗi liên tục.
