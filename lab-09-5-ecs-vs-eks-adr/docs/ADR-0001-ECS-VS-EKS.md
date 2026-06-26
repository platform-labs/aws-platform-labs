# ADR-0001: ECS Fargate hay EKS cho CSNP

- Status: Proposed
- Date: 2026-06-24
- Decision owners: Platform, Security, Application Architecture

## Context

CSNP hiện cần chạy nhiều HTTP API và background worker trên AWS. Team đã có kinh nghiệm Kubernetes on-premises nhưng AWS platform mới đang được xây dựng. Mục tiêu gần hạn là production-ready với blast radius nhỏ, least privilege, quan sát được và chi phí vận hành hợp lý.

## Decision drivers

| Driver | Trọng số | ECS Fargate | EKS |
| --- | ---: | ---: | ---: |
| Time-to-production | 5 | 5 | 3 |
| Operational simplicity | 5 | 5 | 2 |
| Workload portability | 3 | 2 | 5 |
| Ecosystem/extensibility | 3 | 3 | 5 |
| Fine-grained platform APIs | 3 | 3 | 5 |
| Cost at current scale | 4 | 4 | 2 |
| Existing CSNP skills | 3 | 3 | 4 |
| Weighted total |  | **86** | **76** |

Điểm là giả định ban đầu, phải cập nhật bằng dữ liệu của team.

## Decision

Chọn **ECS Fargate cho production đầu tiên**. EKS được duy trì như migration option và learning track, không phải dependency để CSNP production-ready.

## Rationale

- ECS loại bỏ control-plane/add-on/node lifecycle khỏi critical path.
- Fargate phù hợp workload stateless hiện tại và giảm patching.
- IAM task role, ALB, CloudWatch, Secrets Manager tích hợp trực tiếp.
- Team có thể tập trung SLO, security và delivery trước khi xây internal Kubernetes platform.

## Consequences

### Positive

- Ít moving parts, nhanh đạt baseline vận hành.
- Chi phí control plane và add-on thấp hơn ở quy mô hiện tại.
- Blast radius và ownership dễ giải thích.

### Negative

- Tăng phụ thuộc AWS-specific APIs.
- Không dùng trực tiếp Helm/operator/service mesh ecosystem.
- Một số workload đặc thù có thể cần EC2 capacity provider hoặc nền tảng khác.

## Khi nào xem xét lại EKS?

Mở lại ADR khi ít nhất một trigger xảy ra:

- cần operator/CRD hoặc scheduling capability ECS không đáp ứng;
- số service/team khiến platform API chuẩn Kubernetes tạo giá trị rõ;
- yêu cầu portability được tài trợ và đo lường;
- có đội sở hữu EKS control plane, upgrades, add-ons, policy và on-call;
- TCO 12 tháng cho thấy EKS tốt hơn sau khi tính cả engineering time.

## Migration strategy

1. Chuẩn hóa container contract: health endpoint, graceful shutdown, logs stdout, config/secret injection.
2. Giữ app stateless; database/cache/message broker dùng managed services.
3. Dùng OpenTelemetry và deployment metadata độc lập orchestrator.
4. Lab 10 mapping ECS service sang Deployment/Service/Ingress/HPA.
5. Pilot một service ít rủi ro; đo cost, lead time, incidents.
6. Chỉ migrate theo service, không big-bang.

## Rejected alternatives

- EKS ngay lập tức: tăng operational surface trước khi có nhu cầu đủ mạnh.
- Tự quản Kubernetes trên EC2: undifferentiated heavy lifting, không phù hợp mục tiêu lab/platform.
- ECS EC2 launch type mặc định: thêm node management khi Fargate đã đáp ứng workload hiện tại.
