# Lab 11 - ElastiCache Redis

## Mục tiêu

Thêm managed Redis cache vào private data tier để thực hành cache-aside, session, rate limiting và distributed lock.

## Requires / Produces

- Requires: Lab 5 network/ECS.
- Produces: Redis replication group Multi-AZ, primary/reader endpoint và security group chỉ nhận từ ECS SG.

## Architecture

```text
ECS tasks -> Redis primary endpoint
             primary AZ-A -> replica AZ-B (automatic failover)
```

## Cost guardrail

Hai cache nodes tính phí theo giờ. Dùng node nhỏ, test ngắn và destroy ngay.

## Thực hành

Apply Terraform, kết nối từ ECS/host trong VPC, đo cache hit/miss và chạy failover. Xem [hands-on](docs/lab-11-hands-on.md).

## Cleanup

```bash
terraform destroy
```

## Trạng thái

Code-ready, chưa apply.
