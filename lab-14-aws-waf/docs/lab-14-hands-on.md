# Lab 14 - Hands-on

## Deliberate practice loop

1. **Mental model:** request → Web ACL priority → managed/rate rule → allow/block → ALB.
2. **Console discovery:** xem rule order, sampled requests, metrics và association.
3. **Implementation:** apply Web ACL, bắt đầu với endpoint lab và rule set đã định.
4. **CLI verification:** get Web ACL/association và tạo request chứng minh allow/block.
5. **Failure drill:** trigger managed rule và rate rule; tìm false positive rồi thử count-mode reasoning.
6. **Rebuild without guide:** tự tạo baseline managed rules + rate limit mà không làm hỏng health check.
7. **Cleanup/cost audit:** destroy association/ACL và kiểm tra logging destination nếu đã bật.
8. **Interview recap:** giải thích WAF không thay authentication, validation hay tenant-level rate limiting.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

Apply với ALB ARN của Lab 13. Test:

```bash
curl -i "https://api-dev.csnp.xyz/?q=%3Cscript%3Ealert(1)%3C/script%3E"
```

Gửi burst vượt `rate_limit` từ môi trường lab, sau đó xem WAF sampled requests và CloudWatch metrics.

Không coi WAF là thay thế input validation, authentication, authorization hoặc application rate limiting theo tenant/user.
