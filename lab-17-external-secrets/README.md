# Lab 17 - External Secrets Operator

## Mục tiêu

Đồng bộ secret từ AWS Secrets Manager vào Kubernetes bằng External Secrets Operator (ESO), sử dụng IRSA thay vì static AWS keys.

## Requires / Produces

- Requires: Lab 16, EKS OIDC provider và secret Lab 6.
- Produces: least-privilege IAM role, ClusterSecretStore và ExternalSecret.

## Security boundary

ESO tạo Kubernetes Secret; dữ liệu vẫn tồn tại trong etcd. EKS envelope encryption, RBAC, audit và namespace boundary vẫn bắt buộc.

## Cleanup

Xóa ExternalSecret/SecretStore trước IAM role. Không xóa source secret nếu còn consumer khác.

## Trạng thái

Code-ready, chưa apply.
