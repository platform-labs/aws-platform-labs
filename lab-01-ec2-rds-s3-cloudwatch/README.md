# Lab 01 - EC2 + RDS PostgreSQL + S3 + IAM Role + CloudWatch

## Mục tiêu

Deploy Wallet API (minimal API .NET, không phải CSNP Wallet thật) lên AWS. Sau lab này cần hiểu được:

* IAM Role (thay cho Access Key)
* EC2
* Security Group
* RDS PostgreSQL
* S3
* CloudWatch Logs

## Prerequisites

* AWS Account, credit còn khả dụng
* AWS Region: **us-east-1**
* .NET SDK 10 cài sẵn trên máy local

> Lab dùng `Lab01.WalletMinimal` — minimal API .NET tạo riêng cho lab, không dùng Wallet API thật từ CSNP vì CSNP có nhiều dependency (RabbitMQ, Redis, Kafka) chưa cần trong lab này.

## Architecture

```text
                 Internet
                      |
                      v
               Security Group (csnp-ec2-sg)
                      |
                      v
                 EC2 t3.micro
                      |
       +--------------+-------------+
       |                            |
       v                            v
  RDS PostgreSQL               S3 Bucket
  (csnp-rds-sg)             (csnp-wallet-dev)
  Private, no public access

                      |
                      v
               CloudWatch Logs
               (csnp-wallet-api)
```

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| IAM Role | Cấp quyền cho EC2 gọi S3/CloudWatch, không dùng static Access Key |
| EC2 (t3.micro) | Chạy Wallet API |
| Security Group | `csnp-ec2-sg` (SSH chỉ từ My IP), `csnp-rds-sg` (chỉ nhận từ EC2 SG) |
| RDS PostgreSQL (db.t3.micro) | Database, private, không public access |
| S3 | Object storage cho file upload |
| CloudWatch Logs | Log group `csnp-wallet-api` |

## Estimated Cost

| Resource | Chi phí ước tính |
| -------- | ----------------- |
| EC2 t3.micro | Free Tier 750h/tháng |
| RDS db.t3.micro | Free Tier 750h/tháng |
| EBS Volume | Kiểm tra sau khi terminate, xóa nếu state = available |

> NAT Gateway không dùng trong lab này (sẽ ~$32/tháng nếu có). Set AWS Budget alert ở $10.

## Region

`us-east-1`

## Terraform inputs

Terraform state của Lab 1 được lưu trên shared labs S3 backend tại `aws/lab-01/terraform.tfstate`. Chạy [`../bootstrap/`](../bootstrap/) trước lần `terraform init` đầu tiên; không dùng bucket/key production.

Truoc khi chay Terraform, vao thu muc `terraform/` va copy file example:

```powershell
Set-Location .\terraform
Copy-Item .\terraform.tfvars.example .\terraform.tfvars
```

Sau do lay Default VPC ID cua account trong dung region lab:

```bash
aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=true" \
  --query "Vpcs[*].[VpcId,CidrBlock]" \
  --output table \
  --region us-east-1
```

Neu chay bang PowerShell:

```powershell
aws ec2 describe-vpcs `
  --filters "Name=is-default,Values=true" `
  --query "Vpcs[*].[VpcId,CidrBlock]" `
  --output table `
  --region us-east-1
```

Lay tat ca subnet trong Default VPC vua tim duoc:

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxxxxx" \
  --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" \
  --output table \
  --region us-east-1
```

PowerShell:

```powershell
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=vpc-xxxxxxxx" `
  --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" `
  --output table `
  --region us-east-1
```

Dien cac gia tri lay duoc vao `terraform.tfvars`:

```hcl
vpc_id     = "vpc-xxxxxxxx"
subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
```

RDS can it nhat 2 subnet, nen chon 2 subnet o 2 Availability Zone khac nhau neu Default VPC co san.

## Cleanup

* [ ] Terminate EC2 instance
* [ ] Delete RDS instance (skip final snapshot, đây là lab)
* [ ] Empty + delete S3 bucket `csnp-wallet-dev`
* [ ] Xóa CloudWatch log group `csnp-wallet-api`
* [ ] Verify EBS volume không còn ở state "available"
* [ ] Nếu chạy qua Terraform: `terraform destroy` trong `terraform/`

## Lessons Learned

* IAM Role dùng temporary credentials (qua IMDS), AWS tự rotate — không cần quản lý secret thủ công như Access Key.
* RDS Security Group nên reference Security Group của EC2, không phải theo IP — vẫn đúng kể cả khi IP của EC2 đổi.
* Chi tiết đầy đủ + Q&A phỏng vấn xem [`docs/lab-01-hands-on.md`](./docs/lab-01-hands-on.md) và [`docs/lab-01-interview-notes.md`](./docs/lab-01-interview-notes.md).

## Security note

Lab này ban đầu có file `wallet-dev-key.pem` (EC2 key pair private key) đi kèm. File đó **không** được đưa vào cấu trúc này và không bao giờ nên commit vào git. Nếu file `.pem` đó đã từng nằm trong một thư mục được track bởi git (kể cả local), coi như key đã lộ — vào AWS Console xoá key pair cũ và tạo key pair mới cho lần chạy lại lab.

## Trạng thái

Lab đã làm thủ công qua Console (xem `docs/lab-01-hands-on.md`). `terraform/` hiện đã dựng lại phần hạ tầng chính tương đương Console: IAM Role/Instance Profile, EC2, Security Groups, RDS PostgreSQL private, S3 private + versioning, CloudWatch Log Group và EC2 bootstrap cho CloudWatch Agent/runtime/log directory. Tên resource trong Terraform được derive từ `project_name` để dễ chạy lại lab nhiều lần. Trước khi chạy vẫn cần điền `terraform.tfvars` (copy từ `.example`) và xác nhận lại `vpc_id`/`subnet_ids`/`my_ip_cidr`; phần publish/copy artifact WalletMinimal lên EC2 vẫn làm theo bước deploy trong hands-on doc.
