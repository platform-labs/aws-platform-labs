# Lab 13 - Interview Notes

## Vì sao ACM certificate phải cùng region ALB?

Regional services như ALB dùng certificate cùng region. CloudFront là ngoại lệ: certificate viewer phải ở `us-east-1`.

## Alias record khác CNAME?

Route 53 alias có thể trỏ root/apex tới AWS resource và không tính DNS query theo cách CNAME thông thường; record vẫn là A/AAAA.

## DNS validation

ACM kiểm tra CNAME chứng minh quyền kiểm soát domain và có thể tự renew khi record còn tồn tại và certificate còn được dùng.
