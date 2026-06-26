# Lab 13 - Route 53 + ACM + HTTPS

## Mục tiêu

Phát hành ACM certificate bằng DNS validation, tạo HTTPS listener cho ALB và route `api-dev.csnp.xyz`.

## Requires / Produces

- Requires: Lab 5 ALB/target group và Route 53 public hosted zone.
- Produces: validated certificate, HTTPS listener, HTTP redirect và DNS alias.

## Guardrail

Không apply vào hosted zone production nếu chưa được owner phê duyệt. Dùng subdomain lab/dev.

## Cleanup

Terraform có thể xóa certificate sau khi listener được xóa. DNS propagation không tức thời.

## Trạng thái

Code-ready, chưa apply.
