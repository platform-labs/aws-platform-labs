# Lab 12A - Interview Notes

## Retry đặt ở đâu?

In-memory immediate retry cho lỗi rất ngắn; delayed/redelivery cho dependency tạm lỗi; DLQ cho message vượt policy. Retry vô hạn gây queue starvation.

## At-least-once nghĩa gì?

Message có thể được giao nhiều lần. Consumer phải idempotent, thường bằng message ID + unique constraint/inbox.

## Amazon MQ vs tự host RabbitMQ

MQ giảm broker patching/backup/failover work nhưng không loại bỏ topology, capacity, client retry, schema và poison-message operations.
