# Lab 05 - Terraform ECS Platform

## Mục tiêu

Terraform-hoá đúng kiến trúc ECS + ALB + RDS + S3 của Lab 2, nhưng lần này đặt **đúng vào Custom VPC 3-tier** đã xây ở Lab 3A/Lab 4 — không còn `assign_public_ip = true`, không còn default VPC. Đây cũng là lab đầu tiên **tách rõ Task Execution Role và Task Role** thành 2 IAM Role riêng biệt.

**RDS + S3 được tạo bởi Lab 5**, không phải Lab 4. Lab 4 chỉ cung cấp network layer (VPC, Subnet, Security Group); Lab 5 tạo toàn bộ app stack (RDS, S3, ECS, ALB, IAM Role).

Sau lab này cần hiểu được:

* ECS Service đặt trong Private App Subnet, không có Public IP — traffic vào chỉ qua ALB
* Task Execution Role (hạ tầng ECS: pull image, ghi log) khác Task Role (quyền của application: gọi S3, RDS)
* ALB nằm Public Subnet, target type `ip` cho Fargate (giữ nguyên từ Lab 2)
* RDS PostgreSQL đặt trong Private Data Subnet, accessible qua app stack chỉ qua Security Group inbound rule
* S3 bucket được tạo với encryption, versioning, public access blocked (best practice)
* Terraform inputs từ Lab 4 (VPC ID, Subnet IDs, Security Group IDs), không tạo network resources

## ⚠️ Prerequisite — BẮT BUỘC đọc trước khi chạy

* **Lab 3A + 3B đã hoàn thành** (Console + CLI, hiểu rõ VPC/Subnet/Route Table/NAT)
* **Lab 4 đã `terraform apply` thành công** — Lab 5 tiêu thụ output của Lab 4 (VPC ID, Subnet IDs, Security Group IDs)

Required outputs từ Lab 4 (chạy `terraform output` trong `lab-04-terraform-platform-foundation/terraform/`):

```
vpc_id
public_subnet_ids
private_app_subnet_ids
private_data_subnet_ids
alb_security_group_id
ecs_security_group_id
rds_security_group_id
```

Copy các giá trị này vào `terraform.tfvars` của Lab 5 (xem `terraform.tfvars.example`). Lab 4 và Lab 5 đều lưu state trên S3 với key độc lập, nhưng Lab 5 vẫn copy output thủ công để dependency dễ quan sát khi học. Có thể đổi sang `data "terraform_remote_state"` sau khi đã hiểu trade-off coupling và state access.

> **Note:** Lab 5 tự tạo RDS instance + S3 bucket — không cần từ ngoài. Chỉ cần network layer từ Lab 4.

## Architecture

```text
                              Internet
                                  |
                                  v
                 +----------------------------------+
                 |          Public Subnet            |    <- từ Lab 4
                 |   ALB (csnp-platform-alb)          |
                 +----------------------------------+
                                  |
                    (Target Group, target_type=ip)
                                  v
                 +----------------------------------+
                 |       Private App Subnet          |    <- từ Lab 4
                 |   ECS Fargate Service              |
                 |   desired_count = 2 (2 AZ)         |
                 |   assign_public_ip = false         |
                 +----------------------------------+
                                  |
                          (DB_HOST env var)
                                  v
                 +----------------------------------+
                 |       Private Data Subnet         |    <- RDS (cần làm ở phần mở rộng Lab 4)
                 +----------------------------------+
```

## So sánh với Lab 2

| | Lab 2 | Lab 5 |
| --- | --- | --- |
| VPC | Default VPC | Custom VPC (từ Lab 4) |
| ECS Subnet | Default Subnet, public | Private App Subnet |
| `assign_public_ip` | `true` | `false` |
| IAM Role | Chỉ Task Execution Role | Task Execution Role + Task Role riêng |
| Task Role S3 access | (chưa có, app không gọi được S3 từ Fargate) | Có, scoped đúng 1 bucket + 2 action |
| `DB_PASSWORD` | Thiếu hẳn trong Task Definition | Có, nhưng plain env var — known gap, xem dưới |

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| ECR | `csnp-platform-wallet-api`, scan on push |
| ECS Cluster + Service + Task Definition | Fargate, 2 task, Private App Subnet |
| ALB + Target Group + Listener | Public Subnet, port 80, health check `/health` |
| **RDS PostgreSQL** | **Private Data Subnet, accessible qua ECS Security Group** |
| **S3 Bucket** | **Encrypted, versioning enabled, public access blocked** |
| IAM Role | Task Execution Role (ECS infra) + Task Role (app permissions) riêng biệt |
| CloudWatch Log Group | `/ecs/csnp-platform-wallet-api`, retention 14 ngày |

## Known Gaps (cố ý, không phải thiếu sót) + tạo RDS + S3" của lab này.
* **Không có HTTPS/ACM listener** — chỉ HTTP port 80. TLS termination là concern riêng (cert, Route 53), ngoài scope.
* **Container Insights disabled** — bật ở Lab 6 (Observability).
* **RDS: No automated backup to S3, no encryption key alias** — backup rotation là Lab 6/7 (DR topic), encryption key alias cleanup là operational task, không phải IaC scope của lab nàyecrets Manager. Đây là quyết định đã thống nhất từ trước — Secrets Manager (kèm KMS, rotation) để dành Lab 6/7, tránh loãng trọng tâm "đặt ECS đúng vào Custom VPC" của lab này.
* **Không có HTTPS/ACM listener** — chỉ HTTP port 80. TLS termination là concern riêng (cert, Route 53), ngoài scope.
* **Container Insights disabled** — bật ở Lab 6 (Observability).
* **1 NAT Gateway** (kế thừa từ Lab 4) — nếu AZ chứa NAT down, ECS task ở AZ còn lại vẫn chạy được (không cần internet để serve traffic qua ALB), nhưng sẽ không pull được image mới nếu cần restart task lúc đó.

## Estimated Cost

| Resource | Chi phí ước tính |
| -------- | ----------------- |
| ALB | ~$16/tháng + LCU |
| Fargate (2 task, 0.25 vCPU/0.5GB) | ~$18-20/tháng nếu chạy 24/7 |
| ECR | Free tier 500MB, sau đó theo dung lượng |
| CloudWatch Logs | Free tier 5GB, sau đó theo dung lượng |

## Region

`us-east-1`

## Cleanup

```bash
terraform destroy
```

Không ảnh hưởng tới VPC của Lab 4 — Lab 5 chỉ tạo ECR/ECS/ALB/IAM Role, không tạo network resource nào.

## Lessons Learned

* Tách Task Execution Role và Task Role ngay từ đầu giúp tránh việc Task Role "mượn" quyền của Execution Role hoặc ngược lại — một lỗi cấu hình ECS rất phổ biến khi mới học.
* Network là input, không phải resource của lab này — cách tổ chức này (Terraform module/lab chỉ tạo đúng layer của mình, nhận layer dưới qua variable) là chuẩn bị tự nhiên cho việc tách module thật sau này.
* `assign_public_ip = false` không tự động hoạt động nếu Security Group hoặc Route Table của Private App Subnet sai — đây là lý do Lab 3/Lab 4 phải làm đúng trước, không thể bỏ qua.
* Chi tiết Q&A phỏng vấn xem [`docs/lab-05-interview-notes.md`](./docs/lab-05-interview-notes.md). Hands-on checklist xem [`docs/lab-05-hands-on.md`](./docs/lab-05-hands-on.md).
Bây giờ đã Complete (không phải skeleton nữa).** RDS + S3 đã thêm vào, variables đã update, ecs.tf đã dùng data source từ rds.tf + s3.tf. Sẵn sàng apply sau khi hoàn thành Lab 4 và copy `terraform.tfvars`
## Trạng thái

**Skeleton — chưa apply.** Viết sau khi hoàn thành thiết kế Lab 3/Lab 4 (theo roadmap), chờ anh thực hành Lab 3/Lab 4 thật trước khi quay lại điền `terraform.tfvars` và apply lab này.
