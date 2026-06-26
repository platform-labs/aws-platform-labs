# Deliberate Practice Standard for AWS Labs

Mục tiêu của bộ lab không phải hoàn thành checklist một lần, mà là hình thành mental model đủ chắc để tự dự đoán AWS sẽ làm gì, lỗi nằm ở đâu và resource nào đang tính tiền.

## Learning loop bắt buộc

Mỗi lab được luyện theo tám phần:

1. **Mental model** — vẽ kiến trúc, traffic path, identity path và dependency trước khi thao tác.
2. **Console discovery** — tìm đúng màn hình và map các field với resource/API. Không nhất thiết tạo resource bằng Console.
3. **Implementation** — dùng phương thức chính của lab: Console, CLI, Terraform, GitOps hoặc design exercise.
4. **CLI verification** — query trạng thái thật từ AWS API; không chỉ tin màn hình xanh trên Console.
5. **Failure drill** — chủ động tạo một lỗi an toàn, quan sát symptom, tìm root cause và phục hồi.
6. **Rebuild without guide** — cleanup rồi dựng lại chỉ bằng architecture, expected outputs và trí nhớ.
7. **Cleanup and cost audit** — xóa theo dependency order và kiểm tra resource/billing còn sót.
8. **Interview recap** — tự trả lời bảy câu nền tảng bằng lời của mình.

## Năm lượt luyện

| Lượt | Được xem gì? | Mục tiêu |
| --- | --- | --- |
| 1 — Guided | Toàn bộ hands-on | Hiểu resource và luồng hoạt động |
| 2 — Assisted | Architecture + command verification | Tự nhớ thứ tự triển khai |
| 3 — Recall | Chỉ README và expected outputs | Tự dựng và tự debug |
| 4 — Failure | Chỉ failure drill | Nhận diện symptom và root cause |
| 5 — Teach-back | Không xem tài liệu | Giải thích lại và demo cho người khác |

Không chuyển lab thành “mastered” nếu mới hoàn thành lượt 1.

## Bảy câu phải trả lời được

1. Service này giải quyết vấn đề gì?
2. Vì sao không dùng một service đơn giản hơn?
3. Traffic đi từ đâu tới đâu?
4. Identity nào được phép làm gì?
5. Một dependency hỏng thì symptom xuất hiện ở đâu?
6. Service scale và failover như thế nào?
7. Resource nào vẫn tính tiền khi không có traffic?

## Console usage

- Lab 1–3 dùng Console/CLI để tạo resource vì mục tiêu là học resource và AWS API.
- Lab 4–20 dùng IaC/GitOps/design artifact làm implementation chính.
- Console ở Lab 4–20 dùng để discovery, map HCL với AWS UI, quan sát deployment, metric, event và failure.
- Không dựng hai stack giống nhau chỉ để “đủ Console + Terraform”, đặc biệt với NAT, ALB, Aurora, EKS, MQ và MSK.

## Lab completion record

Sau mỗi lượt, ghi lại:

```text
Date:
Lab:
Attempt:
Time to healthy:
Failure encountered:
Root cause:
CLI commands remembered:
Cleanup verified:
What I can now explain without notes:
```

## Definition of Done

Một lab được xem là đã ngấm khi:

- tự vẽ đúng architecture và trust boundary;
- dự đoán gần đúng `terraform plan` hoặc API sequence;
- verify được bằng CLI;
- hoàn thành failure drill và recovery;
- rebuild không nhìn step-by-step;
- cleanup không để lại resource tính phí;
- trả lời được bảy câu nền tảng.
