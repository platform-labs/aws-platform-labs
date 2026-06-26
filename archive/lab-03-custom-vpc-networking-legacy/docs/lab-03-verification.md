# Lab 03 - Verification Steps

Chạy sau khi `terraform apply` xong. Lấy IP/ID cần thiết từ `terraform output`.

## 1. SSH vào network-test-ec2 qua Public IP

```bash
terraform output network_test_ec2_public_ip
ssh -i /path/to/your-key.pem ec2-user@<public-ip>
```

Kỳ vọng: kết nối thành công. Đây là chứng minh Public Subnet → IGW route hoạt động và Security Group SSH rule (chỉ từ `my_ip_cidr`) đúng.

## 2. Từ network-test-ec2, curl ra internet

```bash
# (đang SSH trong network-test-ec2)
curl -s https://checkip.amazonaws.com
sudo dnf update -y    # Amazon Linux 2023 dùng dnf, không phải apt
```

Kỳ vọng: cả hai lệnh chạy được. Public Subnet có Public IP + route `0.0.0.0/0 -> IGW` nên ra internet trực tiếp, không cần NAT.

## 3. Verify Private App Subnet ra internet được qua NAT (không có Public IP)

Đây là bước quan trọng nhất của lab — chứng minh NAT Gateway hoạt động đúng. Cách đơn giản nhất không cần dựng thêm EC2 trong Private App Subnet: dùng VPC Reachability Analyzer hoặc kiểm tra route table trực tiếp.

**Cách A — kiểm tra route table (không tốn thêm resource):**

```bash
terraform output -raw private_app_subnet_ids
# lấy 1 subnet id, ví dụ subnet-0abc123

aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-0abc123" \
  --query "RouteTables[0].Routes"
```

Kỳ vọng: thấy 1 route với `DestinationCidrBlock: 0.0.0.0/0` và `NatGatewayId` (không phải `GatewayId` của IGW).

Cách A là đủ cho mục tiêu Lab 3. Cách B (thực nghiệm thật qua Session Manager) nằm ở phần **Optional Advanced Verification** cuối file — cần thêm IAM Role/Endpoint ngoài scope lab này, nên không phải bước bắt buộc.

## 4. Verify Private Data Subnet KHÔNG có route internet

```bash
terraform output -raw private_data_subnet_ids
# lấy 1 subnet id

aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=subnet-0xyz789" \
  --query "RouteTables[0].Routes"
```

Kỳ vọng: chỉ có 1 route — `10.10.0.0/16 -> local`. Không có bất kỳ route `0.0.0.0/0` nào (không IGW, không NAT).

## 5. (Sau Lab 4) Verify RDS không public, chỉ ECS SG gọi được

```bash
aws rds describe-db-instances \
  --db-instance-identifier <your-db-id> \
  --query "DBInstances[0].PubliclyAccessible"
```

Kỳ vọng: `false`.

```bash
aws ec2 describe-security-groups \
  --group-ids <rds-sg-id> \
  --query "SecurityGroups[0].IpPermissions"
```

Kỳ vọng: ingress rule cho port 5432 chỉ reference `UserIdGroupPairs` (Security Group ID của ECS), không có `IpRanges` nào chứa `0.0.0.0/0`.

## Cleanup sau verification

```bash
# Xoá riêng test EC2 nếu không cần giữ VPC để làm Lab 4 ngay
terraform destroy -target=aws_instance.network_test

# Hoặc xoá toàn bộ Lab 3 (chỉ làm nếu KHÔNG định làm Lab 4 tiếp ngay)
terraform destroy
```

## Optional Advanced Verification (ngoài scope chính của Lab 3)

Nếu muốn verify NAT bằng thực nghiệm thật (curl từ chính một instance nằm trong Private App Subnet, không chỉ đọc route table), cần thêm:

* 1 EC2 trong Private App Subnet, không gán Public IP
* IAM Role cho SSM (`AmazonSSMManagedInstanceCore`) để SSH vào qua [Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) — Private App Subnet không có Public IP nên SSH thường không vào được trực tiếp
* VPC Endpoint cho SSM (hoặc route ra internet qua NAT đã đủ nếu SSM Agent gọi được endpoint public)

Đây là bài tập mở rộng tốt nếu muốn thực hành thêm SSM, nhưng không bắt buộc để hoàn thành Lab 3 — Cách A (đọc route table) đã đủ chứng minh thiết kế đúng. Nếu làm:

```bash
# Sau khi SSH vào qua Session Manager:
curl -s https://checkip.amazonaws.com
```

Kỳ vọng: trả về chính là Public IP của NAT Gateway (`terraform output nat_gateway_public_ip`), không phải IP riêng của instance — chứng minh traffic đi ra qua NAT.
