# Lab 09.5 - Interview Notes

## ADR tốt cần gì?

Context, decision drivers, lựa chọn, consequences, alternatives và trigger xem xét lại. ADR ghi “vì sao” chứ không thay runbook triển khai.

## ECS hay EKS không phải câu hỏi tuyệt đối

Quyết định phụ thuộc workload, quy mô tổ chức, kỹ năng, compliance và total cost of ownership. Câu trả lời senior phải nêu trade-off và điều kiện thay đổi quyết định.

## Portability có miễn phí?

Không. Kubernetes API giúp chuẩn hóa orchestrator nhưng ứng dụng vẫn phụ thuộc IAM, DNS, database, queue, observability và networking của cloud.
