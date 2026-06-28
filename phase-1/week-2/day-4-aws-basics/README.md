# Task: Day 9 — AWS Essentials

- **Intern**: Bùi Anh Chiến
- **Phase / Week / Day**: `Phase 1 / Week 2 / Day 4`
- **Branch**: `phase-1/week-2/day-4-aws-basics`
- **Submitted at**: `2026-06-28 00:03` (timezone +07)
- **Time spent**: `5 giờ`

## 1. Mục tiêu

Tìm hiểu IAM, S3 và VPC trên AWS. Thực hành phân quyền S3 read-only, host static
website, tạo presigned URL cho file private và mô tả kiến trúc VPC nhiều AZ.

## 2. Cách chạy

Yêu cầu máy mentor có AWS CLI, Python 3, `boto3` và một AWS profile dùng cho lab.
Không sử dụng tài khoản root hoặc credentials production.

```bash
git clone https://github.com/chiendz11/devops-training-Chien.git
cd devops-training-Chien/phase-1/week-2/day-4-aws-basics

aws configure --profile default
aws --profile default sts get-caller-identity
python3 -m pip install --user boto3
```

Kiểm tra IAM lab và kết quả user `test-ro` chỉ có quyền đọc S3:

```bash
cat iam-lab/transcript.log
```

Tạo S3 static website bằng bucket riêng của mentor:

```bash
ACCOUNT_ID=$(aws --profile default sts get-caller-identity \
  --query Account --output text)
STATIC_BUCKET="mentor-static-${ACCOUNT_ID}-${RANDOM}"
aws --profile default s3 mb "s3://${STATIC_BUCKET}" --region ap-southeast-1
aws --profile default s3 cp s3-static/index.html "s3://${STATIC_BUCKET}/index.html"
aws --profile default s3 cp s3-static/error.html "s3://${STATIC_BUCKET}/error.html"

aws --profile default s3api put-bucket-website \
  --bucket "$STATIC_BUCKET" \
  --website-configuration \
  '{"IndexDocument":{"Suffix":"index.html"},"ErrorDocument":{"Key":"error.html"}}'
```

Mentor cần tắt Block Public Access cho đúng bucket lab và thay tên bucket trong
`s3-static/bucket-policy.json` trước khi chạy:

```bash
aws --profile default s3api put-bucket-policy \
  --bucket "$STATIC_BUCKET" \
  --policy file://s3-static/bucket-policy.json
```

Tạo presigned URL TTL 5 phút cho một object đã upload vào private bucket:

```bash
python3 s3-presign/presign.py \
  --bucket <private-bucket> \
  --key private.pdf \
  --expires 300 \
  --region ap-southeast-1 \
  --profile default
```

Sau khi kiểm tra, xóa bucket và disable/delete IAM access key đã tạo cho lab để
tránh giữ tài nguyên hoặc credentials không cần thiết.

## 3. Kết quả

- Trả lời IAM và VPC topology trong [`notes.md`](./notes.md).
- Transcript IAM nằm tại [`iam-lab/transcript.log`](./iam-lab/transcript.log).
- User `test-ro` list/read S3 thành công và upload bị `AccessDenied`.
- Static website truy cập được trực tiếp qua S3 và qua CloudFront OAC.
- Presigned URL CLI/Python tải được file private và bị từ chối sau 5 phút.
- Ảnh minh chứng nằm trong [`screenshots/`](./screenshots/).
- Không để link demo chạy thường trực vì tài nguyên AWS đã được dọn sau lab.

## 4. Khó khăn & cách giải quyết

- AWS CLI mặc định vẫn dùng profile `default` → thêm `--profile test-ro` khi test
  để bảo đảm request thực sự chạy bằng user read-only.
- Bucket-level Block Public Access đã tắt nhưng account-level vẫn có thể chặn
  public policy → kiểm tra cả hai cấp và bật lại toàn bộ sau khi hoàn thành lab.
- CloudFront OAC không dùng được với S3 website endpoint → chọn S3 REST origin,
  giữ bucket private và đặt `index.html` làm default root object.
- Presigned URL là bearer URL tạm thời → không commit URL, đặt TTL 300 giây và
  xác nhận request trả lỗi sau khi hết hạn.

## 5. Reference

- [AWS IAM identities](https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html)
- [IAM policy evaluation logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- [Hosting a static website on S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/HostingWebsiteOnS3Setup.html)
- [AWS CLI s3 presign](https://docs.aws.amazon.com/cli/latest/reference/s3/presign.html)
- [Boto3 presigned URLs](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html)
- [AWS VPC NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)

## 6. Self-check

- [x] Code chạy được trên máy sạch sau khi cấu hình AWS credentials và `boto3`.
- [x] README có hướng dẫn run lại.
- [x] Không hard-code secret.
- [x] Commit message theo Conventional Commits.
- [x] Đã review lại code 1 lượt.
