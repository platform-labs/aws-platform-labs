# Lab 12A - Amazon MQ for RabbitMQ

## Mục tiêu

Triển khai RabbitMQ managed broker, kết nối MassTransit và thực hành retry, dead-letter queue, idempotent consumer.

## Requires / Produces

- Requires: Lab 11 và private subnets Lab 4.
- Produces: private RabbitMQ broker endpoints và SG chỉ nhận từ ECS.

## Cost guardrail

Amazon MQ không có free tier phù hợp lab này. Mặc định single-instance để học; production phải đánh giá active/standby Multi-AZ. Destroy trong cùng buổi.

## Secret warning

Broker password là Terraform sensitive variable nhưng vẫn nằm trong encrypted remote state. Dùng password lab riêng, không tái sử dụng.

## Cleanup

```bash
terraform destroy
```

## Tài liệu

- [Hands-on](docs/lab-12a-hands-on.md)
- [Interview notes](docs/lab-12a-interview-notes.md)

## Trạng thái

Code-ready, chưa apply.
