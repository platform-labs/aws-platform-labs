# Lab 09 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ cluster storage, writer, reader, endpoints và failover promotion.
2. **Console discovery:** xem topology/events/monitoring trên resource Terraform tạo; không dựng cluster thứ hai.
3. **Implementation:** apply cluster và hai instances trong một buổi có budget guardrail.
4. **CLI verification:** query members, writer flag, endpoints và failover events.
5. **Failure drill:** controlled failover; đo reconnect time và ghi nhận transaction/connection behavior.
6. **Rebuild without guide:** tự dựng writer/reader Multi-AZ và managed credential.
7. **Cleanup/cost audit:** destroy cùng ngày; kiểm tra instances, cluster, snapshots và secret.
8. **Interview recap:** so sánh RDS PostgreSQL, Multi-AZ và Aurora replicas bằng trade-off thật.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

AWS tự sinh master password và lưu trong Secrets Manager vì `manage_master_user_password=true`.

## Verify topology

```bash
aws rds describe-db-clusters \
  --db-cluster-identifier csnp-lab09-aurora \
  --query "DBClusters[0].{Endpoint:Endpoint,Reader:ReaderEndpoint,Members:DBClusterMembers}"
```

## Failover drill

Ghi lại writer hiện tại, sau đó:

```bash
aws rds failover-db-cluster --db-cluster-identifier csnp-lab09-aurora
```

Đo thời gian application reconnect. DNS endpoint không đổi nhưng connection đang mở sẽ bị đứt; app cần retry có backoff.

## So sánh

Ghi vào report:

- thời gian provision;
- failover duration;
- writer/reader endpoint;
- estimated monthly cost;
- operational differences với `aws_db_instance` Lab 5.
