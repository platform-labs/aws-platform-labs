# AWS CLI Cheat Sheet for AWS SAA + DevOps + Terraform

> Đây là reference tra lệnh nhanh theo từng service. Về cách AWS CLI hoạt động (profile, credential chain, region, output format, JMESPath, assume role, SSO) xem file `00_AWS_CLI_Fundamentals.md`.

## 1. Authentication & Identity

### Kiểm tra phiên đăng nhập hiện tại

```bash
aws sts get-caller-identity
```

### Xem profile

```bash
aws configure list-profiles
```

### Xem region hiện tại

```bash
aws configure get region
```

### Đổi region

```bash
aws configure set region ap-southeast-1
```

### Cấu hình credential (Access Key)

```bash
aws configure
```

### Cấu hình SSO (IAM Identity Center)

```bash
aws configure sso
```

> Chỉ dùng được nếu tổ chức đã setup IAM Identity Center. Account cá nhân mới tạo nên bắt đầu bằng `aws configure`.

---

## 2. S3

### Liệt kê bucket

```bash
aws s3 ls
```

### Tạo bucket

```bash
aws s3 mb s3://toannv-demo-bucket
```

### Upload file

```bash
aws s3 cp test.txt s3://toannv-demo-bucket/
```

### Download file

```bash
aws s3 cp s3://toannv-demo-bucket/test.txt .
```

### Đồng bộ thư mục

```bash
aws s3 sync ./data s3://toannv-demo-bucket
```

### Xóa object

```bash
aws s3 rm s3://toannv-demo-bucket/test.txt
```

### Xóa bucket

```bash
aws s3 rb s3://toannv-demo-bucket --force
```

---

## 3. EC2

### Liệt kê EC2

```bash
aws ec2 describe-instances
```

### Liệt kê AMI

```bash
aws ec2 describe-images --owners amazon
```

### Liệt kê Security Group

```bash
aws ec2 describe-security-groups
```

### Liệt kê Key Pair

```bash
aws ec2 describe-key-pairs
```

### Start EC2

```bash
aws ec2 start-instances \
--instance-ids i-xxxxxxxx
```

### Stop EC2

```bash
aws ec2 stop-instances \
--instance-ids i-xxxxxxxx
```

### Reboot EC2

```bash
aws ec2 reboot-instances \
--instance-ids i-xxxxxxxx
```

### Terminate EC2

```bash
aws ec2 terminate-instances \
--instance-ids i-xxxxxxxx
```

### Lọc kết quả gọn — query + output table

`describe-*` mặc định trả JSON rất dài, khó đọc trên terminal. Dùng `--query` (JMESPath) để chỉ lấy field cần và `--output table` để hiển thị dạng bảng.

```bash
aws ec2 describe-instances \
--query "Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]" \
--output table
```

Kết quả:

```text
--------------------------------------------
|             DescribeInstances             |
+----------------+------------+-------------+
| i-0123456789ab | running    | t3.micro    |
+----------------+------------+-------------+
```

Pattern này áp dụng được cho hầu hết lệnh `describe-*`/`list-*` trong cheat sheet này — ví dụ:

```bash
aws s3api list-buckets --query "Buckets[*].Name" --output table

aws rds describe-db-instances \
--query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]" \
--output table
```

---

## 4. VPC

### Liệt kê VPC

```bash
aws ec2 describe-vpcs
```

### Liệt kê Subnet

```bash
aws ec2 describe-subnets
```

### Liệt kê Route Table

```bash
aws ec2 describe-route-tables
```

### Liệt kê Internet Gateway

```bash
aws ec2 describe-internet-gateways
```

---

## 5. IAM

### Liệt kê user

```bash
aws iam list-users
```

### Liệt kê role

```bash
aws iam list-roles
```

### Xem role

```bash
aws iam get-role \
--role-name MyRole
```

### Liệt kê policy

```bash
aws iam list-policies
```

---

## 6. CloudWatch

### Liệt kê log groups

```bash
aws logs describe-log-groups
```

### Xem log stream

```bash
aws logs describe-log-streams \
--log-group-name my-app
```

### Xem log events

```bash
aws logs get-log-events \
--log-group-name my-app
```

---

## 7. ECR

### Liệt kê repository

```bash
aws ecr describe-repositories
```

### Login Docker vào ECR

```bash
aws ecr get-login-password \
--region ap-southeast-1 \
| docker login \
--username AWS \
--password-stdin <account>.dkr.ecr.ap-southeast-1.amazonaws.com
```

---

## 8. EKS

### Liệt kê cluster

```bash
aws eks list-clusters
```

### Cập nhật kubeconfig

```bash
aws eks update-kubeconfig \
--name my-cluster
```

### Mô tả cluster

```bash
aws eks describe-cluster \
--name my-cluster
```

---

## 9. RDS

### Liệt kê database

```bash
aws rds describe-db-instances
```

### Start DB

```bash
aws rds start-db-instance \
--db-instance-identifier mydb
```

### Stop DB

```bash
aws rds stop-db-instance \
--db-instance-identifier mydb
```

> **Lưu ý thi SAA:** RDS stop không phải vô thời hạn — AWS tự động start lại instance sau **7 ngày** nếu không start thủ công trước đó. Đây là điểm hay bị hỏi và cũng dễ gây bất ngờ về chi phí nếu quên.

---

## 10. Terraform Validation

Luôn chạy trước Terraform Apply

```bash
aws sts get-caller-identity
```

Kiểm tra region

```bash
aws configure get region
```

Kiểm tra resource

```bash
aws ec2 describe-instances
```

Sau đó mới:

```bash
terraform plan
terraform apply
```

---

# Bài Thực Hành Hằng Ngày

## Lab 1

* Login AWS CLI
* Kiểm tra account bằng STS
* Tạo S3 bucket
* Upload file
* Download file
* Xóa bucket

## Lab 2

* Tạo EC2 bằng Console
* Dùng CLI liệt kê EC2
* Stop
* Start
* Terminate

## Lab 3

* Tạo IAM User
* Tạo IAM Role
* Xem ARN
* Xem Policy

## Lab 4

* Tạo VPC
* Tạo Subnet
* Kiểm tra bằng CLI

## Lab 5

* Cài Terraform
* Tạo EC2 bằng Terraform
* Verify bằng AWS CLI
* Destroy bằng Terraform

Mục tiêu: làm được toàn bộ 5 lab mà không cần nhìn tài liệu.
