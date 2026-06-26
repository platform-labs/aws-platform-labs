# Lab 12B - Interview Notes

## Kafka khác RabbitMQ?

Kafka là distributed append log tối ưu retention/replay/streaming. RabbitMQ là message broker mạnh về routing và work queues. Chọn theo semantics, không theo độ “hot”.

## Ordering

Kafka chỉ bảo đảm ordering trong một partition. Partition key là quyết định domain quan trọng.

## Consumer lag

Lag là khoảng cách producer offset và consumer committed offset; tăng liên tục báo hiệu consumer không theo kịp hoặc đang lỗi.
