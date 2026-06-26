# Lab 07 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ metric → scaling policy → desired count và health check → task replacement.
2. **Console discovery:** xem Application Auto Scaling activity, ECS deployment và ALB target health.
3. **Implementation:** apply scaling target/policies rồi chạy load test có giới hạn.
4. **CLI verification:** query desired/running count, scaling activities và task AZ/subnet.
5. **Failure drill:** stop task, deploy image lỗi và quan sát self-healing/circuit breaker.
6. **Rebuild without guide:** tự chọn min/max/target/cooldown và giải thích từng giá trị.
7. **Cleanup/cost audit:** destroy policies, xác nhận service trở về desired count có kiểm soát.
8. **Interview recap:** phân biệt scaling, HA, self-healing và deployment rollback.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Load test có kiểm soát

```bash
hey -z 3m -c 30 "http://ALB_DNS/health"
aws ecs describe-services \
  --cluster csnp-platform-cluster \
  --services csnp-platform-wallet-api-service \
  --query "services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}"
```

Theo dõi Activity trong Application Auto Scaling. Sau test chờ cooldown để service scale-in.

## Self-healing drill

Stop một task trong Console hoặc CLI, không thay đổi desired count. ECS phải tạo task thay thế và ALB chỉ route tới target healthy.

## Multi-AZ verification

Liệt kê task ENI/subnet và xác nhận task phân bố qua hai private app subnet. Resilience không chỉ là `desired_count=2`; hai task cùng một AZ vẫn còn shared failure domain.

## Circuit breaker

Lab 5 chưa bật deployment circuit breaker. Thực hành tạo revision image lỗi, quan sát deployment kẹt, sau đó thêm:

```hcl
deployment_circuit_breaker {
  enable   = true
  rollback = true
}
```

vào `aws_ecs_service` của Lab 5 và apply tại state sở hữu service.
