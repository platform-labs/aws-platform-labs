# Lab 10 - Interview Notes

## Managed node group quản lý gì?

AWS quản lý lifecycle integration và rolling update của Auto Scaling Group, nhưng team vẫn sở hữu Kubernetes version compatibility, capacity, daemonsets và workload disruption.

## Control plane public endpoint có nghĩa node public?

Không. API endpoint exposure và node subnet/public IP là hai quyết định khác nhau. Lab đặt nodes ở private subnets và giới hạn public API CIDR.

## HPA cần gì?

Metrics source, resource requests và workload có thể scale ngang. HPA không thay Cluster Autoscaler/Karpenter; nếu node hết capacity, pod vẫn Pending.

## Ingress tự tạo ALB không?

Chỉ khi AWS Load Balancer Controller đang chạy với IAM permissions đúng. Ingress resource tự nó không điều khiển AWS API.
