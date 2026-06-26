# Lab 3B - Verification Checklist

## Sau mỗi Step, verify kết quả bằng CLI

---

## ✅ Verify Step 1 — VPC tạo thành công

Chạy:

```bash
aws ec2 describe-vpcs --vpc-ids $TEST_VPC_ID
```

Kỳ vọng output:

```json
{
    "Vpcs": [
        {
            "VpcId": "vpc-...",
            "CidrBlock": "10.20.0.0/16",
            "State": "available",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "csnp-cli-test-vpc"
                }
            ]
        }
    ]
}
```

**Checklist:**
- [ ] `State` = `available`
- [ ] `CidrBlock` = `10.20.0.0/16`
- [ ] Tag `Name` = `csnp-cli-test-vpc`
- [ ] `VpcId` khác `10.10.0.0/16` VPC từ Lab 3A (nên bắt đầu bằng `vpc-`, không bằng CIDR)

---

## ✅ Verify Step 2 — Subnet tạo thành công

Chạy:

```bash
aws ec2 describe-subnets --subnet-ids $TEST_SUBNET_ID
```

Kỳ vọng:

```json
{
    "Subnets": [
        {
            "SubnetId": "subnet-...",
            "VpcId": "vpc-...",
            "CidrBlock": "10.20.1.0/24",
            "AvailabilityZone": "us-east-1a",
            "State": "available",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "csnp-cli-test-subnet"
                }
            ]
        }
    ]
}
```

**Checklist:**
- [ ] `VpcId` match `$TEST_VPC_ID`
- [ ] `CidrBlock` = `10.20.1.0/24`
- [ ] `AvailabilityZone` = `us-east-1a`
- [ ] `State` = `available`
- [ ] Tag `Name` = `csnp-cli-test-subnet`

---

## ✅ Verify Step 3A — Route Table tạo thành công

Chạy:

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID
```

Kỳ vọng:

```json
{
    "RouteTables": [
        {
            "RouteTableId": "rtb-...",
            "VpcId": "vpc-...",
            "Routes": [
                {
                    "DestinationCidrBlock": "10.20.0.0/16",
                    "GatewayId": "local",
                    "State": "active"
                }
            ],
            "Associations": []
        }
    ]
}
```

**Checklist:**
- [ ] `VpcId` match `$TEST_VPC_ID`
- [ ] `Routes` chỉ có 1 route: `local`
- [ ] `Associations` trống (vì chưa associate với subnet)
- [ ] `State` của route = `active`

---

## ✅ Verify Step 3B — Route Table Associate thành công

Chạy:

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Associations"
```

Kỳ vọng:

```json
[
    {
        "RouteTableAssociationId": "rtbassoc-...",
        "SubnetId": "subnet-...",
        "Main": false,
        "AssociationState": {
            "State": "associated"
        }
    }
]
```

**Checklist:**
- [ ] `SubnetId` match `$TEST_SUBNET_ID`
- [ ] `State` = `associated`
- [ ] `Main` = `false` (không phải Main Route Table)
- [ ] `RouteTableAssociationId` match `$TEST_RT_ASSOC_ID` (lưu từ bước tạo)

---

## ✅ Verify Step 4 — Cleanup hoàn tất

Sau khi chạy delete commands, verify VPC đã xoá:

```bash
aws ec2 describe-vpcs --vpc-ids $TEST_VPC_ID 2>&1
```

Kỳ vọng lỗi:

```
An error occurred (InvalidVpcID.NotFound) when calling the DescribeVpcs operation: 
The vpc ID 'vpc-...' does not exist
```

**Checklist:**
- [ ] Output có chứa `does not exist` → VPC đã xoá thành công
- [ ] Hoặc chạy query tất cả VPC, không thấy `10.20.0.0/16` nữa:

```bash
aws ec2 describe-vpcs --query "Vpcs[?CidrBlock=='10.20.0.0/16']"
```

Output: `[]` (empty list) → VPC test đã xoá sạch.

---

## 🔍 Troubleshooting Verification

### Verify không thấy resource (mất ID)

Nếu `$TEST_VPC_ID` trống, query lại:

```bash
# Tìm VPC theo CIDR
aws ec2 describe-vpcs --filters "Name=cidr-block,Values=10.20.0.0/16" \
  --query "Vpcs[0].VpcId"
```

### Verify associationID

Nếu mất `$TEST_RT_ASSOC_ID` khi cleanup, lấy lại:

```bash
aws ec2 describe-route-tables --route-table-ids $TEST_RT_ID \
  --query "RouteTables[0].Associations[0].RouteTableAssociationId" \
  --output text
```

### Verify permission

Nếu error `UnauthorizedOperation`, check credential:

```bash
aws sts get-caller-identity
```

---

## Summary

Hoàn thành hết checklist trên = Lab 3B done! 🎉
