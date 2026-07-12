# Task: Kubernetes RBAC, ServiceAccount và NetworkPolicy

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 6`
- **Branch**: `phase-2/week-3/day-6-kubernetes-rbac-networkpolicy`
- **Submitted at**: `2026-07-12` (timezone +07)
- **Time spent**: `~2 giờ`

## 1. Mục tiêu

Tạo Helm chart để demo RBAC, ServiceAccount và NetworkPolicy. Lab chứng minh `readonly-sa` chỉ xem được resource, `deployer-sa` có quyền deploy, và DB chỉ nhận traffic từ app client.

## 2. Cách chạy

```bash
cd phase-2/week-3/lab-7-rbac-networkpolicy

helm lint ./charts/rbac-netpol-lab

helm template rbac-netpol ./charts/rbac-netpol-lab \
  -n rbac-netpol-lab \
  > rendered.yaml
```

Cài lần đầu chưa bật NetworkPolicy để chứng minh traffic mặc định đang mở:

```bash
helm upgrade --install rbac-netpol ./charts/rbac-netpol-lab \
  -n rbac-netpol-lab \
  --create-namespace \
  --set networkPolicy.enabled=false \
  --wait
```

Kiểm tra RBAC:

```bash
kubectl auth can-i list pods \
  --as=system:serviceaccount:rbac-netpol-lab:readonly-sa \
  -n rbac-netpol-lab

kubectl auth can-i create deployments \
  --as=system:serviceaccount:rbac-netpol-lab:readonly-sa \
  -n rbac-netpol-lab

kubectl auth can-i create deployments \
  --as=system:serviceaccount:rbac-netpol-lab:deployer-sa \
  -n rbac-netpol-lab
```

Bật NetworkPolicy:

```bash
helm upgrade --install rbac-netpol ./charts/rbac-netpol-lab \
  -n rbac-netpol-lab \
  --set networkPolicy.enabled=true \
  --wait
```

Test network:

```bash
kubectl -n rbac-netpol-lab exec deploy/app-client -- \
  curl -sS --connect-timeout 3 http://db

kubectl -n rbac-netpol-lab exec deploy/attacker -- \
  curl -sS --connect-timeout 3 http://db || echo "blocked as expected"
```

## 3. Kết quả

- Helm chart render ServiceAccount, Role, RoleBinding, Deployment, Service và NetworkPolicy.
- `readonly-sa` list resource được nhưng không tạo Deployment được.
- `deployer-sa` tạo Deployment được trong namespace lab.
- Trước NetworkPolicy, `app-client` và `attacker` đều gọi được `db`.
- Sau NetworkPolicy, chỉ Pod label `role=app` gọi được Pod label `role=db`.

## 4. Khó khăn & cách giải quyết

- NetworkPolicy chỉ hoạt động nếu CNI/network policy controller support. Với k3d/k3s bình thường thì dùng được.
- Cần test trước/sau khi bật policy để mentor thấy rõ policy thật sự có tác dụng.
- RBAC nên test bằng `kubectl auth can-i` để không cần tạo kubeconfig user thật.

## 5. Screenshot

- `screenshots/rbac_roles_object_created.png`: ServiceAccount, Role và RoleBinding đã được tạo.
- `screenshots/rbac_test.png`: kết quả `kubectl auth can-i` cho `readonly-sa` và `deployer-sa`.
- `screenshots/before_network_policy_on_test.png`: trước khi bật NetworkPolicy, `app-client` và `attacker` đều gọi được `db`.
- `screenshots/after_network_policy_on_test.png`: sau khi bật NetworkPolicy, `app-client` gọi được `db`, `attacker` bị block.

## 6. Dọn lab

```bash
helm uninstall rbac-netpol -n rbac-netpol-lab
kubectl delete namespace rbac-netpol-lab
rm -f rendered.yaml
```

## 7. Reference

- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Kubernetes ServiceAccount: https://kubernetes.io/docs/concepts/security/service-accounts/
- Kubernetes NetworkPolicy: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Helm template guide: https://helm.sh/docs/chart_template_guide/
