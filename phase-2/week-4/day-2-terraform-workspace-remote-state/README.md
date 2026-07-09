# Task: Terraform workspace, dependency graph, terraform_remote_state

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 4 / Day 2`
- **Branch**: `phase-2/week-4/day-2-terraform-workspace-remote-state`
- **Submitted at**: `2026-07-09` (timezone +07)
- **Time spent**: `3 giờ`

## 1. Mục tiêu

Lab này thực hành `terraform workspace`, `terraform_remote_state` và `terraform graph`.
Root `shared` publish output vào remote state, root `app` đọc output đó rồi deploy cùng module `k8s-app` cho 2 workspace `dev` và `stg`.

## 2. Cách chạy

Yêu cầu đã chạy xong Day 1 và backend S3 + DynamoDB vẫn còn tồn tại.

```bash
cd phase-2/week-4/day-2-terraform-workspace-remote-state

DAY1="../day-1-terraform-k8s-app"
BUCKET_NAME=$(terraform -chdir="$DAY1/bootstrap-backend" output -raw bucket_name)
LOCK_TABLE_NAME=$(terraform -chdir="$DAY1/bootstrap-backend" output -raw lock_table_name)
AWS_REGION="ap-southeast-1"
```

Thêm local domain:

```bash
sudo sh -c 'echo "127.0.0.1 dev.day2.demo.local stg.day2.demo.local" >> /etc/hosts'
```

Tạo shared state:

```bash
cat > shared/backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "week4/day2/shared.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$LOCK_TABLE_NAME"
encrypt        = true
EOF

cd shared
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
cd ..
```

Tạo app backend và apply 2 workspace:

```bash
cat > app/backend.hcl <<EOF
bucket               = "$BUCKET_NAME"
key                  = "app.tfstate"
workspace_key_prefix = "week4/day2/workspaces"
region               = "$AWS_REGION"
dynamodb_table       = "$LOCK_TABLE_NAME"
encrypt              = true
EOF

cp app/terraform.tfvars.example app/terraform.tfvars
sed -i "s|<state-bucket>|$BUCKET_NAME|g" app/terraform.tfvars
sed -i "s|<lock-table>|$LOCK_TABLE_NAME|g" app/terraform.tfvars

cd app
terraform init -backend-config=backend.hcl

terraform workspace new dev || terraform workspace select dev
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output

terraform workspace new stg || terraform workspace select stg
terraform plan -out=tfplan
terraform apply tfplan
terraform output
cd ..
```

Verify:

```bash
terraform -chdir=app workspace list

kubectl get deploy,svc,ingress -n demo-day2-dev
kubectl get deploy,svc,ingress -n demo-day2-stg

curl -H "Host: dev.demo.local" http://127.0.0.1:8080/
curl -H "Host: dev.day2.demo.local" http://127.0.0.1:8080/
curl http://stg.day2.demo.local:8080/health

aws s3 ls "s3://$BUCKET_NAME/week4/day2/" --recursive
```

Sinh dependency graph trên Arch Linux:

```bash
sudo pacman -S graphviz

terraform -chdir=app workspace select dev
terraform -chdir=app graph > screenshots/app-dev-graph.dot
dot -Tpng screenshots/app-dev-graph.dot -o screenshots/app-dev-graph.png
```

Nếu dùng Ubuntu thì cài bằng:

```bash
sudo apt-get update
sudo apt-get install -y graphviz
```

## 3. Kết quả

- `shared` root tạo remote state `week4/day2/shared.tfstate`.
- `app` root dùng workspace `dev` và `stg`, state tách riêng bằng `workspace_key_prefix`.
- `app` đọc `image` và `domain_suffix` từ shared state bằng `terraform_remote_state`.
- Day 2 tạo thêm route mới cho `dev.day2.demo.local`, không override route Day 1 `dev.demo.local`.
- Screenshot minh chứng nằm trong `./screenshots/`.

## 4. Khó khăn & cách giải quyết

- Ban đầu dễ nhầm rằng Day 2 override route Day 1. Em kiểm tra bằng `Host` header và thấy ingress-nginx thêm rule mới, không ghi đè rule cũ.
- Backend config không thể lấy trực tiếp từ `terraform_remote_state` vì backend được init trước phase plan/apply. Em dùng output từ Day 1 để generate `backend.hcl`.
- Dependency graph nhìn ngược chiều mũi tên so với trực giác ban đầu. Em hiểu lại là graph biểu diễn dependency giữa `terraform_remote_state`, guard và module/Helm release.

## 5. Reference

- Terraform S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform remote state data source: https://developer.hashicorp.com/terraform/language/state/remote-state-data
- Terraform graph command: https://developer.hashicorp.com/terraform/cli/commands/graph
- Helm provider: https://registry.terraform.io/providers/hashicorp/helm/latest/docs

## 6. Self-check

- [x] Dùng workspace `dev` và `stg`.
- [x] Workspace dev/stg dùng chung root config `app`.
- [x] State dev/stg tách riêng trên S3 bằng `workspace_key_prefix`.
- [x] `app` đọc output từ `shared` bằng `terraform_remote_state`.
- [x] Có dependency graph bằng `terraform graph`.
- [x] Không commit `terraform.tfvars`, `backend.hcl`, `tfplan`, `.terraform/`.
