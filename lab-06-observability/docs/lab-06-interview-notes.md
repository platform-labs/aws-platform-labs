# Lab 06 - Interview Notes

## Metrics, logs và traces khác nhau thế nào?

- Metrics trả lời “hệ thống đang tốt hay xấu” theo chuỗi thời gian.
- Logs giải thích sự kiện chi tiết.
- Traces nối một request xuyên nhiều service; Lab 18 triển khai phần này.

## Vì sao alarm cần SNS?

Alarm chỉ biểu diễn state. SNS tách việc phát hiện khỏi kênh nhận thông báo, cho phép email, Chatbot hoặc Lambda subscribe độc lập.

## Vì sao không truyền secret value qua Terraform?

Giá trị nhạy cảm vẫn có thể nằm trong state dù variable được đánh dấu `sensitive`. Lab chỉ quản lý secret container/key bằng Terraform và nạp payload qua API ngoài state.

## Container Insights trade-off

Cho metric chi tiết theo task/service nhưng tăng ingestion và storage cost. Production nên đặt retention, sampling và dashboard theo SLO thay vì bật rồi bỏ mặc.
