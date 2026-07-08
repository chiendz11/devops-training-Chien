# Day 1 — Terraform module + remote backend cho Kubernetes app

## Task

- **Intern**: `Bùi Anh Chiến`
- **Phase / Week / Day**: `Phase 2 / Week 4 / Day 1`
- **Branch**: `phase-2/week-4/day-1-terraform-k8s-app`

## 1. Mục tiêu

Lab này dùng Terraform để tạo module `k8s-app`, sau đó reuse module cho 2 môi trường `dev` và `stg`.
Terraform state được lưu remote trên S3 và lock bằng DynamoDB để tránh nhiều người apply cùng lúc.

## 2. Cấu trúc

```text
day-1-terraform-k8s-app/
├── bootstrap-backend/     # tạo S3 bucket + DynamoDB table
├── modules/k8s-app/       # Terraform module deploy app bằng Helm
└── envs/
    ├── dev/               # root config dev
    └── stg/               # root config staging
```

## 3. Cách chạy

Yêu cầu máy đã có `aws`, `terraform`, `kubectl`, `helm` và kubeconfig trỏ tới cluster đang chạy.

### Chuẩn bị local Kubernetes

```bash
k3d cluster create dev --agents 2 -p "8080:80@loadbalancer"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

sudo sh -c 'echo "127.0.0.1 dev.demo.local stg.demo.local" >> /etc/hosts'
```

### Bootstrap remote backend

```bash
cd bootstrap-backend

cp terraform.tfvars.example terraform.tfvars
# sửa bucket_name nếu cần vì S3 bucket name phải unique global

terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

cd ..
```

### Tạo backend config cho dev/stg

```bash
BUCKET_NAME=$(terraform -chdir=bootstrap-backend output -raw bucket_name)
LOCK_TABLE_NAME=$(terraform -chdir=bootstrap-backend output -raw lock_table_name)
AWS_REGION="ap-southeast-1"

cat > envs/dev/backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "week4/day1/dev.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$LOCK_TABLE_NAME"
encrypt        = true
EOF

cat > envs/stg/backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "week4/day1/stg.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$LOCK_TABLE_NAME"
encrypt        = true
EOF
```

### Apply dev

```bash
cd envs/dev

cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

cd ../..
curl http://dev.demo.local:8080/health
```

### Apply stg

```bash
cd envs/stg

cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

cd ../..
curl http://stg.demo.local:8080/health
```

## 4. Verify

```bash
kubectl get deploy,svc,ingress -n demo-dev
kubectl get deploy,svc,ingress -n demo-stg

aws s3 ls "s3://$BUCKET_NAME/week4/day1/"
aws dynamodb describe-table \
  --table-name "$LOCK_TABLE_NAME" \
  --region "$AWS_REGION" \
  --query 'Table.TableStatus'
```

## 5. Dọn dẹp

Destroy app trước, backend sau:

```bash
terraform -chdir=envs/stg destroy
terraform -chdir=envs/dev destroy
terraform -chdir=bootstrap-backend destroy
```

## 6. Self-check

- [ ] Module `k8s-app` được reuse bởi `envs/dev` và `envs/stg`.
- [ ] Dev và staging có state key riêng trên S3.
- [ ] DynamoDB table dùng để lock state.
- [ ] App truy cập được qua `dev.demo.local:8080` và `stg.demo.local:8080`.
- [ ] Không commit `*.tfvars`, `*.tfstate`, `backend.hcl`.
