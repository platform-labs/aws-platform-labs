# AWS CLI Hands-on Lab 3B

## Deliberate practice loop

1. **Mental model:** viết create order và destroy order cho VPC → subnet → route table → association.
2. **Console discovery:** mở resource map của VPC sandbox nhưng không tạo bằng Console.
3. **Implementation:** CLI là phương thức chính; tự lưu ID và context như các step bên dưới.
4. **CLI verification:** mọi create command phải có một describe/query command chứng minh kết quả.
5. **Failure drill:** cố xóa VPC trước dependency để đọc `DependencyViolation`, sau đó cleanup đúng thứ tự.
6. **Rebuild without guide:** tạo và xóa sandbox `10.20.0.0/16` mà không copy command.
7. **Cleanup/cost audit:** query lại theo CIDR/tag để chắc chắn sandbox không còn resource.
8. **Interview recap:** giải thích vì sao Terraform state và dependency graph giải quyết pain point vừa trải nghiệm.

Quy tắc luyện nhiều vòng: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Custom VPC Networking — một phần bằng AWS CLI

### Mục tiêu

Lab 3A đã tạo toàn bộ VPC qua Console. Lab 3B **không tạo lại từ đầu** — chỉ thực hành một phần qua CLI để thấy Console thực chất gọi API nào, và để quen cú pháp `aws ec2` trước khi viết Terraform ở Lab 4 (Terraform cũng gọi đúng những API này, chỉ khác cách khai báo).

> **CIDR trong file này: `10.20.0.0/16` — CLI Learning Sandbox, throwaway.**
> Khác với `10.10.0.0/16` (Source of Truth, VPC chính ở Lab 3A, đã verify, giữ nguyên). **Không bao giờ chạy lệnh xoá/sửa nhắm vào `10.10.0.0/16` trong file này.**

Phạm vi Lab 3B: tạo **một VPC test riêng, nhỏ, tách biệt khỏi VPC chính của Lab 3A** — để không ảnh hưởng tới VPC đã verify xong. Chỉ làm 3 resource: VPC, Subnet, Route Table — đủ để thấy dependency, không cần lặp lại toàn bộ NAT/SG.

> **Lưu ý:** Không cần làm full 6 subnet + NAT + SG lại bằng CLI. Mục tiêu là "thấy API", không phải "build lại lab". Sau phần này, xoá VPC test ngay.

---

## Prerequisites

* AWS CLI phiên bản >= 2.0 cài sẵn (`aws --version` để check)
* AWS CLI đã configure (`aws configure` hoặc IAM Identity Center)
* Region: `us-east-1`
* Đã đọc [`../../lab-03a-vpc-networking-console/README.md`](../../lab-03a-vpc-networking-console/README.md) để hiểu Lab 3A

---

## Step 0 — Verify AWS CLI Setup

Trước khi bắt đầu, verify AWS CLI hoạt động đúng:

```bash
# Check phiên bản
aws --version

# Verify credential (nên thấy Account ID, ARN, User ID)
aws sts get-caller-identity
```

Output mong đợi:

```json
{
    "UserId": "...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-name"
}
```

Nếu có lỗi credential → chạy `aws configure` và nhập AWS Access Key ID + Secret.

---

## Step 1 - Tạo VPC test

Gọi API `CreateVpc`:

```bash
aws ec2 create-vpc \
  --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=csnp-cli-test-vpc}]'
```

Output sẽ trông như:

```json
{
    "Vpc": {
        "VpcId": "vpc-0abc123def456",
        "CidrBlock": "10.20.0.0/16",
        "State": "available",
        "Tags": [{"Key": "Name", "Value": "csnp-cli-test-vpc"}]
    }
}
```

**Lưu lại `VpcId`** — CLI không tự nhớ context như Console, mọi lệnh sau đều cần truyền ID thủ công:

```bash
# macOS / Linux / WSL2
export TEST_VPC_ID=vpc-0abc123def456   # thay bằng VpcId thật từ output trên

# Windows PowerShell
$env:TEST_VPC_ID = "vpc-0abc123def456"
```

### So với Console

Console button "Create VPC" thực chất gọi đúng API `CreateVpc` này — chỉ khác là Console tự lưu context (bạn không cần nhớ VPC ID, chỉ cần click chọn từ dropdown).

---

## Step 2 - Tạo Subnet trong VPC test

```bash
aws ec2 create-subnet \
  --vpc-id $TEST_VPC_ID \
  --cidr-block 10.20.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=csnp-cli-test-subnet}]'
```

Output:

```json
{
    "Subnet": {
        "SubnetId": "subnet-0xyz789abc123",
        "VpcId": "vpc-0abc123def456",
        "CidrBlock": "10.20.1.0/24",
        "AvailabilityZone": "us-east-1a",
        ...
    }
}
```

**Lưu `SubnetId`:**

```bash
# macOS / Linux / WSL2
export TEST_SUBNET_ID=subnet-0xyz789abc123

# Windows PowerShell
$env:TEST_SUBNET_ID = "subnet-0xyz789abc123"
```

### Verify bằng CLI

```bash
aws ec2 describe-subnets --subnet-ids $TEST_SUBNET_ID
```

So sánh field `VpcId`, `CidrBlock`, `AvailabilityZone` trong output với những gì Console hiển thị ở Lab 3A — đây chính là cùng một dữ liệu, chỉ hiển thị khác hình thức.

---

## Step 3 - Tạo Route Table và Associate

### 3A - Tạo Route Table

```bash
aws ec2 create-route-table \
  --vpc-id $TEST_VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=csnp-cli-test-rt}]'
```

Output:

```json
{
    "RouteTable": {
        "RouteTableId": "rtb-0def456ghi789",
        "VpcId": "vpc-0abc123def456",
        "Routes": [
            {
                "DestinationCidrBlock": "10.20.0.0/16",
                "GatewayId": "local",
                "State": "active"
            }
        ],
        ...
    }
}
```

**Lưu `RouteTableId`:**

```bash
export TEST_RT_ID=rtb-0def456ghi789

# Windows PowerShell
$env:TEST_RT_ID = "rtb-0def456ghi789"
```

### 3B - Associate Route Table với Subnet

Đây chính là bước "Route Table Association" đã nhấn mạnh ở Lab 3A — tạo Route Table không tự động áp dụng cho Subnet nào:

```bash
aws ec2 associate-route-table \
  --route-table-id $TEST_RT_ID \
  --subnet-id $TEST_SUBNET_ID
```

Output:

```json
{
    "AssociationId": "rtbassoc-01234567890abcdef",
    "AssociationState": {"State": "associating"}
}
```

**Lưu `AssociationId`** — dùng cho cleanup sau:

```bash
export TEST_RT_ASSOC_ID=rtbassoc-01234567890abcdef

# Windows PowerShell
$env:TEST_RT_ASSOC_ID = "rtbassoc-01234567890abcdef"
```

### 3C - Verify Route Table đang trống (chỉ có local route)

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Routes"
```

Kỳ vọng output:

```json
[
    {
        "DestinationCidrBlock": "10.20.0.0/16",
        "GatewayId": "local",
        "State": "active"
    }
]
```

Chỉ thấy **1 route**, `local` — giống đúng cấu trúc của Private Data Route Table ở Lab 3A, chưa thêm gì cả. Nếu có thêm routes (ví dụ 0.0.0.0/0), có thể là Route Table lấy nhầm.

### Tại sao tách `create-route-table` và `associate-route-table` thành 2 lệnh riêng?

Đúng như logic Console — tạo Route Table **không tự động gắn vào Subnet nào**. Phải gọi API `AssociateRouteTable` riêng.

**CLI ở đây phơi bày rõ ràng hơn Console:** Console "ẩn" 2 bước này dưới 1 màn hình "Edit subnet associations", còn CLI buộc bạn gọi 2 API riêng biệt → bạn thấy rõ chúng là 2 hành động độc lập, không phải 1 phép toán kết hợp.

Đây là điểm mạnh của CLI — dạy rõ ràng API structure.

---

## Step 4 - Cleanup VPC test

**QUAN TRỌNG:** Xoá theo đúng thứ tự ngược lại với khi tạo. Đây là điểm CLI dạy rất rõ về dependency mà Console che giấu bằng cách tự chặn nút Delete nếu còn dependency.

### 4A - Disassociate Route Table

```bash
aws ec2 disassociate-route-table \
  --association-id $TEST_RT_ASSOC_ID
```

(Nếu không lưu `AssociationId` từ lúc tạo, query lại:)

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Associations[0].RouteTableAssociationId" \
  --output text
```

Lệnh này trả về Association ID, copy và chạy `disassociate-route-table` với nó.

### 4B - Xoá Route Table

```bash
aws ec2 delete-route-table --route-table-id $TEST_RT_ID
```

### 4C - Xoá Subnet

```bash
aws ec2 delete-subnet --subnet-id $TEST_SUBNET_ID
```

### 4D - Xoá VPC

```bash
aws ec2 delete-vpc --vpc-id $TEST_VPC_ID
```

Nếu chạy thứ tự sai (ví dụ xoá VPC trước xoá Subnet) → AWS trả lỗi:

```
An error occurred (DependencyViolation) when calling the DeleteVpc operation: 
The vpc 'vpc-0abc123def456' has dependencies and cannot be deleted.
```

**Đây chính là điểm học quan trọng nhất:** Dependency graph là **thứ Terraform tự động hoá ở Lab 4**. CLI buộc bạn tự làm tay, giúp hiểu rõ tại sao cần Terraform để quản lý dependency.

---

## Lessons Learned

1. **Console = CLI = Terraform** — tất cả đều gọi cùng AWS API, khác biệt chỉ là abstraction level:
   - Console: cao nhất, tự lưu context, tự quản lý dependency
   - CLI: trung bình, bạn quản lý context + dependency
   - Terraform: thấp nhất, code khai báo, Terraform compute dependency graph

2. **API Call Sequence** — từ CLI, bạn thấy rõ:
   - CreateVpc → CreateSubnet → CreateRouteTable → AssociateRouteTable (5 API gọi)
   - DeleteVpc thất bại nếu còn Subnet (dependency violation)
   - DisassociateRouteTable → DeleteRouteTable → DeleteSubnet → DeleteVpc (phải ngược lại)

3. **Context Management** — CLI không tự nhớ context, bạn phải `export` variable mỗi lần lấy ID:
   - Đây là lý do tại sao Terraform cần `terraform state` — để lưu resource ID và dependency
   - Console tự lưu session context → bạn không cảm nhận ra

4. **Query Output** — JSON output từ CLI dễ dàng parse với `--query` (JMESPath):
   - `--query "RouteTables[0].Routes"` extract chỉ field `Routes` từ array response
   - Giúp automation script CLI dễ dàng

5. **Safety Net của Console** — Console không cho xoá VPC khi còn resource bên trong. CLI không — nếu bạn quên disassociate, AWS báo lỗi. Cách CLI dạy bạn cẩn thận hơn.

---

## Next Step

Sau hoàn thành Lab 3B, bạn sẽ thấy:

* **Lab 4 (Terraform)** sẽ dùng HCL để khai báo cùng resources — Terraform tự tính thứ tự tạo từ dependency graph (`vpc_id` trong subnet depends on vpc)
* Lệnh `terraform destroy` tự đảo ngược dependency, không cần bạn tạm thời 4 lệnh riêng
* Terraform state file giữ track mọi resource ID — giống như "context" Console, nhưng persistent trên disk

---

## Troubleshooting

**Lỗi: `You are not authorized to perform this operation`**
- Kiểm tra quyền IAM (cần `ec2:CreateVpc`, `ec2:CreateSubnet`, ...)
- Chạy `aws sts get-caller-identity` verify đang dùng đúng account/user

**Lỗi: `An error occurred (DependencyViolation) when calling the DeleteVpc operation`**
- Bạn đã xoá VPC khi còn Subnet bên trong
- Xoá lại từ đầu: xoá Subnet trước, rồi VPC

**Lỗi: `The subnets in the route table are not empty`** (không phổ biến, nhưng có khi gặp)
- Chắc chắn disassociate route table trước khi xoá
- Query lại Association ID: `aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID`

**Mất biến `$TEST_VPC_ID` (terminal mới hoặc session hết)?**
- Chạy lại `export` hoặc `$env:` để set lại biến từ giá trị bạn lưu
- Hoặc dùng `aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.20.0.0/16"` để query VPC mới tạo

---

## Estimated Time

* Setup + Step 0-1: 5 phút
* Step 2-3: 10 phút
* Step 4 cleanup: 5 phút
* **Total: ~20 phút**

---

## Chúc bạn thành công! 🎯

Sau Lab 3B, hãy nhảy vào Lab 4 để thấy Terraform hoá các resource này.
