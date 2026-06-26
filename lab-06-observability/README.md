# Lab 06 - Observability, Secrets Manager và KMS

## Mục tiêu

Xây lớp quan sát cho ECS platform của Lab 5: dashboard, metric, log, alarm và secret được mã hóa bằng KMS.

## Requires / Produces

- Requires: Lab 5 đã apply; có tên ECS cluster/service, ALB ARN suffix, target group ARN suffix và log group.
- Produces: CloudWatch dashboard, CPU/memory/5xx/healthy-host alarms, SNS topic, KMS key và Secrets Manager secret.

## Architecture

```text
ECS + ALB + RDS -> CloudWatch Metrics/Logs -> Dashboard + Alarms -> SNS
Application secret -> Secrets Manager -> customer-managed KMS key
```

## Thực hành

1. Copy `terraform.tfvars.example` thành `terraform.tfvars`, điền output/ARN của Lab 5.
2. Chạy `terraform init`, `terraform plan`, `terraform apply`.
3. Nạp secret bằng CLI theo [hands-on](docs/lab-06-hands-on.md); không commit secret vào Terraform.
4. Tạo traffic và quan sát dashboard/alarm.

## Chi phí và cleanup

Dashboard, custom alarms, log ingestion, Secrets Manager và KMS có phí nhỏ theo tháng. Container Insights có thể tăng đáng kể log/metric cost.

```bash
terraform destroy
```

Không xóa log group của Lab 5. Secret dùng recovery window 7 ngày.

## Tài liệu

- [Hands-on](docs/lab-06-hands-on.md)
- [Interview notes](docs/lab-06-interview-notes.md)

## Trạng thái

Code-ready, chưa apply.
