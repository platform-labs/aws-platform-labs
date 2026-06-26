# Lab 15 - CloudFront

## Mục tiêu

Đặt CloudFront trước HTTPS ALB, ép HTTPS, hiểu cache key, TTL và origin protection.

## Requires / Produces

- Requires: Lab 14.
- Produces: CloudFront distribution trỏ ALB origin.

## Thiết kế lab

Default behavior dùng managed `CachingDisabled` vì Wallet API là dynamic. Một cache behavior `/public/*` dùng `CachingOptimized` để minh họa edge caching an toàn cho public content.

## Cost guardrail

CloudFront tính data transfer/request; invalidation ngoài quota miễn phí có thể phát sinh phí.

## Cleanup

Distribution phải disable trước khi AWS cho delete; `terraform destroy` có thể mất vài phút.

## Trạng thái

Code-ready, chưa apply.
