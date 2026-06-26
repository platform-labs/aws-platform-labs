# Lab 06 - Hands-on

## Deliberate practice loop

1. **Mental model:** phân biệt metrics, logs, alarms, dashboard và secrets; vẽ signal → alarm → SNS.
2. **Console discovery:** mở CloudWatch dashboard/alarm/log group và Secrets Manager sau apply, map từng widget/rule với HCL.
3. **Implementation:** lấy input Lab 5, apply Terraform, nạp secret ngoài state và bật Container Insights có chủ đích.
4. **CLI verification:** list dashboard/alarms, tail logs, describe secret metadata và kiểm tra ECS cluster setting.
5. **Failure drill:** tạo application error hoặc tải CPU ngắn để alarm chuyển state; xác nhận notification.
6. **Rebuild without guide:** tự dựng dashboard và bốn alarm chỉ từ expected signals.
7. **Cleanup/cost audit:** xóa dashboard/alarm test, kiểm tra log retention và Container Insights ingestion.
8. **Interview recap:** giải thích signal nào dùng để detect, signal nào dùng để diagnose.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## 1. Lấy input từ Lab 5

```bash
aws elbv2 describe-load-balancers --names csnp-platform-alb
aws elbv2 describe-target-groups --names csnp-platform-wallet-api-tg
terraform -chdir=../lab-05-terraform-ecs-platform/terraform output
```

ARN suffix là phần sau `loadbalancer/` hoặc `targetgroup/`, đúng format CloudWatch yêu cầu.

## 2. Apply

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## 3. Nạp secret ngoài Terraform state

```bash
aws secretsmanager put-secret-value \
  --secret-id "$(terraform output -raw application_secret_arn)" \
  --secret-string '{"username":"postgres","password":"REPLACE_ME"}'
```

Sau đó tạo revision mới cho ECS task definition dùng `secrets.valueFrom`. Execution Role phải có `secretsmanager:GetSecretValue` và `kms:Decrypt` cho đúng secret/key.

## 4. Bật Container Insights cho cluster hiện hữu

```bash
aws ecs update-cluster-settings \
  --cluster csnp-platform-cluster \
  --settings name=containerInsights,value=enabled
```

Lệnh này thay đổi resource do Lab 5 quản lý. Sau khi học xong, cập nhật Lab 5 Terraform hoặc tắt lại để tránh drift.

## 5. Verify

### 5.1. Bằng CLI

```bash
aws cloudwatch list-dashboards --dashboard-name-prefix csnp-platform
aws cloudwatch describe-alarms --alarm-name-prefix csnp-platform
aws logs tail /ecs/csnp-platform-wallet-api --since 10m
```

### 5.2. Quan sát trên AWS Console

Lab 6 tạo ra các resource về Observability. Để thấy rõ giá trị, anh cần xem trực tiếp trên giao diện AWS:

**1. Xem Dashboard (Biểu đồ tổng quan)**
*   Vào AWS Console, tìm dịch vụ **CloudWatch** > chọn mục **Dashboards** (menu bên trái).
*   Click vào dashboard `csnp-platform-lab06`.
*   Anh sẽ thấy các widget biểu đồ hiển thị: CPU/Memory của ECS và trạng thái Healthy Hosts / lỗi 5xx của ALB. Đây là nơi dùng để theo dõi "sức khỏe" hệ thống hàng ngày.

**2. Xem Alarms (Cảnh báo tự động)**
*   Vào **CloudWatch** > **All alarms**.
*   Anh sẽ thấy 4 alarms vừa được Terraform tạo ra:
# Lab 06 - Hands-on

## Deliberate practice loop

1. **Mental model:** phân biệt metrics, logs, alarms, dashboard và secrets; vẽ signal → alarm → SNS.
2. **Console discovery:** mở CloudWatch dashboard/alarm/log group và Secrets Manager sau apply, map từng widget/rule với HCL.
3. **Implementation:** lấy input Lab 5, apply Terraform, nạp secret ngoài state và bật Container Insights có chủ đích.
4. **CLI verification:** list dashboard/alarms, tail logs, describe secret metadata và kiểm tra ECS cluster setting.
5. **Failure drill:** tạo application error hoặc tải CPU ngắn để alarm chuyển state; xác nhận notification.
6. **Rebuild without guide:** tự dựng dashboard và bốn alarm chỉ từ expected signals.
7. **Cleanup/cost audit:** xóa dashboard/alarm test, kiểm tra log retention và Container Insights ingestion.
8. **Interview recap:** giải thích signal nào dùng để detect, signal nào dùng để diagnose.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## 1. Lấy input từ Lab 5

```bash
aws elbv2 describe-load-balancers --names csnp-platform-alb
aws elbv2 describe-target-groups --names csnp-platform-wallet-api-tg
terraform -chdir=../lab-05-terraform-ecs-platform/terraform output
```

ARN suffix là phần sau `loadbalancer/` hoặc `targetgroup/`, đúng format CloudWatch yêu cầu.

## 2. Apply

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## 3. Nạp secret ngoài Terraform state

```bash
aws secretsmanager put-secret-value \
  --secret-id "$(terraform output -raw application_secret_arn)" \
  --secret-string '{"username":"postgres","password":"REPLACE_ME"}'
```

Sau đó tạo revision mới cho ECS task definition dùng `secrets.valueFrom`. Execution Role phải có `secretsmanager:GetSecretValue` và `kms:Decrypt` cho đúng secret/key.

## 4. Bật Container Insights cho cluster hiện hữu

```bash
aws ecs update-cluster-settings \
  --cluster csnp-platform-cluster \
  --settings name=containerInsights,value=enabled
```

Lệnh này thay đổi resource do Lab 5 quản lý. Sau khi học xong, cập nhật Lab 5 Terraform hoặc tắt lại để tránh drift.

## 5. Verify

### 5.1. Bằng CLI

```bash
aws cloudwatch list-dashboards --dashboard-name-prefix csnp-platform
aws cloudwatch describe-alarms --alarm-name-prefix csnp-platform
aws logs tail /ecs/csnp-platform-wallet-api --since 10m
```

### 5.2. Quan sát trên AWS Console

Lab 6 tạo ra các resource về Observability. Để thấy rõ giá trị, anh cần xem trực tiếp trên giao diện AWS:

**1. Xem Dashboard (Biểu đồ tổng quan)**
*   Vào AWS Console, tìm dịch vụ **CloudWatch** > chọn mục **Dashboards** (menu bên trái).
*   Click vào dashboard `csnp-platform-lab06`.
*   Anh sẽ thấy các widget biểu đồ hiển thị: CPU/Memory của ECS và trạng thái Healthy Hosts / lỗi 5xx của ALB. Đây là nơi dùng để theo dõi "sức khỏe" hệ thống hàng ngày.

**2. Xem Alarms (Cảnh báo tự động)**
*   Vào **CloudWatch** > **All alarms**.
*   Anh sẽ thấy 4 alarms vừa được Terraform tạo ra:
    *   `csnp-platform-ecs-cpu-high`: Cảnh báo khi CPU > 70%
    *   `csnp-platform-ecs-memory-high`: Cảnh báo khi RAM > 75%
    *   `csnp-platform-alb-5xx`: Cảnh báo khi API báo lỗi (HTTP 5xx) từ 5 lần trở lên
    *   `csnp-platform-healthy-hosts-low`: Cảnh báo khi số lượng ECS container còn sống < 1
*   Trạng thái ban đầu có thể là `INSUFFICIENT_DATA` (nếu chưa có traffic/data). Khi hệ thống chạy ổn, nó sẽ là `OK`. Khi vượt ngưỡng, nó đổi thành màu đỏ `ALARM` và kích hoạt gửi email qua SNS.

**3. Xem Logs và Metric Filters**
*   Vào **CloudWatch** > menu bên trái, cuộn xuống phần **Logs** > chọn **Log Management** (hoặc Log groups tùy theo hiển thị mới).
*   Tìm group `/ecs/csnp-platform-wallet-api` và click vào. Đây là nơi chứa log do ứng dụng bắn ra.
*   Chuyển sang tab **Metric filters** bên trong Log group đó, anh sẽ thấy filter `csnp-platform-application-errors`. AWS sẽ tự động quét log, nếu thấy chữ "ERROR" hoặc "Exception", nó sẽ cộng 1 vào metric để báo động (alarm).

**4. Xem Container Insights**
*   Vào **CloudWatch** > menu bên trái, tìm phần **Infrastructure Monitoring** (chọn Container Insights nếu có ở trong đó). 
*   *Mẹo nhanh:* Trên giao diện mới của AWS, cách nhanh nhất là anh bấm vào ô **Search [Alt+S]** ở trên cùng, gõ chữ `Container Insights` rồi click vào kết quả hiện ra.
*   Chọn cluster `csnp-platform-cluster`.
*   Tính năng này cung cấp các metric cực kỳ chi tiết sâu xuống mức Task và Container (như Network Rx/Tx, Storage) mà anh không cần phải tự cấu hình hay vẽ biểu đồ.
