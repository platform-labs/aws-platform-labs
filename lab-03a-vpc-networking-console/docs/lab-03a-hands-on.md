# AWS Hands-on Lab #3A

## Deliberate practice loop

1. **Mental model:** tự chia CIDR thành public/private-app/private-data và vẽ route target trước khi bấm Console.
2. **Console discovery:** lab này dùng Console làm implementation chính; không chọn wizard “VPC and more”.
3. **Implementation:** tạo từng VPC, IGW, subnet, NAT, route table, association và SG theo dependency order.
4. **CLI verification:** dùng `describe-vpcs`, `describe-subnets`, `describe-route-tables` và `describe-security-groups`.
5. **Failure drill:** bỏ association của một subnet hoặc route mặc định, dự đoán connectivity rồi khôi phục.
6. **Rebuild without guide:** dựng lại toàn bộ VPC 3-tier chỉ từ CIDR table.
7. **Cleanup/cost audit:** NAT Gateway và EIP là ưu tiên; không xóa nhầm VPC `10.10.0.0/16` nếu còn dùng làm reference.
8. **Interview recap:** giải thích public subnet được quyết định bởi route/public IP, không phải tên subnet.

Quy tắc luyện nhiều vòng: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Custom VPC Networking — làm tay qua Console

### Mục tiêu

Sau lab này cần hiểu được:

* VPC, Subnet, Route Table — và tại sao tách theo tier
* Internet Gateway vs NAT Gateway — dependency và thứ tự tạo
* Route Table Association — bước rất dễ bị quên
* Security Group chain: ALB → ECS → RDS

Lab 1 và Lab 2 dùng Default VPC. Lab này xây Custom VPC 3-tier **bằng tay qua Console trước**, để tận mắt thấy từng resource và dependency giữa chúng — đúng triết lý học UI → CLI → Terraform đã áp dụng từ Lab 1/Lab 2. Phần CLI ở Lab 3B, phần Terraform ở Lab 4.

> **CIDR trong file này: `10.10.0.0/16` — Source of Truth.** Đây là VPC chính, sẽ verify kỹ và giữ nguyên trạng để Lab 4 tham khảo/so sánh. Lab 3B dùng CIDR khác (`10.20.0.0/16`, throwaway sandbox), không đụng tới VPC này.

---

# Architecture

```text
                              Internet
                                  |
                                  v
                          Internet Gateway
                                  |
                                  v
                 +----------------------------------+
                 |          Public Subnet            |
                 |   10.10.1.0/24 (us-east-1a)       |
                 |   10.10.2.0/24 (us-east-1b)       |
                 |   - NAT Gateway (in 1a only)       |
                 +----------------------------------+
                                  |
                 +----------------------------------+
                 |       Private App Subnet          |
                 |   10.10.11.0/24 (us-east-1a)      |
                 |   10.10.12.0/24 (us-east-1b)      |
                 +----------------------------------+
                                  |
                 +----------------------------------+
                 |       Private Data Subnet         |
                 |   10.10.21.0/24 (us-east-1a)      |
                 |   10.10.22.0/24 (us-east-1b)      |
                 +----------------------------------+
```

CIDR Plan:

| Tier | AZ us-east-1a | AZ us-east-1b |
| --- | --- | --- |
| VPC | `10.10.0.0/16` | |
| Public | `10.10.1.0/24` | `10.10.2.0/24` |
| Private App | `10.10.11.0/24` | `10.10.12.0/24` |
| Private Data | `10.10.21.0/24` | `10.10.22.0/24` |

---

# Prerequisites

* AWS Account, credit còn khả dụng
* AWS Region: **us-east-1**
* Đã ghi nhớ IP public của mình: `curl -s https://checkip.amazonaws.com`

---

# Cost Warning

| Resource | Chi phí ước tính |
| -------- | ---------------- |
| NAT Gateway | ~$32/tháng + data processing — **tốn theo giờ kể cả không traffic, ưu tiên xoá sau khi xong lab** |
| EIP gắn NAT | Free khi đang attach |
| EC2 t3.micro (test) | Free Tier 750h/tháng |
| VPC, Subnet, Route Table, IGW, SG | Free |

> Tạo NAT Gateway xong rồi quên xoá là lỗi tốn tiền phổ biến nhất ở lab này. Set lại reminder cleanup ngay sau khi verify xong.

---

# Step 1 - Tạo VPC

## Console: VPC → Your VPCs → Create VPC

* Resources to create: **VPC only**
* Name tag: `csnp-platform-vpc`
* IPv4 CIDR: `10.10.0.0/16`
* Tenancy: Default

## Tại sao không chọn "VPC and more"?

Console có tùy chọn tự động tạo cả Subnet/Route Table/NAT trong 1 click. Lab này **không dùng tùy chọn đó** — mục tiêu là tự tay tạo từng resource để hiểu dependency, không phải có VPC nhanh nhất.

---

# Step 2 - Tạo Internet Gateway và attach vào VPC

## Console: VPC → Internet Gateways → Create internet gateway

* Name tag: `csnp-platform-igw`
* Create

Sau khi tạo, IGW ở trạng thái `Detached`. Phải gắn thủ công:

## Attach to VPC

* Chọn IGW vừa tạo → Actions → **Attach to VPC**
* Chọn `csnp-platform-vpc`

## Tại sao phải attach riêng?

IGW là resource độc lập với VPC — 1 IGW chỉ attach được vào 1 VPC tại một thời điểm. Việc tách tạo và attach thành 2 bước giúp thấy rõ IGW không "thuộc về" VPC ngay khi tạo, mà là một quan hệ gắn vào sau.

---

# Step 3 - Tạo 6 Subnet (2 AZ x 3 tier)

## Console: VPC → Subnets → Create subnet

Chọn VPC `csnp-platform-vpc`, sau đó tạo lần lượt 6 subnet (Console cho phép add nhiều subnet trong 1 lần tạo — dùng "Add new subnet"):

| Subnet name | AZ | CIDR |
| --- | --- | --- |
| `csnp-platform-public-us-east-1a` | us-east-1a | `10.10.1.0/24` |
| `csnp-platform-public-us-east-1b` | us-east-1b | `10.10.2.0/24` |
| `csnp-platform-private-app-us-east-1a` | us-east-1a | `10.10.11.0/24` |
| `csnp-platform-private-app-us-east-1b` | us-east-1b | `10.10.12.0/24` |
| `csnp-platform-private-data-us-east-1a` | us-east-1a | `10.10.21.0/24` |
| `csnp-platform-private-data-us-east-1b` | us-east-1b | `10.10.22.0/24` |

## Bật Auto-assign Public IP cho 2 Public Subnet

Sau khi tạo xong, vào từng Public Subnet:

* Actions → **Edit subnet settings**
* Tick **Enable auto-assign public IPv4 address**

Private App và Private Data **không** tick mục này — đây chính là điểm khác biệt quyết định một subnet là "public" hay "private" theo định nghĩa thực dụng (không phải tên gọi, mà là việc instance trong đó có tự động nhận Public IP hay không).

---

# Step 4 - Tạo Elastic IP và NAT Gateway

## Tạo Elastic IP trước

Console: VPC → Elastic IPs → **Allocate Elastic IP address**

* Network Border Group: mặc định
* Allocate

## Tạo NAT Gateway

Console: VPC → NAT Gateways → **Create NAT gateway**

* Name: `csnp-platform-nat-us-east-1a`
* Availability mode: Zonal
* Subnet: `csnp-platform-public-us-east-1a` (NAT phải nằm trong Public Subnet)
* Connectivity type: Public
* Elastic IP allocation ID: chọn EIP vừa tạo ở trên

Tạo xong, NAT Gateway ở trạng thái `Pending` — **chờ 3-5 phút** cho tới khi chuyển `Available`. Không thể tạo Route Table trỏ vào NAT khi nó còn Pending.

## Tại sao chỉ 1 NAT Gateway?

Lab này dùng 1 NAT (đặt ở AZ us-east-1a) cho cả 2 Private App Subnet, để tiết kiệm chi phí (~$32/tháng thay vì ~$64/tháng cho 2 NAT). Trade-off: nếu AZ us-east-1a down, Private App ở AZ us-east-1b cũng mất internet — Single Point of Failure có chủ đích, ghi rõ để không nhầm là thiếu hiểu biết. Production nên có 1 NAT/AZ.

---

# Step 5 - Tạo Route Tables

Cần 4 Route Table: 1 Public (chung 2 AZ), 2 Private App (riêng từng AZ), 1 Private Data (chung, local only).

## 5.1 Public Route Table

Console: VPC → Route Tables → **Create route table**

* Name: `csnp-platform-public-rt`
* VPC: `csnp-platform-vpc`

Sau khi tạo, vào tab **Routes** → Edit routes → Add route:

* Destination: `0.0.0.0/0`
* Target: **Internet Gateway** → chọn `csnp-platform-igw`

## 5.2 Private App Route Table (us-east-1a)

* Name: `csnp-platform-private-app-rt-us-east-1a`
* VPC: `csnp-platform-vpc`

Routes → Add route:

* Destination: `0.0.0.0/0`
* Target: **NAT Gateway** → chọn `csnp-platform-nat-us-east-1a`

## 5.3 Private App Route Table (us-east-1b)

* Name: `csnp-platform-private-app-rt-us-east-1b`
* Routes giống y 5.2 — cùng trỏ về NAT Gateway duy nhất ở us-east-1a (vì lab chỉ có 1 NAT)

> Tại sao 2 Route Table riêng nếu route giống nhau? Vì nếu sau này thêm NAT Gateway thứ 2 ở us-east-1b (production setup), chỉ cần sửa route của Route Table `-us-east-1b` để trỏ NAT mới, không ảnh hưởng AZ-a. Tách sẵn route table theo AZ giúp việc nâng cấp lên 1-NAT/AZ không cần đổi cấu trúc, chỉ đổi target.

## 5.4 Private Data Route Table

* Name: `csnp-platform-private-data-rt`
* VPC: `csnp-platform-vpc`
* **Không thêm route nào cả** — giữ nguyên route `local` (10.10.0.0/16) tự động có sẵn

Đây là bước dễ bị "thêm thừa" nhất nếu làm theo quán tính — đừng thêm route `0.0.0.0/0` vào bảng này.

---

# Step 6 - Route Table Association (bước hay bị quên)

Tạo Route Table xong **không tự động áp dụng** cho Subnet nào. Phải associate thủ công.

Console: chọn từng Route Table → tab **Subnet associations** → **Edit subnet associations**

| Route Table | Associate với Subnet |
| --- | --- |
| `csnp-platform-public-rt` | `csnp-platform-public-us-east-1a`, `csnp-platform-public-us-east-1b` |
| `csnp-platform-private-app-rt-us-east-1a` | `csnp-platform-private-app-us-east-1a` |
| `csnp-platform-private-app-rt-us-east-1b` | `csnp-platform-private-app-us-east-1b` |
| `csnp-platform-private-data-rt` | `csnp-platform-private-data-us-east-1a`, `csnp-platform-private-data-us-east-1b` |

## Tại sao bước này quan trọng?

Nếu quên associate, Subnet vẫn dùng **Main Route Table** của VPC (chỉ có route `local`) — Subnet sẽ không ra được internet dù Route Table đúng đã tồn tại. Đây là lỗi rất hay gặp và dễ khiến debug sai hướng (nghĩ NAT/IGW sai, nhưng thực ra do thiếu association).

---

# Step 7 - Tạo Security Groups

Console: VPC → Security Groups → **Create security group**

## 7.1 ALB Security Group

* Name: `csnp-platform-alb-sg`
* Description: `Allow HTTP traffic from Internet to Application Load Balancer`
* VPC: `csnp-platform-vpc`
* Inbound rule: HTTP (80) từ Source `0.0.0.0/0`
* Outbound: giữ default (All traffic, `0.0.0.0/0`)

## 7.2 ECS Security Group

* Name: `csnp-platform-ecs-sg`
* Description: `Allow application traffic from ALB Security Group on port 5000`
* VPC: `csnp-platform-vpc`
* Inbound rule: Custom TCP, port `5000`, Source = **Security Group** `csnp-platform-alb-sg` (không phải CIDR)
* Outbound: giữ default

## 7.3 RDS Security Group

* Name: `csnp-platform-rds-sg`
* Description: `Allow PostgreSQL traffic from ECS Security Group on port 5432`
* VPC: `csnp-platform-vpc`
* Inbound rule: PostgreSQL (5432), Source = **Security Group** `csnp-platform-ecs-sg`
* Outbound: giữ default

## 7.4 Test EC2 Security Group

Security Group này dùng riêng cho EC2 test ở Step 8.

* Name: `csnp-platform-test-ec2-sg`
* Description: `Allow SSH access from administrator public IP`
* VPC: `csnp-platform-vpc`
* Inbound rule: SSH (22), Source = **My IP**
* Outbound: giữ default (All traffic, `0.0.0.0/0`)

## Tại sao chọn Source là Security Group, không phải CIDR?

Giống lý do ở Lab 1/Lab 2 — Security Group Reference không phụ thuộc IP cố định, đúng khi ECS task hoặc EC2 instance bị thay thế (IP đổi nhưng SG giữ nguyên).

---

# Step 8 - Tạo EC2 test để verify

Console: EC2 → Launch instance

* Name: `network-test-ec2`
* AMI: Amazon Linux 2023
* Instance type: `t3.micro`
* Key pair: chọn key có sẵn (hoặc tạo mới, nhớ note Security warning như Lab 1)
* Network settings → Edit:
  * VPC: `csnp-platform-vpc`
  * Subnet: `csnp-platform-public-us-east-1a`
  * Auto-assign public IP: **Enable**
  * Security Group: chọn `csnp-platform-test-ec2-sg`

Launch.

---

# Step 9 - Verify

## 9.1 SSH vào EC2 qua Public IP

```bash
ssh-keygen -R EC2-PUBLIC-IP
ssh -i "C:\Users\Toan\.ssh\wallet-dev-key.pem" ec2-user@EC2-PUBLIC-IP
```

Kỳ vọng: connect thành công → xác nhận Public Subnet + IGW route + SG đúng.

## 9.2 Curl ra internet từ EC2 (Public Subnet)

```bash
curl -s https://checkip.amazonaws.com
sudo dnf update -y
```

Kỳ vọng: chạy được — IP trả về chính là Public IP của EC2.

## 9.3 Kiểm tra Route Table của Private App Subnet

Console: VPC → Subnets → chọn 1 Private App Subnet → tab **Route table**

Kỳ vọng: thấy route `0.0.0.0/0` → Target là NAT Gateway (không phải IGW).

## 9.4 Kiểm tra Route Table của Private Data Subnet

Console: VPC → Subnets → chọn 1 Private Data Subnet → tab **Route table**

Kỳ vọng: chỉ có 1 route — `10.10.0.0/16` → `local`. Không có route nào khác.

---

# Cleanup

* [ ] Terminate `network-test-ec2`
* [ ] **Xoá NAT Gateway trước tiên** (tốn tiền theo giờ) — nếu không định làm Lab 3B/Lab 4 ngay
* [ ] Release Elastic IP sau khi NAT Gateway đã xoá xong (EIP không gắn gì vẫn tốn tiền)
* [ ] Nếu định làm Lab 3B (CLI) hoặc Lab 4 (Terraform) ngay tiếp theo: **giữ lại toàn bộ VPC này**, không cần xoá — Lab 3B sẽ thực hành CLI trên chính VPC đã tạo, Lab 4 build Terraform riêng trên VPC mới (không tái sử dụng VPC làm tay này, theo nguyên tắc không mix Console resource với Terraform state)

---

# Lessons Learned

* NAT Gateway cần Elastic IP — đây là 2 resource tách biệt, không tự động đi kèm nhau như có thể nghĩ ban đầu.
* Route Table Association không tự động — quên bước này dẫn tới subnet "không hoạt động" dù mọi thứ khác đúng.
* Private Data Subnet không cần — và không nên có — route ra internet. RDS hoạt động hoàn toàn qua route `local` nội bộ VPC.
* Chi tiết Q&A phỏng vấn xem [`lab-03-interview-notes.md`](./lab-03-interview-notes.md). Phần CLI tiếp theo xem [`lab-03b-cli-walkthrough.md`](./lab-03b-cli-walkthrough.md).
