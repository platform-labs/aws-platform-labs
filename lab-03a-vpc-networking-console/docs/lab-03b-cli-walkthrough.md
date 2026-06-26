# AWS Hands-on Lab #3B

## Custom VPC Networking — một phần bằng AWS CLI

### Mục tiêu

Lab 3A đã tạo toàn bộ VPC qua Console. Lab 3B **không tạo lại từ đầu** — chỉ thực hành một phần qua CLI để thấy Console thực chất gọi API nào, và để quen cú pháp `aws ec2` trước khi viết Terraform ở Lab 4 (Terraform cũng gọi đúng những API này, chỉ khác cách khai báo).

> **CIDR trong file này: `10.20.0.0/16` — CLI Learning Sandbox, throwaway.**
> Khác với `10.10.0.0/16` (Source of Truth, VPC chính ở Lab 3A, đã verify, giữ nguyên). Không bao giờ chạy lệnh xoá/sửa nhắm vào `10.10.0.0/16` trong file này.

Phạm vi Lab 3B: tạo **một VPC test riêng, nhỏ, tách biệt khỏi VPC chính của Lab 3A** — để không ảnh hưởng tới VPC đã verify xong. Chỉ làm 3 resource: VPC, Subnet, Route Table — đủ để thấy dependency, không cần lặp lại toàn bộ NAT/SG.

> Lưu ý: không cần làm full 6 subnet + NAT + SG lại bằng CLI. Mục tiêu là "thấy API", không phải "build lại lab". Sau phần này, xoá VPC test ngay.

---

# Prerequisites

* AWS CLI đã configure (`aws configure` hoặc IAM Identity Center)
* Region: `us-east-1`
* Đã đọc [`lab-03a-hands-on.md`](./lab-03a-hands-on.md)

---

# Step 1 - Tạo VPC test

```bash
aws ec2 create-vpc \
  --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=csnp-cli-test-vpc}]'
```

Output trả về JSON chứa `VpcId`, ví dụ `vpc-0abc123`. **Lưu lại ID này** — CLI không tự nhớ context như Console, mọi lệnh sau đều cần truyền ID thủ công.

```bash
export TEST_VPC_ID=vpc-0abc123   # thay bằng VpcId thật từ output trên
```

## So với Console

Console "Create VPC" thực chất gọi đúng API `CreateVpc` này — chỉ khác là Console tự lưu context (bạn không cần nhớ VPC ID, chỉ cần click chọn từ dropdown).

---

# Step 2 - Tạo Subnet trong VPC test

```bash
aws ec2 create-subnet \
  --vpc-id $TEST_VPC_ID \
  --cidr-block 10.20.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=csnp-cli-test-subnet}]'
```

Lưu `SubnetId` từ output:

```bash
export TEST_SUBNET_ID=subnet-0xyz789   # thay bằng SubnetId thật
```

## Verify bằng CLI

```bash
aws ec2 describe-subnets --subnet-ids $TEST_SUBNET_ID
```

So sánh field `VpcId`, `CidrBlock`, `AvailabilityZone` trong output với những gì Console hiển thị ở Lab 3A — đây chính là cùng một dữ liệu, chỉ hiển thị khác hình thức.

---

# Step 3 - Tạo Route Table và Associate

```bash
aws ec2 create-route-table \
  --vpc-id $TEST_VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=csnp-cli-test-rt}]'
```

Lưu `RouteTableId`:

```bash
export TEST_RT_ID=rtb-0def456   # thay bằng RouteTableId thật
```

Associate Route Table với Subnet — đây chính là bước "Route Table Association" đã nhấn mạnh ở Lab 3A:

```bash
aws ec2 associate-route-table \
  --route-table-id $TEST_RT_ID \
  --subnet-id $TEST_SUBNET_ID
```

## Verify route table đang trống (chỉ có local route)

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Routes"
```

Kỳ vọng: chỉ thấy 1 route, `DestinationCidrBlock: 10.20.0.0/16`, `GatewayId: local` — giống đúng cấu trúc của Private Data Route Table ở Lab 3A, chưa thêm gì cả.

## Tại sao tách `create-route-table` và `associate-route-table` thành 2 lệnh riêng?

Đúng như Console — tạo Route Table không tự gắn vào Subnet nào. Phải gọi API `AssociateRouteTable` riêng. CLI ở đây phơi bày rõ ràng hơn Console: Console "ẩn" 2 bước này dưới 1 màn hình "Edit subnet associations", còn CLI buộc bạn gọi 2 API riêng biệt, thấy rõ chúng là 2 hành động độc lập.

---

# Step 4 - Cleanup VPC test

Xoá theo đúng thứ tự ngược lại với khi tạo — đây là điểm CLI dạy rất rõ về dependency mà Console che giấu bằng cách tự chặn nút Delete nếu còn dependency:

```bash
# Disassociate trước (cần Association ID, lấy từ describe-route-tables)
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Associations[0].RouteTableAssociationId"

aws ec2 disassociate-route-table --association-id <association-id-tu-lenh-tren>

# Xoá Route Table
aws ec2 delete-route-table --route-table-id $TEST_RT_ID

# Xoá Subnet
aws ec2 delete-subnet --subnet-id $TEST_SUBNET_ID

# Xoá VPC
aws ec2 delete-vpc --vpc-id $TEST_VPC_ID
```

## Tại sao thứ tự xoá ngược lại thứ tự tạo?

VPC không xoá được khi còn Subnet bên trong. Subnet không xoá được khi còn Route Table Association. Đây chính là dependency graph — Terraform ở Lab 4 sẽ tự tính toán thứ tự này (`terraform destroy` tự đảo ngược dependency graph), nhưng CLI buộc bạn tự làm tay, giúp hiểu rõ tại sao Terraform cần biết dependency giữa resource.

---

# Lessons Learned

* Console và CLI gọi đúng cùng một API AWS — khác biệt duy nhất là Console tự lưu context (ID) và tự chặn xoá khi còn dependency, CLI để bạn tự quản lý cả hai.
* `create-route-table` và `associate-route-table` là 2 API riêng — Console gộp lại thành 1 màn hình khiến nhiều người không nhận ra đây là 2 bước.
* Thứ tự xoá luôn ngược thứ tự tạo khi có dependency (VPC ← Subnet ← Route Table Association) — đây chính là điều Terraform tự động hoá ở Lab 4 qua dependency graph.
* Chi tiết Q&A phỏng vấn xem [`lab-03-interview-notes.md`](./lab-03-interview-notes.md).
