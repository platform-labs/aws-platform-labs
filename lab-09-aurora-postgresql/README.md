# Lab 09 - Aurora PostgreSQL

## Mục tiêu

Triển khai Aurora PostgreSQL trong private data subnets, một writer và một reader ở hai AZ; thực hành endpoint, failover và so sánh với RDS PostgreSQL Lab 5.

## Requires / Produces

- Requires: Lab 8; network outputs Lab 4.
- Produces: Aurora cluster endpoint, reader endpoint, Secrets Manager-managed master credential và failover report.

## Architecture

```text
ECS -> Aurora writer endpoint
read workload -> Aurora reader endpoint
                 writer AZ-A <-> reader AZ-B
```

## Guardrail chi phí

Aurora không thuộc free tier và có compute + storage + I/O cost. Mặc định lab dùng hai `db.t4g.medium`; apply, test và destroy trong cùng buổi. Budget alert là bắt buộc.

## Thực hành

Xem [hands-on](docs/lab-09-hands-on.md). Không cắt ECS production-like Lab 5 sang Aurora trước khi migration/rollback đã được kiểm thử.

## Cleanup

```bash
terraform destroy
```

Lab dùng `skip_final_snapshot=true` chỉ vì là sandbox.

## Trạng thái

Code-ready, chưa apply.
