# Lab 12B - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ producer → partitioned log → independent consumer groups, offsets và replay.
2. **Console discovery:** xem cluster, IAM authentication và metrics; không tạo cluster thứ hai.
3. **Implementation:** apply MSK Serverless, tạo topic và hai consumer groups.
4. **CLI verification:** describe cluster, list topic/partitions, produce/consume và kiểm tra committed offsets.
5. **Failure drill:** dừng consumer để tạo lag, restart và replay; quan sát ordering theo partition key.
6. **Rebuild without guide:** tự chọn topic, key và consumer groups cho compliance/analytics.
7. **Cleanup/cost audit:** destroy trong cùng buổi; kiểm tra client resources/logs còn sót.
8. **Interview recap:** so sánh Kafka với RabbitMQ bằng semantics, không bằng popularity.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

Apply Terraform, lấy bootstrap brokers, sau đó dùng client hỗ trợ SASL/IAM.

Thực hành:

- topic `wallet-events-v1`;
- partition key = aggregate/account ID để giữ ordering theo entity;
- hai consumer groups độc lập: compliance và analytics;
- replay từ offset cũ;
- quan sát consumer lag.

Không đưa PII thô vào event nếu chưa có classification, retention và encryption policy.
