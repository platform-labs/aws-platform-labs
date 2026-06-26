# Lab 20 - Disaster Recovery

## Mục tiêu

Định nghĩa RPO/RTO, backup policy, cross-region copy và restore drill cho tagged CSNP resources.

## Requires / Produces

- Requires: Lab 18 và các stateful services đã học.
- Produces: AWS Backup vault/plan hai region, tag-based selection và DR runbook.

## Architecture

```text
Primary resources -> AWS Backup vault (us-east-1)
                         |
                         +-> copy -> DR vault (us-west-2)
```

## Safety

Lab mặc định retention ngắn. Production cần Vault Lock, immutable retention, separate backup account và legal/compliance review.

## Cleanup

Recovery points phải hết/xóa trước khi vault bị destroy. Kiểm tra cả primary và DR region.

## Trạng thái

Code-ready, chưa apply.
