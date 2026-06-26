# Lab 19 - Hands-on Design Exercise

## Deliberate practice loop

1. **Mental model:** vẽ Organization root → OUs → accounts → SCP/identity/resource policies và centralized security services.
2. **Console discovery:** chỉ xem Organizations/Control Tower trong sandbox hoặc read-only; không thay organization thật.
3. **Implementation:** tạo OU/account ownership matrix, guardrail catalog và account-vending workflow trên giấy/code.
4. **CLI verification:** validate policy JSON và dùng simulator/read-only queries khi có sandbox organization.
5. **Failure drill:** review một SCP quá rộng có thể khóa admin/global services; viết exception/recovery path.
6. **Rebuild without guide:** từ yêu cầu dev/UAT/pro/security, tự thiết kế landing zone.
7. **Cleanup/cost audit:** không có resource lab; xóa account IDs/email nhạy cảm khỏi artifact.
8. **Interview recap:** giải thích account boundary, OU, SCP “does not grant” và delegated admin.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## 1. Define account boundaries

Tạo bảng cho account owner, billing owner, data classification, region policy, break-glass và log retention.

## 2. Central capabilities

- Organization CloudTrail -> immutable Log Archive.
- GuardDuty/Security Hub delegated admin.
- Central IAM Identity Center.
- Network account sở hữu Transit Gateway/egress nếu architecture cần.

## 3. SCP simulation

Review policy samples bằng IAM Access Analyzer/Organizations policy simulator trong sandbox organization. SCP không cấp quyền; nó chỉ giới hạn maximum permission.

## 4. Account vending

Định nghĩa workflow có approval, baseline stack, budget, contacts, tags và decommission runbook trước khi dùng Control Tower Account Factory.
