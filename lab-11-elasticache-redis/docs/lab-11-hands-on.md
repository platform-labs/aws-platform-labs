# Lab 11 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ cache-aside hit/miss, TTL, database fallback và Redis primary/replica failover.
2. **Console discovery:** xem replication group, nodes, endpoints và CloudWatch metrics sau apply.
3. **Implementation:** apply Terraform, kết nối TLS và thêm cache-aside vào app/test client.
4. **CLI verification:** describe replication group, `redis-cli PING`, đo hit/miss và latency.
5. **Failure drill:** failover hoặc tạm làm Redis unavailable; app phải fallback thay vì mất dữ liệu nghiệp vụ.
6. **Rebuild without guide:** tự dựng private Multi-AZ Redis và giải thích SG path.
7. **Cleanup/cost audit:** destroy nodes ngay sau lab; kiểm tra snapshots và subnet/security groups.
8. **Interview recap:** giải thích cache consistency, distributed lock limits và vì sao Redis không là source of truth.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Verify

```bash
aws elasticache describe-replication-groups \
  --replication-group-id csnp-lab11-redis
```

Từ ECS task hoặc debug host trong VPC:

```bash
redis-cli --tls -h PRIMARY_ENDPOINT -p 6379 PING
```

Thực hành:

- cache-aside với TTL ngắn;
- đo hit/miss và latency;
- lock bằng `SET key value NX PX`;
- test idempotency: lock phải có owner token và unlock bằng compare-and-delete script.

Không dùng Redis lock như thay thế database transaction cho tiền/ledger.
