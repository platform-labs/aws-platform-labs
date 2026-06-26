# Lab 16 - GitOps với Argo CD

## Mục tiêu

Cài Argo CD trên EKS Lab 10 và để Git trở thành desired state cho Wallet API.

## Requires / Produces

- Requires: Lab 10.
- Produces: Argo CD installation runbook, AppProject và Application manifests.

## Flow

```text
Git commit -> Argo CD reconcile -> Kubernetes desired state
                         drift -> detect / self-heal
```

## Guardrail

Lab mặc định automated prune/self-heal cho namespace `wallet` trong cluster lab. Không trỏ Application vào production cluster/repository.

## Thực hành

Xem [hands-on](docs/lab-16-hands-on.md), thay `REPLACE_REPOSITORY_URL` và path trước khi apply.

## Cleanup

Xóa Application trước, sau đó uninstall Argo CD. Kiểm tra ALB/LoadBalancer service đã được dọn.

## Trạng thái

Code-ready, chưa apply.
