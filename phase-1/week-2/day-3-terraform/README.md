# Task: Day 8 (W2-D3) — Terraform Basics

- **Intern**: Bùi Anh Chiến
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 3`
- **Branch**: `phase-1/week-2/day-3-terraform`
- **Submitted at**: `2026-06-26 21:55` (timezone +07)
- **Time spent**: `~5 giờ`

## Tóm tắt bài làm

Day 8 tập trung vào Terraform cơ bản và cách dùng Infrastructure as Code để mô tả hạ tầng theo kiểu declarative.

Em đã hoàn thành:

- Viết `notes.md` trả lời các phần lý thuyết: state file, plan/apply/refresh, remote backend, module, `count` vs `for_each`, drift.
- Làm lab local-only trong `1-local/` với provider `random` và `local`, có transcript `1-local-transcript.log`.
- Làm lab AWS trong `2-aws/`: tạo VPC `10.20.0.0/16`, 2 public subnet, IGW, route table, security group, EC2 Amazon Linux 2023, Elastic IP và nginx.
- Verify EC2 bằng `curl http://<public_ip>` và đã chạy `terraform destroy` để dọn resource.
- Thêm tag cho resource: `Project=devops-training`, `Owner=Bui Anh Chien`, `ManagedBy=terraform`.

## Remote backend bonus

Folder `bootstrap-backend/` dùng để tạo remote backend riêng trước khi `2-aws/` migrate state.

Backend gồm:

- S3 bucket `tfstate-<tên>-<random>` để lưu Terraform state.
- DynamoDB table `tfstate-lock` để lock state khi apply.
- S3 versioning, encryption và block public access.

Sau khi bootstrap xong, lấy output bucket/table rồi tạo `2-aws/backend.tf` từ `2-aws/backend.tf.example`, sau đó chạy:

```bash
terraform init -migrate-state
```

Các file nhạy cảm như `*.tfstate`, `*.tfvars`, `.terraform/`, `tfplan`, `backend.tf` đều đã được ignore.
