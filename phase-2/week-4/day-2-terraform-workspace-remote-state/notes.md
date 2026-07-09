# Notes — Terraform workspace, graph, remote state

## 1. Terraform workspace là gì?

Terraform workspace là cách để cùng một root config có nhiều state khác nhau.
Trong lab này root `app` có 2 workspace:

```text
dev
stg
```

Cùng file Terraform, nhưng khi chọn workspace khác nhau thì state khác nhau.

```bash
terraform workspace select dev
terraform apply

terraform workspace select stg
terraform apply
```

Với S3 backend, mình dùng `workspace_key_prefix` để state được tách riêng:

```text
week4/day2/workspaces/dev/app.tfstate
week4/day2/workspaces/stg/app.tfstate
```

## 2. terraform_remote_state dùng để làm gì?

`terraform_remote_state` cho phép root này đọc output từ state của root khác.

Trong lab:

```text
shared root
  └── output image, domain_suffix

app root
  └── đọc output đó bằng data.terraform_remote_state.shared
```

Nhờ vậy `app` không cần hard-code image/domain suffix trong code.

## 3. Dependency graph là gì?

Terraform tạo graph để biết resource/data/module nào phụ thuộc cái nào.

Trong lab này flow là:

```text
data.terraform_remote_state.shared
        ↓
locals image/domain/replicas
        ↓
module.k8s_app
        ↓
helm_release.app
```

Lệnh xem graph:

```bash
terraform graph
```

Nếu muốn xuất ảnh:

```bash
terraform graph > graph.dot
dot -Tpng graph.dot -o graph.png
```

## 4. Lưu ý thực tế

Workspace tiện để học concept state riêng, nhưng production lớn thường thích folder per env hơn:

```text
envs/dev
envs/stg
envs/prod
```

Lý do là folder per env dễ review, dễ phân quyền và ít nhầm workspace hơn.

