# Lab 03 - Custom VPC Networking

## Mục tiêu

Generation 1 (Lab 1, Lab 2) chạy trên **default VPC** — đủ để học EC2/RDS/S3/ECS/ALB ở mức resource riêng lẻ, nhưng không phản ánh đúng cách một fintech platform thật nên đặt network. Lab này xây **custom VPC 3-tier**, là nền tảng để Lab 4 viết lại Lab 1 bằng Terraform đúng chuẩn — không phải hack thêm VPC vào Terraform cũ.

Sau lab này cần hiểu được:

* Custom VPC, Subnet theo tier (public / private-app / private-data)
* Internet Gateway vs NAT Gateway — khi nào cần cái nào
* Route Table theo tier, vì sao Data tier không cần route ra internet
* Security Group chain: Internet → ALB SG → ECS SG → RDS SG
* Multi-AZ làm nền cho High Availability (RDS subnet group, ECS service sau này)

**Lab 1 và Lab 2 không bị động tới** — coi như "Generation 1", đóng băng nguyên trạng trên default VPC.

## Prerequisites

* AWS Account, credit còn khả dụng
* AWS Region: **us-east-1**
* Terraform >= 1.5.0
* Một EC2 key pair đã có sẵn (dùng tạm cho test EC2, xoá key pair sau khi xong nếu không cần nữa)

## Architecture

Lưu ý: sơ đồ dưới đây mô tả **traffic flow logical** (luồng request đi qua các tier theo nghiệp vụ, qua Security Group). Đây **không phải** route table thật giữa các subnet — mỗi tier có route table riêng, độc lập, xem chi tiết ở bảng Route Table bên dưới sơ đồ.

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

Route table thật của từng tier (đây là network layer, tách biệt với traffic flow ở trên):

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
| NAT Gateway | 1 cái, đặt ở Public Subnet AZ-a, cho Private App ra internet (apt update, pull image...) |
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

* [ ] Terminate `network-test-ec2` ngay sau khi verify xong (không cần giữ)
* [ ] Nếu nghỉ dài hạn: xoá NAT Gateway trước (tốn tiền theo giờ), giữ lại VPC/Subnet/Route Table/SG (free)
* [ ] `terraform destroy` nếu muốn dẹp toàn bộ — nhưng nếu định làm Lab 4 ngay tiếp theo, **giữ lại VPC này**, Lab 4 sẽ build trên cùng VPC
* [ ] Kiểm tra EIP không còn ở trạng thái unattached sau destroy

## Verification Checklist

Xem chi tiết lệnh ở [`docs/lab-03-verification.md`](./docs/lab-03-verification.md). Tóm tắt:

* [ ] SSH vào `network-test-ec2` qua Public IP — thành công
* [ ] Từ `network-test-ec2`, `curl` ra internet — thành công (đi qua IGW)
* [ ] Từ một instance trong Private App Subnet, `curl`/`apt update` ra internet — thành công (đi qua NAT, không có Public IP)
* [ ] Private Data Subnet — route table xác nhận KHÔNG có route `0.0.0.0/0`
* [ ] RDS (khi tạo ở Lab 4) — xác nhận `publicly_accessible = false` và chỉ SG của ECS mới gọi được port 5432

## Lessons Learned

* Data tier (RDS) không cần route ra internet để hoạt động — managed service connect qua endpoint nội bộ, không cần gọi ra ngoài. Tách hẳn route table cho tier này là cách rõ ràng nhất để chứng minh điều đó bằng hạ tầng, không phải chỉ bằng Security Group.
* 1 NAT Gateway là lựa chọn hợp lý cho lab/dev, nhưng là Single Point of Failure theo AZ — cần nhớ đây là trade-off có ý thức, không phải thiếu hiểu biết.
* Route Table Association là thứ hay bị quên — tạo Route Table xong mà không associate với Subnet thì Subnet vẫn dùng Main Route Table của VPC (thường chỉ có route local), dễ gây nhầm "tại sao subnet này không ra được internet".
* Chi tiết đầy đủ + Q&A phỏng vấn xem [`docs/lab-03-interview-notes.md`](./docs/lab-03-interview-notes.md).

## Trạng thái

Viết bằng Terraform ngay từ đầu (không làm tay qua Console trước) — khác Lab 1/Lab 2. Lý do: VPC networking có nhiều resource phụ thuộc nhau (subnet → route table → association → NAT → EIP), làm tay qua Console dễ rối thứ tự hơn so với EC2/RDS/S3 đơn lẻ. Điền `terraform.tfvars` (copy từ `.example`), xác nhận `my_ip_cidr` và `key_pair_name` trước khi `terraform apply`.
