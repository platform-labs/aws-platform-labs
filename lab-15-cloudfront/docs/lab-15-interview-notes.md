# Lab 15 - Interview Notes

## Cache key

Cache key quyết định request nào dùng chung object, thường dựa path/query/header/cookie. Key quá rộng gây data leak; quá hẹp làm hit ratio thấp.

## Origin request policy khác cache policy

Cache policy quyết định cache key/TTL. Origin request policy quyết định dữ liệu forwarded tới origin nhưng không nhất thiết nằm trong cache key.

## CloudFront certificate region

Viewer certificate phải ở `us-east-1`, kể cả origin/ALB ở region khác.
