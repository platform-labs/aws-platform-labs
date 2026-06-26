# Lab 14 - Interview Notes

## Managed rules có đủ không?

Không. Chúng giảm common exploit traffic nhưng cần tuning/exclusions, app security và threat model riêng.

## Rate-based rule đếm theo gì?

Lab dùng source IP trong rolling window. NAT/shared proxy có thể gom nhiều user vào một IP; application-level identity rate limit vẫn cần.

## Count mode

Cho quan sát match mà không block, rất hữu ích khi rollout để đánh giá false positives.
