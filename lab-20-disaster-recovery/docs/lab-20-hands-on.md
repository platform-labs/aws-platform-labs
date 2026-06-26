# Lab 20 - Hands-on

## Deliberate practice loop

1. **Mental model:** workload → backup plan/vault → cross-region copy → isolated restore → DNS/application recovery.
2. **Console discovery:** xem backup jobs, recovery points, copy jobs và restore jobs sau Terraform.
3. **Implementation:** chốt RPO/RTO, tag resource, apply plan và tạo recovery point.
4. **CLI verification:** list/describe jobs và recovery points; ghi timestamp để đo RPO/RTO thật.
5. **Failure drill:** restore vào target cô lập, chạy integrity/smoke test và tabletop region outage.
6. **Rebuild without guide:** tự viết runbook từ “region unavailable” tới service healthy.
7. **Cleanup/cost audit:** xóa restored resources/recovery points theo retention; kiểm tra cả hai region.
8. **Interview recap:** giải thích backup khác DR và chọn pilot-light/warm-standby/active-active theo business impact.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## 1. Chốt mục tiêu

Lập bảng từng service:

| Service | RPO | RTO | Backup | Restore owner |
| --- | --- | --- | --- | --- |
| RDS/Aurora | 15m | 2h | snapshots/PITR | Data platform |
| S3 | near-zero | 1h | versioning/replication | Platform |
| Redis | rebuild/cache | 30m | none/snapshot by need | App |
| MQ/MSK | domain-specific | domain-specific | replay/outbox | App |

## 2. Apply backup plan

Tag resource cần bảo vệ: `Backup=lab20`, rồi apply Terraform.

## 3. Restore drill

Không chỉ kiểm tra “backup completed”. Restore vào isolated subnet/name mới, chạy integrity query và application smoke test, ghi thời gian thực tế.

## 4. Region failover tabletop

Liệt kê dependency cần dựng lại: network, IAM, KMS keys, secrets, images, DNS, certificates, quotas và observability.
