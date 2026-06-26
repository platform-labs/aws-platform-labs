# Lab 13 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ DNS query → Route 53 alias → ALB listener → target và ACM DNS validation.
2. **Console discovery:** xem hosted zone, certificate validation records và listeners sau apply.
3. **Implementation:** apply certificate, validation, HTTPS listener và alias record.
4. **CLI verification:** dùng `dig/nslookup`, ACM/Route53/ELB describe và `openssl s_client`.
5. **Failure drill:** dùng sai hosted zone/record/listener SG từng lỗi một và phân biệt DNS với TLS failure.
6. **Rebuild without guide:** từ domain + ALB outputs, tự đưa endpoint tới HTTPS healthy.
7. **Cleanup/cost audit:** xóa DNS/listener trước certificate; không đụng record production ngoài scope.
8. **Interview recap:** giải thích alias vs CNAME, certificate region và DNS propagation.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Verify:

```bash
dig api-dev.csnp.xyz
curl -Iv https://api-dev.csnp.xyz/health
openssl s_client -connect api-dev.csnp.xyz:443 -servername api-dev.csnp.xyz
```

Security group ALB phải cho inbound 443. Lab 4 hiện chỉ mở port 80; cập nhật tại state sở hữu SG trước khi test HTTPS.
