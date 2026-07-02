# Part A — Terraform theory

## 1. State file là gì? Vì sao không được commit lên Git?

### a. State file là gì?

State file là file Terraform dùng để ghi nhớ trạng thái hạ tầng mà nó đang quản lý.

Mặc định khi chạy local, Terraform tạo file:

```text
terraform.tfstate
```

File này thường là JSON và chứa các thông tin như:

- Resource nào đang được Terraform quản lý.
- Resource trong code map với resource thật nào trên cloud.
- ID thật của resource, ví dụ VPC ID, subnet ID, instance ID.
- Thuộc tính hiện tại của resource.
- Output values.
- Metadata để Terraform hiểu dependency giữa các resource.

Ví dụ trong code có:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-xxx"
  instance_type = "t3.micro"
}
```

Terraform cần state để biết:

```text
aws_instance.web trong code
        ↓
EC2 thật trên AWS có instance_id = i-0123456789
```

Nếu không có state, Terraform không biết resource trong code đang tương ứng với resource thật nào. Lúc đó nó có thể nghĩ là resource chưa tồn tại và tạo mới sai.

### b. Vì sao không được commit state lên Git?

Không nên commit `terraform.tfstate` lên Git vì các lý do sau:

#### Lý do 1: State có thể chứa thông tin nhạy cảm

State file có thể chứa:

- Public IP / private IP.
- ARN.
- Resource ID.
- Database endpoint.
- Password hoặc secret nếu resource/provider trả về.
- User-data.
- Output value.

Kể cả khi trong Terraform có đánh dấu `sensitive = true`, giá trị đó vẫn có thể nằm trong state. `sensitive` chủ yếu giúp che khi hiển thị ra terminal, chứ không có nghĩa là state không chứa secret.

Nếu commit state lên GitHub, người có quyền đọc repo có thể đọc được thông tin hạ tầng.

#### Lý do 2: Dễ bị conflict khi làm team

State file thay đổi sau mỗi lần `terraform apply`.

Nếu nhiều người cùng làm:

```text
Developer A apply
Developer B apply
```

và cả hai cùng commit `terraform.tfstate`, file state rất dễ conflict. Conflict trong state cực kỳ nguy hiểm vì sửa tay sai có thể làm Terraform hiểu sai hạ tầng thật.

#### Lý do 3: Không có locking

Git không có cơ chế lock state khi đang `terraform apply`.

Nếu hai người cùng apply một lúc với local state:

```text
User A terraform apply
User B terraform apply
```

có thể làm state bị lệch hoặc bị ghi đè. Đây là lý do production thường dùng remote backend có state locking.

#### Lý do 4: State là dữ liệu runtime, không phải source code

Git nên lưu:

- `.tf` source code.
- Module.
- README.
- `.terraform.lock.hcl`.
- File example như `terraform.tfvars.example`.

Git không nên lưu:

- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `*.tfvars` thật nếu có IP, secret, account info.

Ví dụ `.gitignore` nên có:

```gitignore
**/.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!*.tfvars.example
```

Riêng `.terraform.lock.hcl` thì thường nên commit, vì file này lock version provider để các máy dùng cùng provider version.

## 2. So sánh terraform plan vs terraform apply vs terraform refresh

### a. `terraform plan`

`terraform plan` dùng để xem trước Terraform định làm gì.

Ví dụ:

```bash
terraform plan
```

Nó sẽ so sánh:

```text
Terraform code hiện tại
        +
Terraform state
        +
Resource thật trên cloud
        ↓
Danh sách thay đổi dự kiến
```

Kết quả có thể là:

```text
+ create
~ update in-place
- destroy
-/+ replace
```

Ví dụ sửa `instance_type` từ `t3.micro` sang `t3.small`, `terraform plan` sẽ cho biết resource nào bị update hoặc replace trước khi mình apply thật.

Điểm quan trọng:

- `plan` chỉ preview.
- Không tạo/sửa/xóa resource thật.
- Thường dùng trong PR để review trước khi merge.
- Có thể lưu plan ra file:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Cách này giúp đảm bảo cái được apply chính là cái đã review.

### b. `terraform apply`

`terraform apply` dùng để thực thi thay đổi thật.

Ví dụ:

```bash
terraform apply
```

Terraform sẽ:

```text
Tạo plan
    ↓
Hỏi confirm yes
    ↓
Gọi API provider, ví dụ AWS API
    ↓
Tạo / sửa / xóa resource thật
    ↓
Cập nhật state
```

Ví dụ nếu code có EC2 mới, `apply` sẽ gọi AWS để tạo EC2 thật.

Điểm quan trọng:

- `apply` có thể thay đổi hạ tầng thật.
- Cần review kỹ plan trước khi gõ `yes`.
- Trong CI/CD production thường cần approval trước bước apply.

### c. `terraform refresh`

`terraform refresh` dùng để đọc trạng thái resource thật và cập nhật lại state.

Nó không tạo/sửa/xóa resource thật, nhưng nó có thể sửa state.

Ví dụ:

```bash
terraform refresh
```

Flow đơn giản:

```text
Đọc resource thật trên cloud
        ↓
Cập nhật terraform.tfstate
```

Tuy nhiên hiện tại `terraform refresh` là command đã deprecated. Cách được khuyến nghị hơn là dùng refresh-only:

```bash
terraform plan -refresh-only
terraform apply -refresh-only
```

Khác nhau:

- `terraform plan -refresh-only`: xem state sẽ thay đổi gì nếu đồng bộ với resource thật.
- `terraform apply -refresh-only`: cập nhật state để khớp resource thật.

Em hiểu đơn giản:

| Lệnh | Mục đích | Có đổi resource thật không? | Có đổi state không? |
| :--- | :--- | :--- | :--- |
| `terraform plan` | Xem trước thay đổi | Không | Không phải mục đích chính |
| `terraform apply` | Apply thay đổi thật | Có | Có |
| `terraform refresh` | Đồng bộ state với resource thật | Không | Có |
| `terraform plan -refresh-only` | Xem drift/state sẽ đổi gì | Không | Không |
| `terraform apply -refresh-only` | Cập nhật state theo resource thật | Không | Có |

## 3. Tại sao nên dùng remote backend?

### a. Backend là gì?

Backend là nơi Terraform lưu state.

Nếu không cấu hình gì, Terraform dùng local backend:

```text
terraform.tfstate nằm ngay trong folder project
```

Với lab cá nhân thì local backend ổn. Nhưng với team hoặc production thì nên dùng remote backend.

Ví dụ remote backend AWS:

```text
S3 bucket        → lưu file state
DynamoDB table  → lock state khi apply
```

### b. Vì sao nên dùng S3 để lưu state?

S3 giúp state được lưu tập trung.

Lợi ích:

- Team cùng dùng một state duy nhất.
- CI/CD runner cũng đọc được state.
- Không cần truyền file `terraform.tfstate` qua lại.
- Có thể bật versioning để rollback state khi cần.
- Có thể bật encryption để bảo vệ state.
- Có thể giới hạn quyền bằng IAM.

Ví dụ:

```hcl
terraform {
  backend "s3" {
    bucket         = "tfstate-chien-demo"
    key            = "phase1/week2/day3.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tfstate-lock"
    encrypt        = true
  }
}
```

Khi đó state không còn nằm local nữa, mà nằm trên S3.

### c. DynamoDB lock dùng để làm gì?

DynamoDB lock dùng để tránh nhiều người hoặc nhiều pipeline apply cùng lúc.

Ví dụ nếu không có lock:

```text
User A terraform apply
User B terraform apply
CI pipeline terraform apply
```

Cả 3 cùng sửa state thì rất nguy hiểm.

Khi có lock:

```text
User A apply → giữ lock
User B apply → phải chờ hoặc fail vì state đang bị lock
```

Nhờ đó state không bị ghi đè lung tung.

### d. Lưu ý thực tế về S3 lock mới

Theo docs Terraform mới, S3 backend hiện có thể dùng native lockfile của S3, còn DynamoDB-based locking đang ở trạng thái deprecated và có thể bị gỡ trong tương lai.

Nhưng trong nhiều hệ thống cũ và trong bài lab này, mô hình S3 + DynamoDB lock vẫn rất phổ biến để học concept:

```text
S3       → remote state
DynamoDB → state lock
```

Khi đi làm thực tế thì nên check version Terraform và guideline của team. Nếu project mới có thể cân nhắc S3 native lockfile nếu công ty đã dùng Terraform version hỗ trợ.

## 4. So sánh module local vs registry

### a. Module là gì?

Module là một nhóm file Terraform được đóng gói lại để tái sử dụng.

Thực ra folder Terraform hiện tại cũng là một module, gọi là root module.

Ví dụ:

```text
2-aws/
├── main.tf
├── variables.tf
└── outputs.tf
```

Nếu tách VPC ra riêng:

```text
modules/
└── vpc/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

thì `modules/vpc` là local module.

### b. Local module

Local module là module nằm trong cùng repo hoặc cùng filesystem.

Ví dụ:

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.20.0.0/16"
}
```

Ưu điểm:

- Dễ viết và sửa nhanh.
- Phù hợp khi module chỉ dùng riêng cho project.
- Không cần publish lên registry.
- Review cùng PR với code chính.
- Không phụ thuộc network để tải module.

Nhược điểm:

- Khó chia sẻ cho nhiều repo khác.
- Versioning không rõ bằng registry module.
- Nếu nhiều project copy/paste module local thì sau này update rất mệt.

### c. Registry module

Registry module là module lấy từ Terraform Registry hoặc private registry.

Ví dụ public registry:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "demo-vpc"
  cidr = "10.20.0.0/16"
}
```

Ưu điểm:

- Có version rõ ràng.
- Dễ tái sử dụng giữa nhiều repo.
- Thường có README, input, output, example.
- Module phổ biến thường đã cover nhiều best practice.
- Phù hợp cho team/platform dùng chung.

Nhược điểm:

- Cần tin tưởng source module.
- Module lớn đôi khi hơi phức tạp so với nhu cầu nhỏ.
- Update version cần đọc changelog, vì có thể breaking change.
- Nếu dùng public module thì phải kiểm tra security và maintenance.

### d. Bảng so sánh nhanh

| Tiêu chí | Local module | Registry module |
| :--- | :--- | :--- |
| Vị trí | Trong repo/local folder | Public/private registry |
| Cách gọi | `source = "./modules/vpc"` | `source = "terraform-aws-modules/vpc/aws"` |
| Versioning | Theo commit của repo chính | Có `version` riêng |
| Phù hợp | Module nhỏ, nội bộ project | Module dùng lại nhiều nơi |
| Ưu điểm | Dễ sửa, dễ review | Chuẩn hóa, dễ share |
| Nhược điểm | Khó tái sử dụng rộng | Cần quản lý version và trust |

Em hiểu đơn giản:

- Đang học hoặc project nhỏ → local module dễ hiểu hơn.
- Team nhiều repo dùng chung VPC/IAM/EKS pattern → registry/private registry hợp lý hơn.

## 5. count vs for_each — khi nào dùng cái nào?

### a. Điểm giống nhau

`count` và `for_each` đều dùng để tạo nhiều instance của cùng một resource/module.

Ví dụ cần tạo nhiều subnet, nhiều IAM user, nhiều security group rule.

Lưu ý: một resource block không thể dùng cả `count` và `for_each` cùng lúc.

### b. `count`

`count` nhận một số nguyên.

Ví dụ tạo 3 file:

```hcl
resource "local_file" "demo" {
  count = 3

  filename = "${path.module}/out/file-${count.index}.txt"
  content  = "hello ${count.index}"
}
```

Terraform sẽ tạo:

```text
local_file.demo[0]
local_file.demo[1]
local_file.demo[2]
```

Nên dùng `count` khi:

- Các resource gần như giống nhau.
- Chỉ khác nhau theo index.
- Cần bật/tắt resource đơn giản.

Ví dụ bật/tắt bằng biến:

```hcl
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0

  ami           = var.ami_id
  instance_type = "t3.micro"
}
```

Nhược điểm của `count` là phụ thuộc index. Nếu list thay đổi thứ tự, Terraform có thể hiểu nhầm và replace resource không cần thiết.

Ví dụ ban đầu:

```hcl
users = ["alice", "bob", "charlie"]
```

Sau đó xóa `"alice"`:

```hcl
users = ["bob", "charlie"]
```

Index của `bob` và `charlie` bị đổi, dễ gây diff khó chịu.

### c. `for_each`

`for_each` nhận map hoặc set.

Ví dụ tạo file theo từng tên:

```hcl
resource "local_file" "demo" {
  for_each = toset(["alice", "bob", "charlie"])

  filename = "${path.module}/out/${each.key}.txt"
  content  = "hello ${each.key}"
}
```

Terraform sẽ tạo:

```text
local_file.demo["alice"]
local_file.demo["bob"]
local_file.demo["charlie"]
```

Nên dùng `for_each` khi:

- Mỗi resource có tên/key riêng.
- Mỗi resource có config khác nhau.
- Muốn địa chỉ resource ổn định.
- Dữ liệu đầu vào là map/object.

Ví dụ tạo subnet:

```hcl
variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.key
  }
}
```

Input:

```hcl
public_subnets = {
  public-a = {
    cidr = "10.20.1.0/24"
    az   = "ap-southeast-1a"
  }
  public-b = {
    cidr = "10.20.2.0/24"
    az   = "ap-southeast-1b"
  }
}
```

Địa chỉ resource sẽ là:

```text
aws_subnet.public["public-a"]
aws_subnet.public["public-b"]
```

Nhìn dễ hiểu hơn `aws_subnet.public[0]`, `aws_subnet.public[1]`.

### d. Chọn cái nào?

| Trường hợp | Nên dùng |
| :--- | :--- |
| Tạo N resource giống nhau | `count` |
| Bật/tắt resource bằng boolean | `count` |
| Resource có key/tên riêng | `for_each` |
| Resource có config khác nhau | `for_each` |
| Dữ liệu là map/object | `for_each` |
| Muốn tránh lỗi đổi index | `for_each` |

Rule em nhớ:

```text
Nếu resource có danh tính riêng → for_each
Nếu chỉ cần số lượng → count
```

## 6. Drift là gì, cách phát hiện & xử lý?

### a. Drift là gì?

Drift là tình trạng hạ tầng thật bị lệch so với Terraform code hoặc Terraform state.

Ví dụ Terraform code khai báo:

```hcl
instance_type = "t3.micro"
```

Nhưng ai đó vào AWS Console sửa EC2 thành:

```text
t3.small
```

Lúc này Terraform code nói một kiểu, AWS thật lại đang một kiểu. Đó là drift.

### b. Nguyên nhân gây drift

Một số nguyên nhân thường gặp:

- Có người sửa tay trên AWS Console.
- Có người dùng AWS CLI sửa trực tiếp.
- Một tool khác ngoài Terraform sửa resource.
- Hotfix production khẩn cấp nhưng quên update Terraform code.
- Resource bị xóa tay.
- Cloud provider tự thay đổi default value.
- Autoscaling hoặc managed service tự sinh/sửa một số resource phụ.

Không phải drift nào cũng xấu, nhưng drift cần được phát hiện để team biết hạ tầng thật đang khác code.

### c. Cách phát hiện drift

#### Cách 1: Chạy `terraform plan`

```bash
terraform plan
```

Nếu có drift, Terraform thường sẽ hiện diff.

Ví dụ:

```text
~ instance_type = "t3.small" -> "t3.micro"
```

Nghĩa là hạ tầng thật đang là `t3.small`, còn code muốn đưa về `t3.micro`.

#### Cách 2: Chạy refresh-only plan

Cách an toàn để kiểm tra state/resource thật:

```bash
terraform plan -refresh-only
```

Lệnh này giúp xem state sẽ thay đổi gì nếu đồng bộ lại với resource thật, nhưng chưa apply.

Nếu muốn cập nhật state theo resource thật:

```bash
terraform apply -refresh-only
```

Nhưng cần cẩn thận: không nên refresh/apply bừa nếu chưa hiểu vì sao drift xảy ra.

#### Cách 3: Dùng CI định kỳ

Trong thực tế có thể tạo scheduled pipeline:

```bash
terraform plan -detailed-exitcode
```

Ý nghĩa exit code:

```text
0 = không có diff
1 = lỗi
2 = có diff
```

Nếu exit code là `2`, pipeline có thể báo là có drift để team kiểm tra.

#### Cách 4: So sánh với cloud console / audit log

Ví dụ trên AWS có thể xem:

- AWS Console.
- CloudTrail.
- Config.
- Tag owner.
- Lịch sử thay đổi của resource.

Mục tiêu là biết ai hoặc tool nào đã sửa resource ngoài Terraform.

### d. Cách xử lý drift

Khi phát hiện drift, không nên apply ngay lập tức. Nên xác định drift đó là đúng hay sai.

#### Trường hợp 1: Drift là sai

Ví dụ ai đó sửa security group mở port `22` cho `0.0.0.0/0`.

Code Terraform vẫn đúng, hạ tầng thật bị sửa sai.

Cách xử lý:

```bash
terraform plan
terraform apply
```

Terraform sẽ đưa hạ tầng thật về lại đúng với code.

#### Trường hợp 2: Drift là thay đổi đúng nhưng chưa update code

Ví dụ team tăng EC2 từ `t3.micro` lên `t3.small` vì app thiếu RAM.

Nếu thay đổi đó là đúng, cần update Terraform code:

```hcl
instance_type = "t3.small"
```

Sau đó chạy:

```bash
terraform plan
terraform apply
```

Như vậy code lại trở thành source of truth.

#### Trường hợp 3: Resource bị tạo ngoài Terraform nhưng giờ muốn Terraform quản lý

Nếu resource được tạo tay ngoài AWS Console, Terraform chưa biết resource đó.

Cách xử lý là import:

```bash
terraform import aws_instance.web i-0123456789
```

Sau đó viết code `.tf` tương ứng và chạy plan để chỉnh cho khớp.

#### Trường hợp 4: Resource trong state nhưng thực tế đã bị xóa

Nếu resource bị xóa tay, `terraform plan` thường báo sẽ tạo lại.

Cần quyết định:

- Nếu vẫn cần resource → để Terraform tạo lại bằng `apply`.
- Nếu không cần resource nữa → xóa khỏi code hoặc dùng `terraform state rm` nếu chỉ muốn bỏ quản lý.

### e. Cách hạn chế drift

- Hạn chế sửa tay trên cloud console.
- Dùng PR review cho Terraform code.
- Chạy `terraform plan` trong CI.
- Dùng remote backend + locking.
- Phân quyền IAM rõ ràng, không ai cũng có quyền sửa production.
- Ghi lại emergency change và update Terraform code sau đó.
- Dùng tag để biết resource thuộc Terraform/project nào.

Em hiểu ngắn gọn:

```text
Terraform code là ý định mong muốn.
State là trí nhớ của Terraform.
Cloud resource là thực tế.

Drift xảy ra khi 3 cái này không còn khớp nhau.
```

## Reference

- Terraform State: https://developer.hashicorp.com/terraform/language/state
- Sensitive data in Terraform state: https://developer.hashicorp.com/terraform/language/manage-sensitive-data
- Terraform refresh command: https://developer.hashicorp.com/terraform/cli/commands/refresh
- Refresh-only mode: https://developer.hashicorp.com/terraform/tutorials/state/refresh
- S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3
- Terraform modules: https://developer.hashicorp.com/terraform/language/modules
- Module sources: https://developer.hashicorp.com/terraform/language/modules/configuration
- `for_each` reference: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each
- Resource drift: https://developer.hashicorp.com/terraform/tutorials/state/resource-drift
