# Lab 09.5 - Deliberate Practice

## 1. Mental model

Viết decision drivers trước khi đọc ADR mẫu: workload shape, team skill, operations, compliance, portability, cost và migration reversibility.

## 2. Console discovery

Không tạo resource. Xem ECS/EKS pricing, service quotas và operational surfaces để thu thập evidence; không chọn công nghệ từ cảm giác.

## 3. Implementation

Copy ADR sang một file nháp mới, xóa phần Decision/Rationale, rồi tự điền context, alternatives, matrix và consequences.

## 4. CLI verification

Dùng AWS CLI thu thập dữ liệu hiện hữu như số ECS services, task definitions, EKS clusters và account quotas nếu có. Evidence phải được ghi ngày thu thập.

## 5. Failure drill

Đưa vào một scenario làm quyết định hiện tại yếu đi, ví dụ cần CRD/operator hoặc team không có Kubernetes on-call. Xác định decision trigger có buộc mở lại ADR không.

## 6. Rebuild without guide

Viết ADR ECS vs EKS từ blank page trong 30 phút, sau đó mới diff với [`ADR-0001-ECS-VS-EKS.md`](./ADR-0001-ECS-VS-EKS.md).

## 7. Cleanup and cost audit

Không có resource để cleanup. Xóa dữ liệu account nhạy cảm khỏi notes và giữ assumptions/cost calculations có nguồn.

## 8. Interview recap

Trình bày quyết định trong 5 phút: “Why ECS today, when EKS tomorrow?”, gồm cả điều kiện khiến mình đổi ý.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).
