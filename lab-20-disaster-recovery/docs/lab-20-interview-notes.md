# Lab 20 - Interview Notes

## RPO và RTO

RPO là mức dữ liệu có thể mất theo thời gian. RTO là thời gian tối đa để khôi phục dịch vụ.

## Backup không phải DR

Backup là một capability. DR còn gồm hạ tầng, identity, network, DNS, dependency, runbook, people và test.

## Pilot light, warm standby, active-active

Chi phí và RTO tăng dần. Chọn theo business impact, không mặc định active-active.

## Restore test

Backup chưa từng restore chỉ là giả thuyết. Drill phải đo thời gian, integrity và application usability.
