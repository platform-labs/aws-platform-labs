# Lab 17 - Interview Notes

## ESO có loại bỏ Kubernetes Secret?

Không. ESO tự động hóa đồng bộ; target thường vẫn là Kubernetes Secret. CSI driver là lựa chọn khác khi muốn mount trực tiếp.

## IRSA trust policy

Phải giới hạn đúng OIDC issuer, audience `sts.amazonaws.com`, namespace và service account subject.

## Rotation

Source rotation chỉ hữu ích nếu ESO refresh và ứng dụng reload secret/reconnect đúng cách.
