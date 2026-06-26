# Lab 07 - Interview Notes

## Target tracking vs step scaling

Target tracking cố giữ metric quanh mục tiêu và đơn giản hơn. Step scaling cho kiểm soát mức tăng/giảm theo từng ngưỡng, phù hợp khi tải có hình dạng rõ.

## Vì sao min capacity nên là 2?

Một task chỉ có self-healing, chưa có service availability trong thời gian task khởi động lại. Hai task đặt ở hai AZ giảm single point of failure.

## CPU và memory cùng scale thì sao?

Policy scale-out độc lập: policy nào yêu cầu tăng cũng có thể tăng capacity. Scale-in thận trọng hơn vì các policy phải đồng thuận.

## Health check grace period

Giúp ECS không kill task đang warm-up trước khi app sẵn sàng. Giá trị phải phản ánh startup thực, không dùng số lớn để che lỗi.
