# Task: Day 10 — Observability Basics

- **Intern**: Bùi Anh Chiến
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 5`
- **Branch**: `phase-1/week-2/day-5-observability`
- **Submitted at**: `2026-06-29 23:23` (timezone +07)
- **Time spent**: `4 giờ`

## 1. Mục tiêu

Tìm hiểu các khái niệm cơ bản của observability: log, metric, trace, SLI/SLO/SLA
và cardinality. Thực hành dựng stack Prometheus + Grafana + Node Exporter +
Blackbox Exporter bằng Docker Compose, tạo dashboard host/HTTP và mô tả alert rule
cho web app.

## 2. Cách chạy

Yêu cầu máy mentor có Docker, Docker Compose plugin và các port `3000`, `9090`,
`9100`, `9115` đang trống.

```bash
git clone https://github.com/chiendz11/devops-training-Chien.git
cd devops-training-Chien/phase-1/week-2/day-5-observability

docker compose up -d
docker compose ps
```

Kiểm tra Prometheus đã sẵn sàng và scrape target thành công:

```bash
curl -s http://localhost:9090/-/ready

curl -s http://localhost:9090/api/v1/targets \
  | jq -r '.data.activeTargets[] | [.labels.job, .scrapeUrl, .health] | @tsv'
```

Kết quả mong đợi có `node-exporter` và `blackbox-http` đều `up`.

Import Prometheus datasource và dashboard Grafana bằng API:

```bash
curl -s -u admin:admin \
  -H "Content-Type: application/json" \
  -X POST http://localhost:3000/api/datasources \
  -d '{
    "uid": "bfqlwmeglvu9sf",
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }'

jq '{dashboard: ., folderId: 0, overwrite: true}' \
  dashboards/host.json > /tmp/host-dashboard-import.json

curl -s -u admin:admin \
  -H "Content-Type: application/json" \
  -X POST http://localhost:3000/api/dashboards/db \
  --data-binary @/tmp/host-dashboard-import.json
```

Mở Grafana:

```text
http://localhost:3000
```

Login mặc định:

```text
username: admin
password: admin
```

Sau khi kiểm tra xong, dọn stack local:

```bash
docker compose down -v
```

## 3. Kết quả

- Trả lời lý thuyết observability trong [`notes.md`](./notes.md).
- Stack Docker Compose nằm trong [`compose.yml`](./compose.yml).
- Cấu hình scrape Prometheus nằm trong [`prometheus.yml`](./prometheus.yml).
- Dashboard Grafana export tại [`dashboards/host.json`](./dashboards/host.json).
- Mô tả alert rule latency, error rate, saturation trong [`alerts.md`](./alerts.md).
- Prometheus scrape được `node-exporter:9100` mỗi 15s.
- Prometheus dùng Blackbox Exporter probe `https://example.com` mỗi 30s.
- Dashboard có 4 panel:
  - CPU Usage.
  - Memory Usage.
  - Disk Free %.
  - HTTP Probe — example.com.
- Ảnh minh chứng nằm trong [`screenshots/`](./screenshots/).

## 4. Khó khăn & cách giải quyết

- Một số tag image ngắn như `prom/prometheus:v2.55`, `prom/node-exporter:v1.8`
  hoặc `prom/blackbox-exporter:v0.25` không pull được → dùng patch version thật:
  `v2.55.1`, `v1.8.2`, `v0.25.0`.
- Truy cập `http://localhost:9090/query` bị `404 page not found` → Prometheus UI
  dùng `/graph`, còn API query đúng là `/api/v1/query`.
- Grafana chạy trong container nên datasource không dùng `http://localhost:9090`
  được → dùng service name nội bộ Docker Compose là `http://prometheus:9090`.
- Dashboard export trên Grafana UI hơi khó tìm → export bằng JSON model hoặc gọi
  API `/api/dashboards/uid/<uid>` rồi lưu vào `dashboards/host.json`.
- Disk Free % có logic màu ngược CPU/Memory → disk càng thấp càng nguy hiểm, nên
  threshold dùng `Base red`, `15 yellow`, `30 green`.

## 5. Reference

- [Prometheus getting started](https://prometheus.io/docs/prometheus/2.55/getting_started/)
- [Prometheus HTTP API](https://prometheus.io/docs/prometheus/2.55/querying/api/)
- [Grafana Prometheus data source](https://grafana.com/docs/grafana/latest/datasources/prometheus/configure/)
- [Grafana dashboard export](https://grafana.com/docs/grafana/latest/dashboards/share-dashboards-panels/)
- [Prometheus node_exporter](https://github.com/prometheus/node_exporter)
- [Prometheus blackbox_exporter](https://github.com/prometheus/blackbox_exporter)

## 6. Self-check

- [x] Code chạy được trên máy sạch có Docker/Docker Compose.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại code 1 lượt.
