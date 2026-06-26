# Lab 12A - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ producer → exchange → queue → consumer → retry/error queue và delivery acknowledgement.
2. **Console discovery:** xem broker, connections, queue depth và metrics trên resource Terraform tạo.
3. **Implementation:** apply broker, kết nối MassTransit, publish và consume message.
4. **CLI verification:** describe broker và dùng client/management metrics chứng minh message flow.
5. **Failure drill:** poison message phải đi qua retry policy rồi DLQ; consumer không được retry vô hạn.
6. **Rebuild without guide:** tự dựng producer/consumer idempotent và retry/DLQ topology.
7. **Cleanup/cost audit:** destroy broker cùng ngày; không log hoặc commit broker password.
8. **Interview recap:** giải thích at-least-once, idempotency, retry và Amazon MQ trade-offs.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Kết nối ứng dụng bằng endpoint `amqps://`; không mở broker public.

## MassTransit exercise

- publish `PaymentRequested`;
- consumer retry ngắn cho transient failure;
- sau retry chuyển fault message sang error/DLQ queue;
- lưu message ID trong inbox table để consumer idempotent;
- quan sát redelivery, queue depth và poison message.

## Verify

```bash
aws mq describe-broker --broker-id "$(terraform output -raw broker_id)"
```

Không log connection string có password.
