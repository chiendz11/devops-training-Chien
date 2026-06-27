# Part A — IAM

## 1. Phân biệt user, group, role, policy

IAM là dịch vụ dùng để quản lý quyền truy cập vào AWS. Nói đơn giản, IAM trả lời 2 câu hỏi:

```text
Bạn là ai?
Bạn được phép làm gì?
```

Trong IAM có 4 khái niệm rất hay gặp: `user`, `group`, `role`, `policy`.

### a. IAM user

IAM user là một identity đại diện cho một người dùng hoặc một ứng dụng cụ thể trong AWS account.

Ví dụ:

```text
user/Chienqt
user/terraform-lab-user
user/github-actions-deploy
```

IAM user có thể có:

- Password để đăng nhập AWS Console.
- Access key để dùng AWS CLI, SDK hoặc Terraform.
- Policy gắn trực tiếp để cấp quyền.

Ví dụ em dùng AWS CLI:

```bash
aws sts get-caller-identity
```

nếu output là:

```text
arn:aws:iam::<account-id>:user/Chienqt
```

thì nghĩa là request đang chạy bằng IAM user `Chienqt`.

IAM user phù hợp cho người dùng cụ thể, nhưng nếu dùng access key lâu dài thì phải quản lý rất cẩn thận vì key bị lộ là người khác có thể gọi AWS API theo quyền của user đó.

### b. IAM group

IAM group là nhóm chứa nhiều IAM user.

Group giúp quản lý quyền cho nhiều user cùng lúc.

Ví dụ:

```text
Developers group
    ├── user/alice
    ├── user/bob
    └── user/chienqt
```

Nếu attach policy `AmazonEC2ReadOnlyAccess` vào group `Developers`, thì tất cả user trong group đều có quyền đọc EC2.

Điểm cần nhớ:

- Group không dùng để login.
- Group không đại diện cho một app hay server.
- Group chỉ là cách gom user lại để cấp quyền dễ hơn.
- Một user có thể nằm trong nhiều group.

Ví dụ thực tế:

```text
Interns group      → chỉ read-only
Developers group   → deploy staging
Admins group       → quyền cao hơn
```

### c. IAM role

IAM role cũng là một identity có permission giống user, nhưng khác user ở chỗ role không có password/access key dài hạn.

Role được thiết kế để một principal khác assume/tạm mượn.

Principal có thể là:

- AWS service như EC2, Lambda, ECS.
- IAM user.
- AWS account khác.
- GitHub Actions qua OIDC.

Ví dụ:

```text
EC2 instance
    ↓ assume role
IAM role: demo-ec2-s3-readonly-role
    ↓ nhận temporary credentials
S3 GetObject
```

Role phù hợp cho workload, CI/CD, service-to-service access.

Ví dụ thay vì nhét access key vào EC2, mình gắn IAM role vào EC2. App trong EC2 sẽ lấy temporary credentials qua Instance Metadata Service.

### d. IAM policy

IAM policy là document JSON định nghĩa quyền.

Policy trả lời:

```text
Allow hay Deny?
Action nào?
Resource nào?
Điều kiện gì?
```

Ví dụ:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

Policy có thể attach vào:

- User.
- Group.
- Role.
- Resource, ví dụ S3 bucket policy.

Em hiểu ngắn gọn:

| Khái niệm | Hiểu đơn giản | Ví dụ |
| :--- | :--- | :--- |
| User | Một người/app cụ thể | `user/Chienqt` |
| Group | Nhóm nhiều user | `Developers` |
| Role | Quyền tạm thời để service/user assume | `EC2S3ReadOnlyRole` |
| Policy | JSON mô tả được phép/không được phép làm gì | Allow `s3:GetObject` |

## 2. Trust policy vs identity policy vs resource policy

### a. Identity policy

Identity policy là policy gắn vào identity.

Identity ở đây gồm:

- IAM user.
- IAM group.
- IAM role.

Ví dụ gắn policy vào user `Chienqt`:

```text
user/Chienqt
    ↓ identity policy
Allow ec2:DescribeInstances
```

Policy này nói user/role/group đó được làm gì với resource nào.

Ví dụ:

```json
{
  "Effect": "Allow",
  "Action": "ec2:DescribeInstances",
  "Resource": "*"
}
```

Nó trả lời câu hỏi:

```text
Identity này được phép làm gì?
```

### b. Resource policy

Resource policy là policy gắn trực tiếp lên resource.

Ví dụ hay gặp nhất:

- S3 bucket policy.
- SQS queue policy.
- SNS topic policy.
- KMS key policy.
- Lambda resource-based policy.

Ví dụ S3 bucket policy cho account khác đọc object:

```text
S3 bucket
    ↓ resource policy
Allow account B s3:GetObject
```

Nó trả lời câu hỏi:

```text
Resource này cho ai truy cập?
```

Điểm khác với identity policy:

- Identity policy gắn vào người/role.
- Resource policy gắn vào chính resource.

Ví dụ dễ hiểu:

```text
Identity policy:
  "Chienqt được phép đọc S3"

Resource policy:
  "Bucket này cho phép Chienqt/account X đọc"
```

### c. Trust policy

Trust policy là policy đặc biệt của IAM role.

Nó không cấp quyền để role làm gì, mà quyết định ai được assume role đó.

Ví dụ role cho EC2 assume:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Policy này nghĩa là:

```text
EC2 service được phép assume role này.
```

Sau khi EC2 assume được role, role còn cần identity policy để biết nó được làm gì.

Ví dụ:

```text
Trust policy:
  Ai được assume role? → EC2

Identity policy của role:
  Role được làm gì? → s3:GetObject
```

Nếu thiếu trust policy đúng, EC2 không assume được role.

Nếu có trust policy nhưng role không có permission policy, EC2 assume được role nhưng cũng không làm được gì nhiều.

### d. So sánh nhanh

| Loại policy | Gắn ở đâu? | Trả lời câu hỏi |
| :--- | :--- | :--- |
| Identity policy | User, group, role | Identity này được làm gì? |
| Resource policy | Resource như S3 bucket, SQS, KMS | Resource này cho ai truy cập? |
| Trust policy | IAM role | Ai được assume role này? |

## 3. Tại sao IAM role tốt hơn IAM user key cho EC2/CI/CD?

IAM role thường tốt hơn IAM user access key vì role dùng temporary credentials, còn IAM user key thường là long-term credentials.

### a. IAM user key là long-term credential

Access key của IAM user gồm:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Nếu key này bị lộ trong:

- GitHub repo.
- Log CI/CD.
- File `.env`.
- AMI.
- Docker image.
- Laptop cá nhân.

thì attacker có thể dùng key đó để gọi AWS API cho tới khi mình rotate/delete key.

Nếu key có quyền rộng như `AdministratorAccess` thì rủi ro cực lớn.

### b. IAM role dùng temporary credentials

IAM role không có access key cố định.

Khi EC2 hoặc CI/CD assume role, AWS STS cấp temporary credentials gồm:

```text
AccessKeyId
SecretAccessKey
SessionToken
Expiration
```

Credential này có thời hạn. Hết hạn thì không dùng lại được.

Với EC2, app/CLI/SDK có thể tự lấy temporary credentials từ Instance Metadata Service. Mình không cần copy key vào server.

### c. Với EC2

Cách không nên làm:

```text
SSH vào EC2
    ↓
aws configure
    ↓
lưu access key trong ~/.aws/credentials
```

Cách nên làm:

```text
Tạo IAM role
    ↓
Attach role vào EC2 instance
    ↓
App trên EC2 tự nhận temporary credentials
```

Lợi ích:

- Không lưu key dài hạn trên máy chủ.
- Role có thể rotate temporary credentials tự động.
- Có thể đổi quyền bằng cách sửa policy của role.
- Dễ audit hơn.
- Giảm rủi ro lộ key.

### d. Với CI/CD

Cách không nên làm:

```text
Tạo IAM user deploy
    ↓
Tạo access key
    ↓
Lưu vào GitHub Secrets
```

Cách tốt hơn:

```text
GitHub Actions
    ↓ OIDC
AWS STS AssumeRoleWithWebIdentity
    ↓
Nhận temporary credentials
    ↓
Deploy
```

Lợi ích:

- Không cần lưu AWS secret key trong GitHub.
- Có thể giới hạn role chỉ cho repo/branch/environment cụ thể.
- Credential tự hết hạn.
- Nếu GitHub repo bị đọc secret thì cũng không có long-term AWS key để lấy.

Tóm lại:

```text
IAM user key = chìa khóa dài hạn, phải tự giữ và tự rotate.
IAM role = quyền tạm thời, cấp khi cần, hết hạn tự vô dụng.
```

## 4. Giải thích policy JSON

Policy cần đọc:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject"],
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": { "IpAddress": { "aws:SourceIp": "203.0.113.0/24" } }
  }]
}
```

### a. `Version`

```json
"Version": "2012-10-17"
```

Đây là version của IAM policy language, không phải ngày tạo policy.

`2012-10-17` là version phổ biến hiện tại nên gần như policy IAM nào cũng dùng dòng này.

### b. `Statement`

```json
"Statement": [...]
```

`Statement` là danh sách các rule trong policy.

Một policy có thể có một hoặc nhiều statement.

Ví dụ:

```text
Statement 1: Allow đọc object
Statement 2: Deny xóa object
```

Trong bài này có 1 statement.

### c. `Effect`

```json
"Effect": "Allow"
```

`Effect` nói statement này là cho phép hay từ chối.

Giá trị có thể là:

```text
Allow
Deny
```

Trong bài này là `Allow`, nghĩa là cho phép nếu request match đủ `Action`, `Resource`, `Condition`.

### d. `Action`

```json
"Action": ["s3:GetObject"]
```

`Action` là hành động AWS API được áp dụng.

`s3:GetObject` nghĩa là đọc/download object trong S3.

Nó cho phép các hành động kiểu:

```bash
aws s3 cp s3://my-bucket/file.txt .
```

Nhưng nó không cho phép:

```text
s3:PutObject     # upload object
s3:DeleteObject  # xóa object
s3:ListBucket    # list bucket
```

Lưu ý nhỏ: để list object trong bucket thường cần thêm `s3:ListBucket` trên ARN bucket không có `/*`.

### e. `Resource`

```json
"Resource": "arn:aws:s3:::my-bucket/*"
```

`Resource` là tài nguyên mà action áp dụng lên.

ARN này nghĩa là:

```text
Tất cả object bên trong bucket my-bucket
```

Dấu `/*` rất quan trọng:

```text
arn:aws:s3:::my-bucket      → bucket
arn:aws:s3:::my-bucket/*    → object trong bucket
```

Vì `s3:GetObject` là action trên object, nên resource cần là object ARN:

```text
arn:aws:s3:::my-bucket/*
```

### f. `Condition`

```json
"Condition": {
  "IpAddress": {
    "aws:SourceIp": "203.0.113.0/24"
  }
}
```

`Condition` là điều kiện để statement có hiệu lực.

Ở đây:

```text
Chỉ allow nếu request đến từ IP range 203.0.113.0/24
```

`203.0.113.0/24` là một CIDR block, gồm các IP từ:

```text
203.0.113.0 → 203.0.113.255
```

Nếu request đến từ IP ngoài range này thì statement `Allow` không match.

Khi không có Allow nào khác, request sẽ bị implicit deny.

### g. Tóm tắt policy

Policy này nghĩa là:

```text
Cho phép đọc object trong bucket my-bucket,
nhưng chỉ khi request đến từ IP range 203.0.113.0/24.
```

Nó không cho upload, không cho delete, không cho list bucket, và không cho đọc nếu IP không khớp condition.

## 5. User nằm trong group có Allow, policy trực tiếp user có Deny — kết quả?

Kết quả là:

```text
Deny
```

Trong IAM, explicit deny luôn thắng explicit allow.

Ví dụ:

Group policy:

```json
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

User direct policy:

```json
{
  "Effect": "Deny",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

User nằm trong group nên nhận được `Allow`, nhưng user cũng có policy trực tiếp `Deny`.

AWS evaluation sẽ nhìn thấy có explicit deny, nên request bị deny.

Flow dễ nhớ:

```text
Mặc định: Deny
Nếu có Allow phù hợp: Allow
Nếu có Deny phù hợp ở bất kỳ policy nào: Deny
```

Nói cách khác:

```text
Explicit Deny > Explicit Allow > Implicit Deny
```

Vì vậy nếu user có cả Allow và Deny cho cùng action/resource, kết quả cuối cùng vẫn là Deny.

# Part E — VPC topology

## 1. Sơ đồ tổng quan

Trong mô hình này, VPC được chia thành 4 subnet nằm trên 2 Availability Zone.
ALB nằm ở public subnet để nhận request từ Internet, còn 2 EC2 backend nằm ở
private subnet và chỉ nhận request từ ALB.

```text
                               Internet
                                   │
                                   ▼
                          Internet Gateway
                                   │
                  ┌────────────────┴────────────────┐
                  │       VPC: 10.0.0.0/16          │
                  │                                 │
                  │    Application Load Balancer    │
                  │       (public, multi-AZ)         │
                  │          │              │        │
                  │          ▼              ▼        │
                  │  Availability Zone A  Availability Zone B
                  │  ┌──────────────────┐ ┌──────────────────┐
                  │  │ Public subnet A  │ │ Public subnet B  │
                  │  │ 10.0.1.0/24      │ │ 10.0.2.0/24      │
                  │  │                  │ │                  │
                  │  │ ALB node         │ │ ALB node         │
                  │  │ NAT Gateway + EIP│ │                  │
                  │  └────────┬─────────┘ └────────┬─────────┘
                  │           │                    │
                  │           ▼                    ▼
                  │  ┌──────────────────┐ ┌──────────────────┐
                  │  │ Private subnet A │ │ Private subnet B │
                  │  │ 10.0.11.0/24     │ │ 10.0.12.0/24     │
                  │  │                  │ │                  │
                  │  │ EC2 backend 1    │ │ EC2 backend 2    │
                  │  └──────────────────┘ └──────────────────┘
                  │                                 │
                  └─────────────────────────────────┘
```

Các thành phần chính:

- Một Internet Gateway được attach vào VPC.
- ALB được gắn với cả 2 public subnet để hoạt động trên 2 AZ.
- Mỗi private subnet chứa một EC2 backend.
- NAT Gateway nằm trong public subnet, có Elastic IP và có đường ra Internet
  thông qua Internet Gateway.
- ALB chuyển request đến hai EC2 thông qua target group.

## 2. Luồng request từ người dùng vào backend

Luồng inbound:

```text
Client trên Internet
        ↓
Internet Gateway
        ↓
Application Load Balancer ở public subnet
        ↓
Target group
        ↓
EC2 backend ở private subnet
```

ALB có thể nhận traffic từ Internet vì nó nằm trên public subnet có route đến
Internet Gateway. Sau đó ALB gọi đến private IP của EC2 thông qua route `local`
có sẵn trong VPC.

Security Group nên được cấu hình theo hướng:

```text
ALB Security Group:
  Inbound 80/443 từ Internet

Backend Security Group:
  Inbound cổng ứng dụng chỉ từ ALB Security Group
```

Ví dụ ứng dụng chạy cổng `3000`, backend không cần mở cổng này cho
`0.0.0.0/0`. Nó chỉ cần cho phép traffic từ Security Group của ALB.

## 3. Route table

Public subnet và private subnet có route table khác nhau:

| Route table | Destination | Target | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| Public route table | CIDR của VPC | `local` | Giao tiếp giữa các subnet trong VPC |
| Public route table | `0.0.0.0/0` | Internet Gateway | Cho ALB và NAT Gateway kết nối Internet |
| Private route table | CIDR của VPC | `local` | Backend giao tiếp nội bộ với ALB và resource khác |
| Private route table | `0.0.0.0/0` | NAT Gateway | Cho backend chủ động đi ra Internet |

Một subnet được coi là public khi route table của nó có route trực tiếp đến
Internet Gateway. Private subnet không có route trực tiếp này.

## 4. Tại sao backend phải ở private subnet?

Backend thường xử lý business logic, gọi database và có thể tiếp xúc với dữ
liệu nhạy cảm. Vì vậy backend không nên được truy cập trực tiếp từ Internet.

Đặt EC2 backend trong private subnet giúp:

- EC2 không cần public IP.
- Giảm bề mặt tấn công vì Internet không kết nối trực tiếp được đến EC2.
- Chỉ cho phép traffic đi qua ALB và Security Group đã kiểm soát.
- Có thể xử lý TLS, access log hoặc WAF tập trung ở lớp ALB.
- Khi một backend bị thay thế hoặc scale, client vẫn chỉ truy cập một endpoint
  ổn định là ALB.

Nếu cần quản trị EC2, có thể dùng AWS Systems Manager Session Manager hoặc
bastion host thay vì mở SSH trực tiếp cho toàn Internet.

Private subnet không có nghĩa là EC2 bị cô lập hoàn toàn. EC2 vẫn giao tiếp
được với các resource trong VPC qua route `local`, và có thể đi ra Internet
thông qua NAT Gateway.

## 5. Backend đi ra Internet qua đâu?

Luồng outbound của backend:

```text
EC2 private
    ↓
Private route table: 0.0.0.0/0 → NAT Gateway
    ↓
NAT Gateway trong public subnet
    ↓
Internet Gateway
    ↓
Internet
```

Ví dụ backend cần tải package hoặc gọi một API bên ngoài:

```text
EC2 → NAT Gateway → Internet Gateway → npm registry/API bên ngoài
```

NAT Gateway thay private IP của EC2 bằng Elastic IP của NAT Gateway. Response
được gửi về NAT Gateway rồi chuyển lại cho EC2 tương ứng.

NAT Gateway chỉ hỗ trợ kết nối do resource phía private chủ động tạo ra. Người
dùng trên Internet không thể dùng NAT Gateway để mở kết nối mới trực tiếp đến
EC2 backend.

Trong sơ đồ lab chỉ có một NAT Gateway để giảm chi phí. Với production, nên đặt
một NAT Gateway ở mỗi AZ và private subnet của AZ nào đi qua NAT Gateway cùng
AZ đó. Cách này tránh phụ thuộc vào một AZ và tránh traffic đi chéo AZ.

## Reference

- IAM identities: https://docs.aws.amazon.com/IAM/latest/UserGuide/id.html
- IAM policies and permissions: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
- IAM roles: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html
- Temporary credentials: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html
- IAM roles for EC2: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html
- Policy evaluation logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- Explicit vs implicit deny: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic_AccessPolicyLanguage_Interplay.html
- IAM policy Condition: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html
- VPC route tables: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html
- NAT Gateway: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
- Application Load Balancer: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
