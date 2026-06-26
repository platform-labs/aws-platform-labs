# Lab 15 - Hands-on

## Deliberate practice loop

1. **Mental model:** viewer request → cache key → edge hit/miss → origin request → response TTL.
2. **Console discovery:** xem distribution, origins, cache behaviors và invalidations.
3. **Implementation:** apply distribution với dynamic API disabled-cache và `/public/*` optimized-cache.
4. **CLI verification:** get distribution config và dùng `curl -I` đọc `X-Cache`/`Age`.
5. **Failure drill:** thay object nhưng chưa invalidation hoặc cấu hình cache key sai; giải thích stale/data-leak risk.
6. **Rebuild without guide:** tự chọn behavior/TTL/methods cho dynamic và public content.
7. **Cleanup/cost audit:** disable/delete distribution; kiểm tra invalidation và data transfer.
8. **Interview recap:** giải thích cache policy, origin request policy và certificate region.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

Apply với `origin_domain_name` là ALB DNS hoặc domain Lab 13.

Verify:

```bash
curl -I "https://$(terraform output -raw distribution_domain_name)/health"
curl -I "https://$(terraform output -raw distribution_domain_name)/public/version.json"
```

Quan sát `X-Cache`, `Age`, cache hit ratio. Không cache response cá nhân hóa nếu cache key không chứa identity phù hợp; tốt nhất dynamic authenticated API để caching disabled.

Production nên hạn chế bypass CloudFront bằng custom origin header/WAF rule hoặc origin-facing controls.
