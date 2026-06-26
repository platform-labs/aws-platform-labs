# AWS Cost Guardrail — Hands-on Setup

## Deliberate practice loop

1. **Mental model:** vẽ chuỗi Cost Explorer/Billing metric → Budget/Alarm → SNS → email và ghi rõ độ trễ của từng lớp.
2. **Console discovery:** tìm Billing preferences, Budgets, CloudWatch Billing metrics và SNS subscription trước khi tạo.
3. **Implementation:** làm Step 1–3 bên dưới; guardrail này được giữ lại cho các lab sau.
4. **CLI verification:** dùng CLI liệt kê budget, SNS topic/subscription và alarm; đối chiếu với Console.
5. **Failure drill:** để một SNS subscription ở trạng thái pending, giải thích vì sao alarm không gửi email, rồi confirm và test lại.
6. **Rebuild without guide:** tự dựng budget $5/$10 và notification chỉ từ mục tiêu đầu ra.
7. **Cleanup/cost audit:** không xóa budget chính; xóa alarm/topic test dư và kiểm tra Cost Explorer.
8. **Interview recap:** giải thích Budget khác Billing Alarm thế nào và vì sao alert không phải hard spending limit.

Theo dõi các lượt luyện bằng [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Mục tiêu

Thiết lập 3 layer bảo vệ chi phí:

```
Layer 1: Budget (dashboard thủ công kiểm tra)
           ↓
Layer 2: CloudWatch Alarm (cảnh báo tự động, real-time)
           ↓
Layer 3: Email Notification qua SNS (thông báo cá nhân)
```

---

## Step 1 — Tạo AWS Budget

### 1.1 Vào AWS Budgets

* Đăng nhập AWS Console
* Tìm kiếm **"Budgets"** → vào Billing → Budgets (hoặc trực tiếp [console.aws.amazon.com/billing/home#/budgets](https://console.aws.amazon.com/billing/home#/budgets))

### 1.2 Create Budget

Kích **"Create Budget"** → **"Cost Budget"**

| Field | Giá trị |
| --- | --- |
| Budget name | `CSNP-Monthly-Budget` |
| Period | `Monthly` |
| Start month | Tháng hiện tại |
| Budgeted amount | `$20` (hoặc số tiền bạn dự kiến dùng) |

### 1.3 Thêm Alert Notifications

Trên cùng form:

* **Alert #1 (Warning):**
  - Threshold: `25%` (= $5 nếu budget $20)
  - Alert Type: `Actual` (cảnh báo khi chi phí thực tế vượt)
  - Notification: **Email** → nhập email của bạn

* **Alert #2 (Critical):**
  - Threshold: `50%` (= $10 nếu budget $20)
  - Alert Type: `Actual`
  - Notification: **Email** → nhập email của bạn

Kích **"Create"**

### 1.4 Verify

Sau vài phút, bạn sẽ nhận email confirm từ AWS SNS:

```
Subject: AWS Notification - Subscription Confirmation
Body: Bấm link Confirm Subscription
```

**Bấm link đó để activate email notification.**

---

## Step 2 — Tạo CloudWatch Alarm cho Billing

CloudWatch Alarms cho metric `EstimatedCharges` trigger **trong vòng vài phút** (nhanh hơn Budget email thường gặp delay).

### 2.1 Vào CloudWatch Alarms

* Tìm kiếm **"CloudWatch"** → Alarms → **"Create alarm"**

### 2.2 Tạo Alarm #1 (Warning - $5)

| Field | Giá trị |
| --- | --- |
| Select metric | Browse → Billing → EstimatedCharges |
| Statistic | `Maximum` |
| Period | `1 hour` |
| Threshold type | `Static` |
| Alarm condition | `Greater than or equal to` |
| Threshold value | `5` |
| Datapoints to alarm | `1` (trigger ngay lần đầu vượt) |

### 2.3 Notification (SNS)

* **Create new SNS topic:**
  - Topic name: `csnp-billing-warning`
  - Email endpoints: nhập email của bạn
  
* Kích **"Create topic"**

* Alarm name: `CSNP-Billing-Warning-5USD`
* Alarm description: `Alert when estimated charges exceed $5`

Kích **"Create alarm"**

### 2.4 Tạo Alarm #2 (Critical - $10)

Lặp lại Step 2.2 & 2.3 nhưng:

| Field | Giá trị |
| --- | --- |
| Threshold value | `10` |
| SNS topic | `csnp-billing-warning` (tái sử dụng) |
| Alarm name | `CSNP-Billing-Critical-10USD` |

### 2.5 Confirm SNS Subscription (nếu chưa)

Kiểm tra email, bấm **"Confirm subscription"** link từ SNS.

---

## Step 3 — Verify Alarms Hoạt động

### 3.1 Test SNS Email

Vào CloudWatch → Alarms → chọn alarm `CSNP-Billing-Warning-5USD` → **"Edit"** → **"View in metrics"**

Nếu EstimatedCharges của bạn > $5, alarm sẽ hiển thị **state = ALARM** (đỏ). Nếu < $5, state = OK (xanh).

### 3.2 Xem chi tiết Billing

* Vào **Billing Console** → **Costs & Usage** → **Cost and Usage Reports**
* Filter theo ngày hôm nay → xem dịch vụ nào đang tốn tiền

### 3.3 Tag Strategy (Optional nhưng recommended)

Khi tạo resource ở lab tiếp theo, gắn tag:

```
Key: Lab
Value: lab-01 (hoặc lab-02, lab-03...)

Key: Environment
Value: dev (hoặc lab, test)

Key: Cleanup
Value: true (để nhắc nhở xoá sau)
```

Sau đó vào **Cost & Usage** → **Group by** → **Tag** để xem chi phí theo lab.

---

## Step 4 — Cleanup Checklist (sau mỗi lab)

| Resource | Action |
| --- | --- |
| EC2 instance | Stop (nếu giữ) hoặc Terminate |
| RDS instance | Stop (hoặc Snapshot + Terminate) |
| NAT Gateway | Delete (chi phí cao nhất) |
| ECS Service | Deregister task definition + Delete service |
| ALB | Delete |
| Unattached EIP | Release |

Sau cleanup, kiểm tra Billing Console — chi phí phải giảm gần như bằng 0 (chỉ còn S3 storage nếu để lại bucket).

---

## Khi nào bị Alert?

| Scenario | Trigger |
| --- | --- |
| Lab 1 chạy toàn bộ 1 tháng | RDS EC2 t3.micro (free tier) + RDS 5GB (free tier nếu dùng free tier, $0.14/GB-month) → tổng ~$0-1 |
| Lab 3A + 3B chạy cả tháng | NAT Gateway ~$32 → **Trigger warning($5)** khi chạy vài ngày |
| Lab 4 + 5 chạy full + ALB | ALB $15 + ECS Fargate task 2 vCPU $0.04/hour = $29/tháng → **Trigger critical($10)** |
| Quên terminate EC2 t3.small (on-demand) | $0.023/hour × 730h = ~$16/tháng → **Trigger critical($10)** |

---

## Best Practices

✅ **DO:**
* Kiểm tra Billing Console **hàng tuần**
* Gắn tag cho mọi resource
* Set ngưỡng alert **dưới dự tính 20-30%** (buffer an toàn)
* Cleanup ngay sau lab xong (không để chạy qua đêm)
* Subscribe email cho SNS topic Billing

❌ **DON'T:**
* Ignore budget alert — nó là signal lỏng gọi
* Để NAT Gateway/RDS chạy khi không dùng
* Tạo resource mà không biet chúng tốn bao tiền (check pricing page trước)
* Dựa vào Console alert (thường bị delay) thay vì CloudWatch (real-time)

---

## Cost Breakdown (Lab Các Labs Tính Chung)

| Lab | Chi phí/tháng (nếu chạy full) | Cleanup ngay? |
| --- | ------ | --- |
| Lab 0 (Budgets) | $1 | Không (giữ vĩnh viễn) |
| Lab 1 (EC2 + RDS) | $5-10 (free tier hết) | Có — costly |
| Lab 2 (ECS Fargate) | $5-15 | Có |
| Lab 3A/3B (VPC) | $32 (NAT) | **Có — ưu tiên #1** |
| Lab 4 (Terraform network) | $32 (NAT) | **Có** |
| Lab 5 (Terraform ECS) | $50+ (ALB + ECS + RDS) | **Có** |

**Nếu chạy toàn bộ cùng lúc**: ~$150+/tháng. **Nên cleanup sau mỗi lab.**

---

## Troubleshooting

### Email notification không tới

* [ ] Kiểm tra spam folder
* [ ] Vào SNS → Topics → `csnp-billing-warning` → xem **Subscriptions** → status có phải `Confirmed` không
* Nếu `PendingConfirmation`: click link confirm lại từ email

### Alarm hiển thị "Insufficient Data"

* EstimatedCharges metric mất ~6 giờ mới appear lần đầu — chờ đến ngày hôm sau
* Nếu vẫn chưa có dữ liệu: chắc chắn không có charge gì → OK, không cần lo

### Budget warning hiển thị nhưng Alarm không

* Budget cập nhật **1 lần/ngày**, Alarm cập nhật **1 lần/giờ**
* Nếu charge vừa phát sinh < 1 giờ, Alarm chưa trigger — chờ xíu

---

## Liên lạc Support nếu

* Biểu chi phí > ngưỡng mà bạn không biết từ đâu
* Billing thắc mắc → AWS Support (Basic free, Standard $29/tháng)
