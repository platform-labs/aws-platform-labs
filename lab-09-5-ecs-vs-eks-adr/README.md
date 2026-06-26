# Lab 09.5 - ECS vs EKS Architecture Decision

## Mục tiêu

Ra quyết định có bằng chứng cho CSNP thay vì chọn Kubernetes theo xu hướng.

## Requires / Produces

- Requires: Lab 9 và kinh nghiệm vận hành ECS từ Lab 5–8.
- Produces: [ADR-0001 ECS vs EKS](docs/ADR-0001-ECS-VS-EKS.md).

## Cách làm

1. Điền số liệu thật: số service, kỹ năng team, SLO, compliance, chi phí ước tính.
2. Chấm lại decision matrix.
3. Review ADR với application, platform và security owners.
4. Chỉ đổi trạng thái ADR từ `Proposed` sang `Accepted` sau review.

Thực hành nhiều vòng theo [hands-on](docs/lab-09-5-hands-on.md); lượt rebuild phải viết ADR từ blank page trước khi so với bản mẫu.

## Không có Terraform

Đây là architecture lab. Artifact chính là quyết định có context, trade-off, trigger xem xét lại và migration strategy.

## Trạng thái

ADR draft hoàn chỉnh, cần team review.
