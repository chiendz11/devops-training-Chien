# Task: Kubernetes Storage với Longhorn, Helm, PostgreSQL và PVC

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 5`
- **Branch**: `phase-2/week-3/day-5-kubernetes-storage-postgres`
- **Submitted at**: `2026-07-12` (timezone +07)
- **Time spent**: `~3 giờ`

## 1. Mục tiêu

Triển khai PostgreSQL trên Kubernetes bằng Helm chart tự viết, dùng PVC để lưu data và dùng Longhorn làm CSI storage backend. Kiểm tra data vẫn còn sau khi xoá Pod.

## 2. Cách chạy

Longhorn cần Kubernetes cluster đã chạy và node đáp ứng yêu cầu storage. Với lab local, nên dùng k3s/k3d có đủ quyền privileged.

```bash
cd phase-2/week-3/lab-6

helm repo add longhorn https://charts.longhorn.io
helm repo update

kubectl create namespace longhorn-system

helm upgrade --install longhorn longhorn/longhorn \
  -n longhorn-system \
  -f longhorn-values.yaml

kubectl -n longhorn-system get pod -w
kubectl get storageclass
```

Cài PostgreSQL bằng Helm chart local:

```bash
helm lint ./charts/postgres-longhorn

cp postgres-values.secret.example.yaml postgres-values.secret.yaml

helm upgrade --install postgres ./charts/postgres-longhorn \
  -n postgres-lab \
  --create-namespace \
  -f postgres-values.secret.yaml \
  --wait

kubectl get storageclass,pv
kubectl -n postgres-lab get pvc,statefulset,pod,svc
```

Ghi data:

```bash
POD=$(kubectl -n postgres-lab get pod \
  -l app.kubernetes.io/instance=postgres \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n postgres-lab exec -it "$POD" -- psql -U demo -d demo -c "
CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  message TEXT NOT NULL
);
INSERT INTO notes (message) VALUES ('hello from longhorn pvc');
SELECT * FROM notes;
"
```

Xoá Pod và verify data vẫn còn:

```bash
kubectl -n postgres-lab delete pod "$POD"
kubectl -n postgres-lab rollout status statefulset/postgres-postgres-longhorn

NEW_POD=$(kubectl -n postgres-lab get pod \
  -l app.kubernetes.io/instance=postgres \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n postgres-lab exec -it "$NEW_POD" -- psql -U demo -d demo -c "SELECT * FROM notes;"
```

Mở Longhorn UI nếu cần:

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8088:80
```

Truy cập:

```text
http://localhost:8088
```

## 3. Kết quả

- Longhorn được cài bằng Helm.
- Chart `postgres-longhorn` tạo `StorageClass` dùng `driver.longhorn.io`.
- PVC `postgres-postgres-longhorn-data` bind thành PV do Longhorn provision.
- PostgreSQL mount PVC vào `/var/lib/postgresql/data`.
- Data vẫn tồn tại sau khi Pod PostgreSQL bị xoá và được tạo lại.
- Password Postgres nằm trong `postgres-values.secret.yaml` local và không commit lên Git.

## 4. Khó khăn & cách giải quyết

- Nếu PVC pending, kiểm tra Longhorn Pod và StorageClass trước vì PVC cần CSI provisioner.
- Longhorn local lab có thể lỗi nếu node thiếu privileged/mount propagation/open-iscsi.
- PostgreSQL volume root có thể không rỗng nên chart set `PGDATA=/var/lib/postgresql/data/pgdata`.
- Dùng `numberOfReplicas=1` để phù hợp lab local ít node.
- Không commit secret thật vào `values.yaml` → dùng file local `postgres-values.secret.yaml` bị `.gitignore`.

## 5. Ảnh cần capture

- `01-longhorn-pods-running.png`: `kubectl -n longhorn-system get pod`
- `02-storageclass-longhorn.png`: `kubectl get storageclass`
- `03-postgres-pvc-bound.png`: `kubectl -n postgres-lab get pvc,pv`
- `04-data-inserted.png`: query `SELECT * FROM notes;`
- `05-delete-pod.png`: xoá Pod và Pod mới được tạo.
- `06-data-persist-after-recreate.png`: query lại data sau khi Pod mới lên.
- `07-longhorn-ui-volume.png`: volume trong Longhorn UI.

## 6. Dọn lab

```bash
helm uninstall postgres -n postgres-lab
kubectl delete ns postgres-lab

helm uninstall longhorn -n longhorn-system
```

Longhorn có cơ chế bảo vệ dữ liệu, nếu uninstall bị kẹt thì cần kiểm tra Longhorn docs phần uninstall.

## 7. Reference

- Longhorn install docs: https://longhorn.io/docs/latest/deploy/install/
- Helm chart template guide: https://helm.sh/docs/chart_template_guide/
- Kubernetes Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
