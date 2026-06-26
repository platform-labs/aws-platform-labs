# Lab 10 - Amazon EKS

## Mục tiêu

Tạo EKS cluster + managed node group trong private app subnets và deploy Wallet API bằng Deployment, Service, Ingress, HPA.

## Requires / Produces

- Requires: ADR Lab 9.5, VPC/subnet Lab 4.
- Produces: EKS cluster, managed node group và Kubernetes manifests mapping từ ECS.

## Mapping

| ECS | Kubernetes |
| --- | --- |
| ECS Cluster | EKS cluster |
| Task Definition | Pod template |
| ECS Service | Deployment + Service |
| ALB listener/target group | Ingress |
| Application Auto Scaling | HPA |

## Cost guardrail

EKS control plane, EC2 nodes, NAT và load balancer đều tính phí. `desired_size=2` chỉ dùng trong buổi lab; destroy ngay sau khi hoàn tất.

## Thực hành

Xem [hands-on](docs/lab-10-hands-on.md). AWS Load Balancer Controller chưa được tự động cài trong Terraform để người học hiểu rõ IRSA/add-on boundary; manifest Ingress chỉ hoạt động sau khi controller được cài.

## Cleanup

Xóa Ingress/Service trước để controller dọn ALB, rồi `terraform destroy`.

## Trạng thái

Code-ready, chưa apply.
