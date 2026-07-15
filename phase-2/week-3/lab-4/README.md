# Task: Kubernetes Helm chart + HPA & VPA

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 3`
- **Branch**: `phase-2/week-3/day-3-kubernetes-helm-chart-hpa-vpa`
- **Submitted at**: `2026-07-07 23:20` (timezone +07)
- **Time spent**: `~3 giờ`

## 1. Mục tiêu

Tạo Helm chart cho `demo-app`, tách values `dev/stg/prd`, bật HPA và VPA recommendation.

## 2. Cách chạy

### 2.1. Cài chart

```bash
cd phase-2/week-3/lab-4
# Scaffold chart ban đầu: helm create demo-app
for env in dev stg prd; do helm lint ./demo-app -f values/$env.yaml; done
git clone --depth 1 --branch vertical-pod-autoscaler-1.7.0 https://github.com/kubernetes/autoscaler.git /tmp/autoscaler
cd /tmp/autoscaler/vertical-pod-autoscaler && ./hack/vpa-up.sh
cd -
for env in dev stg prd; do helm upgrade --install demo-app ./demo-app -n lab4-$env --create-namespace -f values/$env.yaml --wait; done
kubectl -n lab4-dev get deploy,pod,svc,hpa,vpa
```

### 2.2. Chạy `test-connection.yaml` bằng Helm

File [`test-connection.yaml`](./demo-app/templates/tests/test-connection.yaml) là
Helm test hook vì có annotation `helm.sh/hook: test`. Không chạy trực tiếp
`kubectl apply -f demo-app/templates/tests/test-connection.yaml` vì file vẫn chứa
Go template như `{{ .Values.service.port }}`.

Xem YAML hook sau khi Helm render với values của môi trường dev:

```bash
helm template demo-app ./demo-app \
  -n lab4-dev \
  -f values/dev.yaml \
  --show-only templates/tests/test-connection.yaml

helm get hooks demo-app -n lab4-dev
```

Chạy test theo cách chuẩn. Helm tạo Pod `demo-app-test-connection`; container
BusyBox gọi Service `demo-app:80`. Command trả exit code `0` thì test `PASSED`:

```bash
helm test demo-app -n lab4-dev --logs
kubectl -n lab4-dev get pod demo-app-test-connection -o wide
kubectl -n lab4-dev logs pod/demo-app-test-connection
kubectl -n lab4-dev describe pod demo-app-test-connection
kubectl -n lab4-dev delete pod demo-app-test-connection --ignore-not-found
```

Kết quả mong đợi có `Phase: Succeeded` và `TEST SUITE: demo-app-test-connection`.

### 2.3. Render rồi apply thủ công để quan sát

Nếu muốn thực hành đúng thao tác `kubectl apply`, phải render template thành YAML
thuần trước:

```bash
helm template demo-app ./demo-app \
  -n lab4-dev \
  -f values/dev.yaml \
  --show-only templates/tests/test-connection.yaml \
  > /tmp/demo-app-test-connection.yaml

kubectl -n lab4-dev delete pod demo-app-test-connection --ignore-not-found
kubectl -n lab4-dev apply -f /tmp/demo-app-test-connection.yaml
kubectl -n lab4-dev wait \
  --for=jsonpath='{.status.phase}'=Succeeded \
  pod/demo-app-test-connection \
  --timeout=60s
kubectl -n lab4-dev logs pod/demo-app-test-connection
kubectl -n lab4-dev delete pod demo-app-test-connection
```

`kubectl apply` chỉ tạo Pod đã render và không thực thi lifecycle của Helm test
hook. Vì vậy khi kiểm tra chart hoàn chỉnh, em ưu tiên dùng `helm test`.

## 3. Kết quả

- Chart nằm trong `./demo-app`, env values nằm trong `./values/`.
- HPA scale replica theo CPU target; VPA recommend resource với `updateMode: Off`.
- Helm test kết nối được tới ClusterIP Service và kết thúc với trạng thái `Succeeded`.

## 4. Khó khăn & cách giải quyết

- App listen port `3000` nhưng Service port `80` → dùng `containerPort: 3000`, Service giữ port `80`.
- VPA không có sẵn trong Kubernetes core → cài VPA CRD/controller trước khi install chart.
- Không để HPA và VPA cùng tự chỉnh CPU/memory tự động → VPA dùng mode `Off`.

## 5. Reference

- Helm chart template: https://helm.sh/docs/chart_template_guide/getting_started/
- Kubernetes HPA: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- Kubernetes Autoscaler VPA: https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler

## 6. Self-check

- [x] Chart install được trên namespace sạch.
- [x] HPA và VPA render/apply được.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Đã review lại chart/values 1 lượt.
