# Lab 00 - AWS Cost Guardrail

## Mục tiêu

Trước khi bắt đầu các lab phát sinh chi phí (RDS, NAT Gateway, Aurora...), thiết lập **Cost Awareness & Cost Control** từ ngay đầu. Sau lab này cần hiểu được:

* AWS Budget để track chi phí thực tế so với dự báo
* Cost Alert để cảnh báo khi chi phí vượt ngưỡng
* CloudWatch & SNS để gửi notification qua Email
* Phân loại chi phí theo service và thẻ (tag)

## Prerequisites

* AWS Account, quyền billing
* Email để nhận thông báo alert
* AWS Region: **us-east-1** (hoặc region bạn sử dụng chính)

> Đây là lab **non-technical** — không có Terraform, CLI, IAM role phức tạp. Mục đích là **hành động phòng vệ**, tránh bill shock khi dùng dịch vụ tốn tiền mà không nhận thấy.

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| AWS Budgets | Theo dõi chi phí theo thời gian thực, so sánh với forecast |
| CloudWatch Alarms | Trigger khi ngưỡng chi phí bị vượt |
| SNS | Gửi email thông báo alert |
| AWS Billing Console | Xem chi tiết hóa đơn, tag-based cost allocation |

## Chi phí của Lab này

| Tên | Chi phí |
| --- | ------- |
| AWS Budgets | Free (tối đa 2 budgets free, thêm $0.02 per budget/day) |
| CloudWatch Alarms | Free cho metric Estimated Charges |
| SNS | ~$0.50/tháng (100 email) |
| **Tổng** | **~$1/tháng** — rất rẻ so với NAT Gateway ($32) |

## Ngưỡng cảnh báo đề xuất

```text
Warning  (Soft Alert):  $5   — Thông báo mềm, check lại xem resource nào tốn
Critical (Hard Alert):  $10  — Alert cứng, xem xét cleanup ngay
```

### Áp dụng đặc biệt cho

| Lab | Lý do tốn tiền |
| --- | -------------- |
| Lab 1 (RDS PostgreSQL) | RDS chạy liên tục, ~$30-50/tháng nếu không stop |
| Lab 3A/3B (NAT Gateway) | ~$32/tháng, tính theo giờ — xoá sau lab xong |
| Lab 5 (ALB + ECS) | ALB ~$15/tháng, ECS Fargate tính theo CPU/Memory seconds |
| Lab 9 (Aurora PostgreSQL) | Aurora tốn hơn RDS ~2x |
| Lab 12A/12B (MQ/MSK) | MQ ~$60/tháng, MSK Serverless tính data throughput |

## Lessons Learned

* Hầu hết learner khi mới AWS đều bị "tái xảy ra" — không setup budget, không cleanup sau lab, rồi nhận email AWS về bill cao → mất tin tưởng vào cloud.
* **5 phút setup budget lúc này = tránh được $100 bill surprise sau 3 tháng.**
* CloudWatch Alarms cho Billing metric là cách "safety net" duy nhất — email alert từ Billing Dashboard không real-time, còn CloudWatch Alarms có thể trigger trong vòng vài phút.
* Tag strategy từ bây giờ (ví dụ `Environment: lab-01`, `CostCenter: CSNP`) giúp cost allocation dễ sau — không cần chạy lại khi cần phân tích.

## Khi kết thúc các lab khác

* [ ] **Cleanup ngay sau lab xong** — không để resource chạy qua đêm:
  * Lab 1: Stop EC2 + RDS sau khi verify (hoặc terminate nếu không giữ lại để reference)
  * Lab 3A: Xoá NAT Gateway sau khi verify (để lại VPC/Subnet cho tham khảo)
  * Lab 4: `terraform destroy` sau khi verify
  * Lab 5: Nếu không dùng nữa, `terraform destroy` cả stack

* [ ] **Kiểm tra Billing Console** hàng tuần — xem thêm dịch vụ nào vô tình chạy (ví dụ NAT gateway unattached vẫn tính tiền)

## Trạng thái

Đây không phải coding lab, chỉ là setup bảo vệ — làm xong trong ~10 phút.
