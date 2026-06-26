# Lab 03A - Custom VPC Networking (Console)

## Mục tiêu

Generation 1 (Lab 1, Lab 2) chạy trên **default VPC** — đủ để học EC2/RDS/S3/ECS/ALB ở mức resource riêng lẻ, nhưng không phản ánh đúng cách một fintech platform thật nên đặt network. Lab 3A xây **custom VPC 3-tier bằng AWS Console**, làm tay từng bước — đúng triết lý học `UI → CLI → Terraform` đã dùng ở Lab 1 và Lab 2. Phần CLI để dành cho **Lab 3B (VPC Networking CLI)**, phần Terraform để dành cho **Lab 4 (Platform Foundation)**, build trên VPC mới, không tái sử dụng VPC làm tay ở đây.

Sau lab này cần hiểu được:

* Custom VPC, Subnet theo tier (public / private-app / private-data)
* Internet Gateway vs NAT Gateway — khi nào cần cái nào, và dependency giữa chúng (EIP → NAT → Route Table)
* Route Table theo tier, vì sao Data tier không cần route ra internet
* Route Table Association — bước hay bị quên, hiểu rõ vì đã tự tay làm
* Security Group chain: Internet → ALB SG → ECS SG → RDS SG
* Multi-AZ làm nền cho High Availability (RDS subnet group, ECS service sau này)
* Console và CLI gọi cùng API nào — chuẩn bị trực giác cho Terraform ở Lab 4

**Lab 1 và Lab 2 không bị động tới** — coi như "Generation 1", đóng băng nguyên trạng trên default VPC.

## Nội dung Lab 3A

| Phần | Nội dung | File |
| --- | --- | --- |
| Hands-on | Làm tay qua Console — full VPC 3-tier, NAT, Route Table, SG, verify | [`docs/lab-03a-hands-on.md`](./docs/lab-03a-hands-on.md) |
| Verification | Checklist kiểm tra network hoạt động đúng | [`docs/lab-03-verification.md`](./docs/lab-03-verification.md) |
| Interview Notes | Q&A phỏng vấn, keyword theo từng concept | [`docs/lab-03-interview-notes.md`](./docs/lab-03-interview-notes.md) |

**Liên quan:**
* Lab 3B (AWS CLI) — thư mục riêng: [`../lab-03b-vpc-networking-cli/`](../lab-03b-vpc-networking-cli/)
* Lab 4 (Terraform) — thư mục riêng: [`../lab-04-terraform-platform-foundation/`](../lab-04-terraform-platform-foundation/)

## Prerequisites

* AWS Account, credit còn khả dụng
* AWS Region: **us-east-1**
* AWS CLI đã configure (cho phần 3B)
* Một EC2 key pair đã có sẵn (dùng tạm cho test EC2)

## Architecture

Sơ đồ dưới đây mô tả **traffic flow logical** (luồng request đi qua các tier theo nghiệp vụ, qua Security Group) — **không phải** route table thật giữa các subnet. Mỗi tier có route table riêng, độc lập, xem bảng Route Table bên dưới.

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
                 |                                    |
                 |   - NAT Gateway (in 1a only)       |
                 |   - network-test-ec2 (temporary)   |
                 |   - ALB sẽ vào đây ở Lab 4+         |
                 +----------------------------------+
                                  |
                    (traffic logic: ALB -> ECS SG)
                                  v
                 +----------------------------------+
                 |       Private App Subnet          |
                 |   10.10.11.0/24 (us-east-1a)      |
                 |   10.10.12.0/24 (us-east-1b)      |
                 |   - ECS tasks sẽ vào đây ở Lab 4+   |
                 +----------------------------------+
                                  |
                    (traffic logic: ECS -> RDS SG)
                                  v
                 +----------------------------------+
                 |       Private Data Subnet         |
                 |   10.10.21.0/24 (us-east-1a)      |
                 |   10.10.22.0/24 (us-east-1b)      |
                 |   - RDS sẽ vào đây ở Lab 4+         |
                 +----------------------------------+
```

Route table thật của từng tier (network layer, tách biệt với traffic flow ở trên):

| Tier | Default route (`0.0.0.0/0`) | Ghi chú |
| --- | --- | --- |
| Public | → Internet Gateway | 2 chiều, có Public IP |
| Private App | → NAT Gateway | 1 chiều ra ngoài, không có Public IP |
| Private Data | **Không có** | chỉ có route `local` (10.10.0.0/16), không ra internet được dù qua NAT hay IGW |

Security Group chain:

```text
Internet → [ALB SG: port 80 from 0.0.0.0/0]
              ↓
         [ECS SG: port 5000 from ALB SG only]
              ↓
         [RDS SG: port 5432 from ECS SG only]
```

## CIDR Plan

| Tier | AZ us-east-1a | AZ us-east-1b |
| --- | --- | --- |
| VPC | `10.10.0.0/16` | |
| Public | `10.10.1.0/24` | `10.10.2.0/24` |
| Private App | `10.10.11.0/24` | `10.10.12.0/24` |
| Private Data | `10.10.21.0/24` | `10.10.22.0/24` |

> **Phân biệt 2 CIDR dùng trong Lab 3:**
> * `10.10.0.0/16` — **Source of truth**, VPC chính làm tay ở Lab 3A, đã verify, giữ nguyên để Lab 4 tham khảo/so sánh.
> * `10.20.0.0/16` — **CLI Learning Sandbox**, dùng riêng ở Lab 3B, throwaway, tạo và xoá tự do để học dependency mà không sợ phá VPC chính.

## NAT Gateway Trade-off

Lab dùng **1 NAT Gateway** (đặt ở Public Subnet AZ-a), cả 2 Private App subnet đều route qua nó.

* Chi phí thấp hơn (~$32/tháng so với ~$64/tháng cho 2 NAT)
* Trade-off: NAT là Single Point of Failure — nếu AZ-a down, Private App ở AZ-b mất internet
* Production nên dùng **1 NAT Gateway / AZ** để giữ đúng tinh thần Multi-AZ

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| VPC | `csnp-platform-vpc`, CIDR `10.10.0.0/16` |
| Internet Gateway | Cho Public Subnet ra internet |
| NAT Gateway | 1 cái, đặt ở Public Subnet AZ-a, cho Private App ra internet |
| Route Tables | Public RT (→ IGW), Private App RT x2 theo AZ (→ NAT), Private Data RT (local only) |
| Security Groups | ALB SG, ECS SG, RDS SG, test EC2 SG |
| EC2 (test) | `network-test-ec2`, t3.micro, tạm thời, chỉ để verify network |

## Estimated Cost

| Resource | Chi phí ước tính |
| -------- | ----------------- |
| NAT Gateway | ~$32/tháng + data processing — **chạy theo giờ kể cả không traffic, ưu tiên xoá sau khi xong lab nếu nghỉ dài** |
| EIP (gắn vào NAT) | Free khi đang attach, tốn tiền nếu để rảnh (unattached) |
| EC2 t3.micro (test) | Free Tier 750h/tháng |
| VPC, Subnet, Route Table, Security Group, IGW | Free |

## Region

`us-east-1`

## Cleanup

* [ ] Terminate `network-test-ec2` ngay sau khi verify xong
* [ ] **Xoá NAT Gateway trước tiên** (tốn tiền theo giờ) nếu không định làm Lab 3B/Lab 4 ngay
* [ ] Release Elastic IP sau khi NAT đã xoá
* [ ] Nếu định làm Lab 3B hoặc Lab 4 tiếp ngay: **giữ lại VPC này** — Lab 3B thực hành CLI trên VPC test riêng (không đụng VPC chính), Lab 4 build Terraform trên VPC hoàn toàn mới (không tái sử dụng VPC làm tay)

## Lessons Learned

* Data tier (RDS) không cần route ra internet để hoạt động — managed service connect qua endpoint nội bộ. Tách hẳn route table cho tier này là cách rõ ràng nhất để chứng minh bằng hạ tầng, không chỉ bằng Security Group.
* 1 NAT Gateway là lựa chọn hợp lý cho lab/dev, nhưng là Single Point of Failure theo AZ — trade-off có ý thức, không phải thiếu hiểu biết.
* Route Table Association là thứ hay bị quên khi làm tay — tạo Route Table xong mà không associate với Subnet thì Subnet vẫn dùng Main Route Table (chỉ có route local), dễ gây nhầm "tại sao subnet này không ra được internet".
* Console và CLI gọi cùng API AWS — khác biệt là Console tự lưu context và tự chặn xoá khi còn dependency.
* Chi tiết đầy đủ + Q&A phỏng vấn xem [`docs/lab-03-interview-notes.md`](./docs/lab-03-interview-notes.md).

## Trạng thái

Làm tay qua Console trước ([`lab-03a-hands-on.md`](./docs/lab-03a-hands-on.md)), sau đó một phần qua CLI ([`lab-03b-cli-walkthrough.md`](./docs/lab-03b-cli-walkthrough.md)) trên VPC test riêng để không ảnh hưởng VPC chính. Terraform hoá toàn bộ network này — trên VPC mới, không tái sử dụng — là phạm vi của `lab-04-terraform-platform-foundation/`.
