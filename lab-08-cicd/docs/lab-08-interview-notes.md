# Lab 08 - Interview Notes

## OIDC tốt hơn access key thế nào?

GitHub nhận token ngắn hạn, AWS kiểm tra issuer/audience/subject rồi cấp STS credentials tạm thời. Không có secret AWS dài hạn để rotate hoặc bị leak.

## Vì sao tag bằng commit SHA?

SHA tạo liên kết bất biến giữa source, image và deployment. `latest` có thể trỏ sang nội dung khác mà task definition không đổi.

## CI khác CD?

CI xác minh thay đổi qua restore/test/build. CD xuất bản artifact và triển khai môi trường. Có thể yêu cầu approval environment giữa hai bước.

## Rollback ECS

Rollback là đăng ký/deploy task definition revision tốt trước đó; image tag bất biến giúp revision thật sự tái lập được.
