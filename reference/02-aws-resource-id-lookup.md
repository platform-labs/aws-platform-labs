# 02 - AWS Resource ID Lookup Cho Terraform

## Mục tiêu

Khi gặp các placeholder trong Terraform

```hcl
vpc_id     = vpc-xxxxxxxx
subnet_ids = [subnet-xxxxxxxx, subnet-yyyyyyyy]
```

sử dụng các lệnh AWS CLI dưới đây để lấy giá trị thật từ tài khoản AWS.

---

## 1. Lấy Default VPC ID

```powershell
aws ec2 describe-vpcs `
  --filters Name=is-default,Values=true `
  --query "Vpcs[].[VpcId,CidrBlock]" `
  --output table
```

Ví dụ kết quả

```text
-----------------------------------------
             DescribeVpcs              
+----------------------+---------------+
 vpc-04b3930827c2b5358 172.31.0.016 
+----------------------+---------------+
```

Terraform

```hcl
vpc_id = vpc-04b3930827c2b5358
```

---

## 2. Lấy Subnet IDs Trong VPC

```powershell
aws ec2 describe-subnets `
  --filters Name=vpc-id,Values=vpc-04b3930827c2b5358 `
  --query "Subnets[].[SubnetId,AvailabilityZone]" `
  --output table
```

Ví dụ

```text
------------------------------------------------
              DescribeSubnets                 
+---------------------------+------------------+
 subnet-0b9ff24f38501582e   us-east-1a       
 subnet-0777ba429cdf585b1   us-east-1b       
 subnet-0a335aeab0c32a4fa   us-east-1c       
+---------------------------+------------------+
```

Terraform

```hcl
subnet_ids = [
  subnet-0b9ff24f38501582e,
  subnet-0777ba429cdf585b1
]
```

Lưu ý

 Đối với RDS nên chọn ít nhất 2 subnet ở 2 Availability Zone khác nhau.
 Ví dụ

   us-east-1a
   us-east-1b

---

## 3. Lấy Security Group IDs

Khi gặp

```hcl
security_group_id = sg-xxxxxxxx
```

Chạy

```powershell
aws ec2 describe-security-groups `
  --query "SecurityGroups[].[GroupId,GroupName]" `
  --output table
```

Ví dụ

```text
sg-0123456789abcdef0   default
sg-0fedcba9876543210   csnp-rds-sg
```

---

## 4. Lấy Route Table IDs

Khi gặp

```hcl
route_table_id = rtb-xxxxxxxx
```

Chạy

```powershell
aws ec2 describe-route-tables `
  --query "RouteTables[].[RouteTableId]" `
  --output table
```

---

## 5. Lấy Internet Gateway IDs

Khi gặp

```hcl
internet_gateway_id = igw-xxxxxxxx
```

Chạy

```powershell
aws ec2 describe-internet-gateways `
  --query "InternetGateways[].[InternetGatewayId]" `
  --output table
```

---

## 6. Lấy Key Pair Names

Khi gặp

```hcl
key_name = wallet-dev-key
```

Chạy

```powershell
aws ec2 describe-key-pairs `
  --query "KeyPairs[].[KeyName]" `
  --output table
```

---

## 7. Lấy Availability Zones

```powershell
aws ec2 describe-availability-zones `
  --query "AvailabilityZones[].[ZoneName]" `
  --output table
```

Ví dụ

```text
us-east-1a
us-east-1b
us-east-1c
us-east-1d
us-east-1e
us-east-1f
```

---

## 8. Lấy Amazon Linux 2023 AMI Mới Nhất

```powershell
aws ec2 describe-images `
  --owners amazon `
  --filters Name=name,Values=al2023-ami-* `
  --query "sort_by(Images,&CreationDate)[-1].[ImageId,Name,CreationDate]" `
  --output table `
  --no-cli-pager
```

Ví dụ

```text
ami-00b29fdf0856a3c47
```

Terraform

```hcl
ami = ami-00b29fdf0856a3c47
```

---

## 9. Bộ Lệnh AWS CLI Dùng Thường Xuyên Nhất Cho Terraform

```powershell
# VPC
aws ec2 describe-vpcs --output table --no-cli-pager

# Subnets
aws ec2 describe-subnets --output table --no-cli-pager

# Security Groups
aws ec2 describe-security-groups --output table --no-cli-pager

# Route Tables
aws ec2 describe-route-tables --output table --no-cli-pager

# Internet Gateways
aws ec2 describe-internet-gateways --output table --no-cli-pager

# Key Pairs
aws ec2 describe-key-pairs --output table --no-cli-pager

# Availability Zones
aws ec2 describe-availability-zones --output table --no-cli-pager

# AMIs
aws ec2 describe-images --owners amazon --filters Name=name,Values=al2023-ami-* --query "sort_by(Images,&CreationDate)[-1].[ImageId,Name,CreationDate]" --output table --no-cli-pager
```

---

## Quy Tắc Nhớ Nhanh

Khi thấy

```hcl
vpc-xxxxxxxx
subnet-xxxxxxxx
sg-xxxxxxxx
rtb-xxxxxxxx
igw-xxxxxxxx
ami-xxxxxxxx
```

= Không đoán.

= Luôn dùng AWS CLI để lấy ID thật từ account hiện tại.

= Terraform chỉ nên dùng resource IDs tồn tại trong account AWS đang thao tác.
