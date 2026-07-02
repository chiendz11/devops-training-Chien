# Bootstrap Terraform remote backend

Folder này dùng để tạo remote backend cho lab Terraform Day 3.

Backend gồm:

- S3 bucket để lưu Terraform state.
- DynamoDB table để lock state khi chạy `terraform apply`.

Lý do tách folder riêng: backend phải tồn tại trước khi folder `2-aws/` có thể dùng backend đó.

## 1. Chạy bootstrap

```bash
cd phase-1/week-2/day-3-terraform/bootstrap-backend

terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Sau khi apply xong, lấy output:

```bash
terraform output
terraform output -raw tfstate_bucket
terraform output -raw tfstate_lock_table
```

## 2. Tạo backend config cho `2-aws`

Copy file example:

```bash
cd ..
cp 2-aws/backend.tf.example 2-aws/backend.tf
```

Sửa dòng `bucket` trong `2-aws/backend.tf` thành output thật:

```hcl
bucket = "tfstate-chienqt-xxxxxxxx"
```

Hoặc tạo nhanh bằng shell:

```bash
TFSTATE_BUCKET="$(terraform -chdir=bootstrap-backend output -raw tfstate_bucket)"
TFLOCK_TABLE="$(terraform -chdir=bootstrap-backend output -raw tfstate_lock_table)"

cat > 2-aws/backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "$TFSTATE_BUCKET"
    key            = "phase1/week2/day3.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "$TFLOCK_TABLE"
    encrypt        = true
  }
}
EOF
```

## 3. Migrate state của `2-aws`

```bash
cd 2-aws
terraform init -migrate-state
```

Khi Terraform hỏi có copy local state lên remote backend không, nhập:

```text
yes
```

Sau đó kiểm tra state:

```bash
terraform state list
```

## 4. Dọn dẹp cuối lab

Destroy app infra trước:

```bash
cd ../2-aws
terraform destroy -auto-approve
```

Sau đó mới destroy backend:

```bash
cd ../bootstrap-backend
terraform destroy -auto-approve
```

Lưu ý: `terraform.tfvars`, `tfplan`, `backend.tf` và state files đều bị ignore, không commit lên Git.
