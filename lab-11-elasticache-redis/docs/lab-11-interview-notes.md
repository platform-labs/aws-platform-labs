# Lab 11 - Interview Notes

## Cache-aside

App đọc cache trước, miss thì đọc database rồi ghi cache. App sở hữu invalidation; stale data là trade-off phải thiết kế.

## Multi-AZ và cluster mode

Multi-AZ tăng availability qua replica/failover. Cluster mode sharding dữ liệu để tăng capacity; hai khái niệm độc lập.

## Distributed lock có an toàn tuyệt đối?

Không. Cần expiry, owner token, fencing token và hiểu failure model. Với ledger, database constraints/idempotency vẫn là nguồn bảo vệ chính.
