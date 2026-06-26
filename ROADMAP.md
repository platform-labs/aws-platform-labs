# AWS Platform Learning Roadmap (CSNP Edition) — Final

## Mục tiêu

Roadmap này nhằm:

* Pass AWS SAA
* Xây nền tảng AWS vững chắc
* Hiểu bản chất hạ tầng AWS
* Chuẩn bị đưa CSNP lên AWS production
* Phát triển theo hướng Senior Platform Engineer

---

# Triết lý học

```text
Console
↓
CLI
↓
Terraform
↓
Production Design
↓
Platform Engineering
```

Không nhảy Terraform quá sớm. Phải hiểu resource trước khi IaC hóa.

Từ Lab 4 trở đi, Console được dùng để discovery và quan sát resource do IaC tạo, không bắt buộc dựng thêm một stack thủ công giống hệt. Mọi lab dùng deliberate-practice loop: mental model → Console discovery → implementation → CLI verification → failure drill → rebuild không nhìn guide → cleanup/cost audit → interview recap. Xem `DELIBERATE_PRACTICE.md` và `PRACTICE_MATRIX.md`.

---

# PHASE 0 — COST GUARDRAIL

## Lab 0.5 — AWS Cost Guardrail

### Mục tiêu

Tránh bill bất ngờ khi bắt đầu dùng các dịch vụ có thể tốn tiền (RDS, NAT Gateway, Aurora, MSK...).

### Thực hành

* Tạo AWS Budget
* Cost Alert
* Email Notification

### Ngưỡng đề xuất

```text
Warning:  $5
Critical: $10
```

### Áp dụng đặc biệt cho

* Lab 1 (RDS)
* Lab 3A/3B (NAT Gateway)
* Lab 9 (Aurora)
* Lab 12A/12B (Amazon MQ / MSK Serverless)
* Lab 15 (CloudFront)

### Học được

* Cost Awareness
* Cost Control
* AWS Billing Basics

---

# PHASE 1 — FOUNDATION

## Lab 1 — EC2 + RDS + S3 + IAM + CloudWatch

### Mục tiêu

Làm quen các dịch vụ AWS cốt lõi.

### Nội dung

* EC2
* RDS PostgreSQL
* S3
* IAM Instance Role
* CloudWatch

### Thực hành

Deploy WalletMinimal:

```text
EC2
↓
RDS
↓
S3
```

### Học được

* Compute
* Database
* Object Storage
* IAM Role
* Security Group

---

## Lab 2 — Docker + ECR + ECS Fargate + ALB

### Mục tiêu

Container hóa ứng dụng.

### Nội dung

* Docker
* ECR
* ECS Fargate
* ALB
* Target Group
* ECS Service
* Task Definition

### Thực hành

Deploy WalletMinimal:

```text
ALB
 ↓
ECS
 ↓
RDS
```

### Học được

* Container
* Orchestration
* Load Balancing
* Self Healing
* Task Role vs Execution Role

---

# PHASE 2 — NETWORKING

## Lab 3A — Custom VPC Networking (Console)

### Source of Truth

CIDR:

```text
10.10.0.0/16
```

### Mục tiêu

Tự tay xây VPC bằng AWS Console.

### Nội dung

* VPC
* Internet Gateway
* NAT Gateway
* Elastic IP
* Route Tables
* Route Associations

### Subnets

Public:

```text
10.10.1.0/24
10.10.2.0/24
```

Private App:

```text
10.10.11.0/24
10.10.12.0/24
```

Private Data:

```text
10.10.21.0/24
10.10.22.0/24
```

### Học được

* Public vs Private
* Routing
* NAT vs IGW
* Trust Boundary

---

## Lab 3B — VPC Networking (CLI)

### Learning Sandbox

CIDR:

```text
10.20.0.0/16
```

### Mục tiêu

Hiểu AWS API phía sau Console.

### Nội dung

* create-vpc
* create-subnet
* create-route-table
* associate-route-table
* delete resources

### Học được

* Resource dependency
* Create order
* Destroy order

---

# PHASE 3 — INFRASTRUCTURE AS CODE

## Lab 4 — Terraform Platform Foundation (Network Only)

### Prerequisites

* Lab 3A
* Lab 3B

### Mục tiêu

Terraform hóa network layer (VPC 3-tier) — **scope đã chốt: chỉ network, không bao gồm EC2/RDS/S3/IAM/CloudWatch**. Các resource đó thuộc về app stack, được Terraform hoá trong Lab 5 (xem lý do ở mục Lab 5 bên dưới).

### Terraform Resources

* VPC
* Subnets (Public / Private App / Private Data)
* IGW
* NAT Gateway
* Route Tables
* Security Groups (ALB SG, ECS SG, RDS SG — định nghĩa sẵn, chưa có resource dùng RDS SG vì RDS thuộc Lab 5)

### Học được

* Terraform State
* Dependency Graph
* IaC

### Trạng thái

**Done.**

---

## Lab 5 — Terraform ECS Platform (= Terraform hoá Lab 2, đặt vào Custom VPC + RDS/S3/IAM)

### Mục tiêu

Lab 5 chính là **bản Terraform của Lab 2** (Dockerize → ECR → ECS Fargate → ALB), nhưng đặt đúng vào Custom VPC 3-tier (output từ Lab 4) thay vì default VPC, và tách rõ Task Execution Role / Task Role.

Vì Lab 5 đóng vai "Terraform hoá toàn bộ app stack" (không chỉ ECS), nên **RDS, S3, IAM Role cũng thuộc Lab 5** — không phải Lab 4. Lab 4 chỉ cung cấp network layer dùng chung (VPC/Subnet/SG); mọi resource phục vụ trực tiếp cho app (database, storage, app permissions) đi theo app stack ở Lab 5.

### Prerequisites

* Lab 4 (network only — `vpc_id`, `private_app_subnet_ids`, `private_data_subnet_ids`, `alb_security_group_id`, `ecs_security_group_id`, `rds_security_group_id`)

### Terraform Resources

ECS / ALB:

* ECR
* ECS Cluster
* ECS Service
* Task Definition
* ALB
* Target Group
* Listener

Database & Storage (chuyển từ Lab 4 sang đây):

* RDS PostgreSQL (Private Data Subnet, `aws_db_instance`)
* S3 Bucket

IAM:

* Execution Role
* Task Role (có quyền gọi S3, đúng vai trò application permission)

### Kiến trúc

```text
ALB
 ↓
ECS (Private App)
 ↓
RDS (Private Data) — tạo bởi chính Lab 5
```

### Học được

* Production ECS Architecture
* Terraform Modules
* ECS Deployment
* Vì sao network (Lab 4) và app stack (Lab 5) nên tách lab riêng — network ít đổi, app stack đổi liên tục theo service

### Trạng thái

Code đã viết (`rds.tf` mới thêm, `variables.tf`/`ecs.tf`/outputs đã update để dùng `aws_db_instance.wallet_db.address` thay vì `var.db_host` cứng). **Chưa `terraform apply`** — cần làm tiếp.

---

# PHASE 4 — OPERATIONS

## Lab 6 — Observability

### Nội dung

* CloudWatch Dashboard
* Metrics
* Logs
* Alarms
* Container Insights

### Security

* Secrets Manager
* KMS

### Học được

* Monitoring
* Alerting
* Secret Management

---

## Lab 7 — Auto Scaling & Resilience

### Nội dung

* ECS Auto Scaling
* CPU Scaling
* Memory Scaling
* Desired Count
* Min Count
* Max Count

### HA Concepts

* Multi-AZ
* Health Checks
* Self Healing

### Học được

* Resilience
* Scaling

---

## Lab 8 — CI/CD

### Nội dung

GitHub Actions:

* Build
* Test
* Docker Build
* Push ECR
* Deploy ECS

### Pipeline

```text
Git Push
 ↓
GitHub Actions
 ↓
ECR
 ↓
ECS
```

### Học được

* Continuous Delivery
* Deployment Automation

---

# PHASE 5 — ARCHITECTURE

## Lab 9 — Aurora PostgreSQL

### Nội dung

* Aurora PostgreSQL
* Read Replica
* Multi-AZ
* Failover

### So sánh

```text
RDS PostgreSQL
vs
Aurora PostgreSQL
```

### Học được

* Database HA
* Managed Database Scaling

---

## Lab 9.5 — ECS vs EKS Architecture Decision

### Output bắt buộc

ADR:

```text
ADR-XXXX-ECS-VS-EKS.md
```

### Nội dung

* ECS
* EKS
* Cost
* Operations
* Complexity
* Migration Strategy

### Case Study

CSNP:

```text
Why ECS today?
When EKS tomorrow?
```

### Học được

* Architecture Decision Records
* Trade-off Analysis

---

## Lab 10 — EKS

### Nội dung

* EKS Cluster
* Deployment
* Service
* Ingress
* HPA

### Mapping

```text
ECS Cluster  → K8s Cluster
ECS Service  → Deployment
Task         → Pod
ALB          → Ingress
```

### Học được

* Kubernetes trên AWS

---

# PHASE 6 — CSNP PRODUCTION SERVICES

## Lab 11 — ElastiCache Redis

### Nội dung

* Redis
* Cache
* Distributed Lock
* Session
* Rate Limiting

### Học được

* Caching Strategy

---

## Lab 12A — Amazon MQ (RabbitMQ)

### Priority

**Required**

### Nội dung

* Amazon MQ
* RabbitMQ
* MassTransit
* Retry
* DLQ

### Liên hệ CSNP

```text
Wallet
Payment
Ledger
Notification
```

### Học được

* Managed RabbitMQ

---

## Lab 12B — Amazon MSK Serverless

### Priority

**Optional**

### Nội dung

* Kafka
* MSK Serverless
* Event Streaming

### Liên hệ CSNP

```text
Compliance
Analytics
Shadow Stream
```

---

## Lab 13 — Route53 + ACM

### Nội dung

* DNS
* Route53
* ACM
* HTTPS

Ví dụ:

```text
api.csnp.xyz
```

### Học được

* Domain Management
* TLS

---

## Lab 14 — AWS WAF

### Priority

**Required**

### Nội dung

* OWASP Rules
* Rate Limiting
* Layer 7 Protection

### Liên hệ CSNP

```text
Fintech
Compliance
Public APIs
```

### Học được

* API Protection

---

# PHASE 7 — ADVANCED PLATFORM ENGINEERING

## Lab 15 — CloudFront

### Priority

**Để sau**

### Nội dung

* CDN
* Edge Caching

---

## Lab 16 — GitOps

### Nội dung

* ArgoCD
* GitOps
* EKS

### Học được

* Platform Delivery

---

## Lab 17 — External Secrets

### Nội dung

* Secrets Manager
* External Secrets Operator

### Học được

* Secret Automation

---

## Lab 18 — OpenTelemetry

### Nội dung

* OpenTelemetry
* AWS X-Ray
* Distributed Tracing

### Học được

* Observability Platform

---

## Lab 19 — Multi Account Strategy

### Priority

**Optional**

### Nội dung

* AWS Organizations
* Landing Zone

---

## Lab 20 — Disaster Recovery

### Nội dung

* Backup
* Restore
* Cross Region
* DR Strategy

---

# AWS SAA THEORY TRACK (No Lab — Học song song)

Không bắt buộc làm lab riêng, nhưng bắt buộc nắm vững cho kỳ thi SAA (theo khóa Stephane Maarek).

### Storage

* S3 Storage Classes
* S3 Lifecycle
* S3 Replication
* Glacier

### Data Transfer

* Snowball
* DataSync
* Storage Gateway

### File Services

* EFS
* FSx

### Networking Advanced

* VPC Peering
* Transit Gateway
* PrivateLink

### Hybrid

* Direct Connect
* VPN

### Enterprise

* AWS Organizations
* Control Tower

### Edge Cases

* Outposts
* Local Zones
* Wavelength

### Mapping gợi ý

```text
S3   → Lab 1 + Theory
VPC  → Lab 3A/3B + Theory
RDS  → Lab 1, Lab 9 + Theory
```

---

# MILESTONES

## AWS SAA + Platform Foundation

```text
Lab 0.5
Lab 1 → Lab 10
```

## CSNP Production Ready

```text
Lab 0.5
Lab 1, 2, 3A, 3B, 4, 5, 6, 7, 8, 9
Lab 11, 12A, 13, 14
```

(Không phụ thuộc EKS — theo kết luận ADR Lab 9.5)

## Senior Platform Engineer Track

```text
Lab 0.5
Lab 1 → Lab 20
```

Bao gồm EKS, GitOps, OpenTelemetry, DR.

---

# DEPENDENCY GRAPH (Requires / Produces)

Nguyên tắc:

* Mỗi lab khai báo rõ **Requires** (lab nào phải xong trước) và **Produces** (output gì cho lab sau dùng).
* Không lab nào được bắt đầu nếu chưa xong toàn bộ "Requires".
* Mọi lab có Terraform lưu state trên shared labs S3 backend với key riêng. Nếu lab sau cần resource từ lab trước (`vpc_id`, `subnet_ids`, `sg_ids`...), mặc định vẫn copy từ `terraform output` vào `terraform.tfvars` để dependency minh bạch; chỉ dùng `terraform_remote_state` khi lab ghi rõ.

| Lab | Requires | Produces |
| --- | --- | --- |
| Lab 0.5 — Cost Guardrail | None | Budget Alert đã set ($5/$10) |
| Lab 1 — EC2+RDS+S3+IAM+CloudWatch | Lab 0.5 | WalletMinimal chạy trên EC2 (default VPC), kinh nghiệm IAM Role/SG |
| Lab 2 — ECR+ECS Fargate+ALB | Lab 1 | Container image trên ECR, ECS service mẫu (default VPC) |
| Lab 3A — VPC Networking (Console) | Lab 2 | VPC 3-tier design đã verify bằng tay (`10.10.0.0/16`) |
| Lab 3B — VPC Networking (CLI) | Lab 3A | AWS CLI skill, hiểu resource dependency (sandbox `10.20.0.0/16`, throwaway) |
| Lab 4 — Terraform Platform Foundation (Network Only) | Lab 3A, Lab 3B | `vpc_id`, `public_subnet_ids`, `private_app_subnet_ids`, `private_data_subnet_ids`, `alb_security_group_id`, `ecs_security_group_id`, `rds_security_group_id` |
| Lab 5 — Terraform ECS Platform (= Terraform Lab 2 + RDS/S3/IAM) | Lab 4 | ECS service chạy trong Custom VPC, ALB DNS, Task Role tách Execution Role, **RDS endpoint (tự tạo, không phải từ Lab 4)**, S3 bucket |
| Lab 6 — Observability | Lab 5 | Dashboards, Alarms, Secrets Manager setup |
| Lab 7 — Auto Scaling & Resilience | Lab 6 | Scaling Policies, Health Check config |
| Lab 8 — CI/CD | Lab 5 | GitHub Actions pipeline (Build→ECR→ECS Deploy) |
| Lab 9 — Aurora PostgreSQL | Lab 8 | Aurora cluster, so sánh RDS vs Aurora |
| Lab 9.5 — ECS vs EKS ADR | Lab 9 | `ADR-XXXX-ECS-VS-EKS.md` |
| Lab 10 — EKS | Lab 9.5 | EKS cluster mapping với ECS concepts |
| Lab 11 — ElastiCache Redis | Lab 5 | Cache layer, distributed lock pattern |
| Lab 12A — Amazon MQ (Required) | Lab 11 | Managed RabbitMQ, retry/DLQ pattern |
| Lab 12B — MSK Serverless (Optional) | Lab 12A | Kafka event streaming demo |
| Lab 13 — Route53 + ACM | Lab 5 | `api.csnp.xyz` DNS + TLS |
| Lab 14 — WAF (Required) | Lab 13 | Layer 7 protection rules |
| Lab 15 — CloudFront (Để sau) | Lab 14 | CDN config |
| Lab 16 — GitOps | Lab 10 | ArgoCD trên EKS |
| Lab 17 — External Secrets | Lab 16 | Secrets Manager ↔ EKS integration |
| Lab 18 — OpenTelemetry | Lab 16 | Distributed tracing trên EKS |
| Lab 19 — Multi Account (Optional) | Lab 18 | AWS Organizations / Landing Zone |
| Lab 20 — Disaster Recovery | Lab 18 | Backup/Restore cross-region |

---

# TRẠNG THÁI HIỆN TẠI (cập nhật 2026-06-19)

| Lab | Status |
| --- | --- |
| Lab 0.5 | Note rải trong từng lab (Estimated Cost), chưa tách riêng — chấp nhận được |
| Lab 1 | Done (Console), Terraform skeleton chưa apply |
| Lab 2 | Done (Console), Terraform skeleton chưa apply |
| Lab 3A / 3B | Done — đã archive bản Lab 3 cũ (Terraform-first, vi phạm triết lý) |
| Lab 4 | **Done.** Network-only (VPC/Subnet/NAT/SG) — chốt scope, không gồm EC2/RDS/S3/IAM/CloudWatch |
| Lab 5 | = Terraform hoá Lab 2, đặt vào Custom VPC + RDS/S3/IAM. **Code đã viết (rds.tf, biến/outputs đã update), chưa `terraform apply`** |
| Lab 6–20 | **Đã generate code/docs ngày 2026-06-24; Terraform đã `fmt` + `validate`, chưa apply.** Lab 19 intentionally docs-first vì blast radius cấp AWS Organization. |

---

# BACKLOG THỨ TỰ XỬ LÝ

1. ✅ Archive `lab-03-custom-vpc-networking` (đã làm)
2. ✅ Update root README + gộp ROADMAP.md (đang làm)
3. ✅ Chốt scope Lab 4 = Network only (RDS/S3/IAM chuyển hẳn sang Lab 5, không phải "Phase B-E" của Lab 4 nữa)
4. ⚠️ `terraform apply` Lab 5 (đã có rds.tf, cần test thật — VPC/Subnet/SG/RDS/ECS/ALB end-to-end)
5. ✅ Generate Lab 6 → Lab 20 (đã hoàn thành code/docs; apply từng lab vẫn phải theo dependency graph và cost guardrail)

---

# CHANGELOG (so với bản gốc 20-lab)

1. Thêm Lab 0.5 — AWS Cost Guardrail (trước Lab 1).
2. Giữ Aurora ở Phase 5 (sau CI/CD) — theo thứ tự platform-first, không phải database-specialist-first.
3. Thêm Lab 9.5 — ECS vs EKS ADR, output là file ADR thật.
4. Tách Lab 12 thành 12A Amazon MQ (Required) và 12B MSK Serverless (Optional); bỏ MSK Provisioned.
5. Đổi priority: Lab 14 WAF → Required, Lab 15 CloudFront → Để sau.
6. Lab 19 Multi Account → Optional.
7. Sửa milestone "CSNP Production Ready": loại bỏ Lab 10 (EKS).
8. Thêm section SAA Theory Track (No Lab) để cover phần kiến thức thi không có trong hands-on lab.
