# Task: Kubernetes Storage với StatefulSet, PVC và local-path

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 3 / Day 5`
- **Branch**: `phase-2/week-3/day-5-kubernetes-storage-postgres`
- **Submitted at**: `2026-07-12` (timezone +07)
- **Time spent**: `~3 giờ`

## 1. Mục tiêu

Triển khai PostgreSQL trên Kubernetes bằng Helm chart tự viết, chạy bằng StatefulSet và lưu data qua PVC. Với k3d/k3s local, lab dùng `local-path` StorageClass để chứng minh data vẫn còn sau khi xoá Pod.

## 2. Cách chạy

Kiểm tra cluster có `local-path` StorageClass:

```bash
kubectl get storageclass
kubectl -n kube-system get pod | grep local-path
```

Cài PostgreSQL bằng Helm chart local:

```bash
cd phase-2/week-3/lab-6

cp postgres-values.secret.example.yaml postgres-values.secret.yaml

helm lint ./charts/postgres-localpath \
  -f postgres-values.secret.yaml

helm upgrade --install postgres ./charts/postgres-localpath \
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
INSERT INTO notes (message) VALUES ('hello from local-path pvc');
SELECT * FROM notes;
"
```

Xoá Pod và verify data vẫn còn:

```bash
kubectl -n postgres-lab delete pod "$POD"
kubectl -n postgres-lab rollout status statefulset/postgres-postgres-localpath

NEW_POD=$(kubectl -n postgres-lab get pod \
  -l app.kubernetes.io/instance=postgres \
  -o jsonpath='{.items[0].metadata.name}')

kubectl -n postgres-lab exec -it "$NEW_POD" -- psql -U demo -d demo -c "SELECT * FROM notes;"
```

## 3. Kết quả

- Chart `postgres-localpath` tạo Secret, Service, PVC và StatefulSet.
- PVC dùng StorageClass `local-path` có sẵn của k3d/k3s.
- PostgreSQL mount PVC vào `/var/lib/postgresql/data`.
- Data vẫn tồn tại sau khi Pod PostgreSQL bị xoá và được StatefulSet tạo lại.
- Password Postgres nằm trong `postgres-values.secret.yaml` local và không commit lên Git.

## 4. Khó khăn & cách giải quyết

- Ban đầu thử Longhorn nhưng k3d node là Docker container tối giản, thiếu `iscsiadm/open-iscsi` nên Longhorn manager bị `CrashLoopBackOff`.
- Với k3d, `local-path` phù hợp hơn cho lab PVC cơ bản vì provisioner đã có sẵn trong `kube-system`.
- PostgreSQL không nên chạy 3 replica chung một PVC, nên lab dùng `replicaCount=1`.
- PostgreSQL volume root có thể không rỗng nên chart set `PGDATA=/var/lib/postgresql/data/pgdata`.
- Không commit secret thật vào `values.yaml` → dùng file local `postgres-values.secret.yaml` bị `.gitignore`.

## 5. Screenshot

- `screenshots/postgres-lab_object_created.png`: các object của lab được tạo trong namespace `postgres-lab`.
- `screenshots/data_insertion.png`: insert data vào PostgreSQL và query lại.
- `screenshots/delete_pods_to_check_PV.png`: xoá Pod, StatefulSet tạo lại Pod mới và data vẫn còn trong PVC.

## 6. Dọn lab

```bash
helm uninstall postgres -n postgres-lab
kubectl delete ns postgres-lab
```

Nếu muốn xoá luôn PV/PVC và data local thì kiểm tra lại:

```bash
kubectl get pv,pvc -A
```

## 7. Reference

- Kubernetes Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Kubernetes StatefulSet: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- Local Path Provisioner: https://github.com/rancher/local-path-provisioner
