# platforms/aws/labs

Learning / POC / experiments cho AWS. **Không phải production infra.**

## Ba vùng tách biệt trong `platforms/aws/`

| Thư mục | Vai trò |
| ------- | ------- |
| `platforms/aws/terraform/` | Production-grade infrastructure (bootstrap, envs, modules) |
| `platforms/aws/kubernetes/` | Production-grade manifests (ArgoCD, ingress...) |
| `platforms/aws/labs/` | Learning, POC, hands-on labs - **resource tạm, apply/destroy liên tục** |

Tuyệt đối không trộn lẫn ba vùng này. Không reference module từ `terraform/modules/` vào trong `labs/` (trừ khi mục tiêu lab là validate lại module đó, ví dụ lab EKS). Labs dùng **bucket state riêng** và tuyệt đối không dùng backend/key của `terraform/envs/*`.

## Roadmap

[`ROADMAP.md`](./ROADMAP.md) là **source of truth duy nhất** — gồm roadmap chi tiết từng lab, SAA Theory Track, dependency graph (Requires/Produces), trạng thái hiện tại và backlog. Không còn file roadmap rời (`all lab.txt` đã được gộp vào, không dùng nữa để tránh drift giữa 2 nguồn).

## Cách luyện nhiều vòng

- [`DELIBERATE_PRACTICE.md`](./DELIBERATE_PRACTICE.md): learning loop, năm lượt luyện và Definition of Done.
- [`PRACTICE_MATRIX.md`](./PRACTICE_MATRIX.md): Console discovery, CLI verification, failure drill và rebuild target của từng Lab 00–20.

Hands-on của mỗi lab đều dùng cùng chu trình: mental model → Console discovery → implementation → CLI verification → failure drill → rebuild không nhìn guide → cleanup/cost audit → interview recap.

## Danh sách Labs

| Lab | Nội dung | Status |
| --- | -------- | ------ |
| [lab-01-ec2-rds-s3-cloudwatch](./lab-01-ec2-rds-s3-cloudwatch) | EC2 + RDS PostgreSQL + S3 + IAM Role + CloudWatch | Done (manual console), Terraform skeleton chưa apply |
| [lab-02-ecr-ecs-fargate](./lab-02-ecr-ecs-fargate) | Dockerize → ECR → ECS Fargate → ALB → CloudWatch | Done (manual console), Terraform skeleton chưa apply |
| [lab-03a-vpc-networking-console](./lab-03a-vpc-networking-console) | Custom VPC 3-tier — 3A Console, 3B CLI | Done |
| [lab-04-terraform-platform-foundation](./lab-04-terraform-platform-foundation) | Terraform hoá VPC 3-tier (Network only) | **Done** |
| [lab-05-terraform-ecs-platform](./lab-05-terraform-ecs-platform) | = Terraform hoá Lab 2, đặt vào Custom VPC + RDS + S3 + IAM | Code đã viết (rds.tf, biến/outputs đã update), **chưa `terraform apply`** |
| [lab-06-observability](./lab-06-observability) | CloudWatch dashboard/alarms/log metric + Secrets Manager + KMS | Code-ready, chưa apply |
| [lab-07-auto-scaling-resilience](./lab-07-auto-scaling-resilience) | ECS target tracking scaling + resilience drills | Code-ready, chưa apply |
| [lab-08-cicd](./lab-08-cicd) | GitHub Actions OIDC → ECR → ECS | Code-ready, chưa apply |
| [lab-09-aurora-postgresql](./lab-09-aurora-postgresql) | Aurora PostgreSQL writer/reader + failover | Code-ready, chưa apply |
| [lab-09-5-ecs-vs-eks-adr](./lab-09-5-ecs-vs-eks-adr) | ADR ECS vs EKS cho CSNP | Draft cần team review |
| [lab-10-eks](./lab-10-eks) | EKS managed nodes + Deployment/Service/Ingress/HPA | Code-ready, chưa apply |
| [lab-11-elasticache-redis](./lab-11-elasticache-redis) | ElastiCache Redis Multi-AZ | Code-ready, chưa apply |
| [lab-12a-amazon-mq-rabbitmq](./lab-12a-amazon-mq-rabbitmq) | Amazon MQ RabbitMQ + retry/DLQ exercises | Code-ready, chưa apply |
| [lab-12b-msk-serverless](./lab-12b-msk-serverless) | MSK Serverless + IAM auth | Optional, code-ready |
| [lab-13-route53-acm](./lab-13-route53-acm) | Route 53 + ACM + ALB HTTPS | Code-ready, chưa apply |
| [lab-14-aws-waf](./lab-14-aws-waf) | AWS managed rules + rate limiting | Code-ready, chưa apply |
| [lab-15-cloudfront](./lab-15-cloudfront) | CloudFront API/static cache behaviors | Code-ready, chưa apply |
| [lab-16-gitops-argocd](./lab-16-gitops-argocd) | Argo CD AppProject/Application | Code-ready, chưa apply |
| [lab-17-external-secrets](./lab-17-external-secrets) | ESO + IRSA + Secrets Manager | Code-ready, chưa apply |
| [lab-18-opentelemetry](./lab-18-opentelemetry) | ADOT Collector + X-Ray | Code-ready, chưa apply |
| [lab-19-multi-account-strategy](./lab-19-multi-account-strategy) | Organizations/landing-zone design + SCP samples | Docs-first, intentionally no apply |
| [lab-20-disaster-recovery](./lab-20-disaster-recovery) | AWS Backup + cross-region copy + restore drill | Code-ready, chưa apply |

> `archive/lab-03-custom-vpc-networking-legacy/` — bản Lab 3 cũ, viết Terraform ngay từ đầu, vi phạm triết lý Console-first. Không phát triển tiếp, xem `ARCHIVE_NOTE.md` trong đó.

## `reference/`

Tài liệu AWS CLI tổng quát, không gắn với lab cụ thể nào (credential chain, profile, region, cheat sheet tra lệnh nhanh). Đọc trước khi vào lab nếu chưa quen AWS CLI.

## Tạo Lab mới

1. Copy [`TEMPLATE.md`](./TEMPLATE.md) thành `lab-NN-ten-lab/README.md`
2. Tạo cấu trúc thư mục theo phần cuối của template (`docs/`, `src/`, `terraform/`, `screenshots/`)
3. Nếu lab có Terraform, `terraform/backend.tf` dùng shared labs S3 backend nhưng **key riêng** theo mẫu `aws/lab-NN/terraform.tfstate`; không bao giờ dùng backend/key của `platforms/aws/terraform/envs/*`
4. Cập nhật bảng "Danh sách Labs" ở trên

## Quy ước Terraform trong Labs

Quy ước chi tiết và mẫu chuẩn nằm tại [`TERRAFORM_CONVENTIONS.md`](./TERRAFORM_CONVENTIONS.md).

* **Flat resources, không dùng module** cho các lab học fundamentals (lab-01, lab-02). Mục tiêu là hiểu từng resource, dùng module sẽ làm mất giá trị học.
* Khi lab có mục tiêu validate lại module production (ví dụ lab-03-eks dùng `modules/eks`, `modules/vpc`), ghi rõ điều này trong README của lab đó.
* Mọi lab có Terraform dùng bucket `csnp-labs-tfstate-289069331511`, DynamoDB lock table `csnp-labs-tfstate-lock` và một state key độc lập. Chạy `bootstrap/` trước khi init lab đầu tiên.
* Remote state chỉ là nơi lưu state. Các lab vẫn ưu tiên truyền output qua `terraform.tfvars` để dependency dễ thấy; chỉ dùng `terraform_remote_state` khi lab nêu rõ.
* Mỗi lab có `terraform.tfvars.example`, không commit `terraform.tfvars` thật.
* Mỗi lab có `.gitignore` riêng cho `.terraform/`, accidental local state file, và `terraform.tfvars`.

## Security

* Không commit private key (`.pem`), Access Key, hoặc bất kỳ credential thật nào vào repo, kể cả trong `docs/` hoặc screenshot.
* IAM Role > Access Key, ngay cả trong lab.
* Nếu lab cần test có thật connect AWS account, dùng temporary credentials hoặc IAM user riêng cho lab, không dùng credential CSNP production.
