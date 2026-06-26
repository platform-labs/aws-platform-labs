# AWS Lab 03 - Verification Commands

## Verify Route Tables

### List all Route Tables in VPC

```bash
aws ec2 describe-route-tables   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query "RouteTables[*].[RouteTableId,Tags[?Key=='Name']|[0].Value]"   --output table
```

---

### Audit Route Tables, Routes, Associations

```bash
aws ec2 describe-route-tables   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query '
RouteTables[*].{
Name:Tags[?Key==`Name`]|[0].Value,
RouteTableId:RouteTableId,
Associations:Associations[*].SubnetId,
Routes:Routes[*].[DestinationCidrBlock,GatewayId,NatGatewayId]
}'   --output json
```

---

### Audit Route Tables (human readable)

```bash
aws ec2 describe-route-tables   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query '
RouteTables[*].{
Name:Tags[?Key==`Name`]|[0].Value,
Main:Associations[?Main==`true`]|[0].Main,
Subnets:Associations[*].SubnetId,
Routes:Routes[*].DestinationCidrBlock
}'   --output yaml
```

---

### Verify Public Route Table

Expected:

- 10.10.0.0/16 -> local
- 0.0.0.0/0 -> IGW

```bash
aws ec2 describe-route-tables   --route-table-ids rtb-033232ffa2235e534   --output json
```

---

### Verify Private Data Route Table

Expected:

- 10.10.0.0/16 -> local
- No 0.0.0.0/0 route

```bash
aws ec2 describe-route-tables   --route-table-ids rtb-0838703dd1c3f1c8a   --query '
RouteTables[*].{
Name:Tags[?Key==`Name`]|[0].Value,
Subnets:Associations[*].SubnetId,
Routes:Routes[*].DestinationCidrBlock
}'   --output yaml
```

---

## Verify Security Groups

### List Security Groups in Lab VPC

```bash
aws ec2 describe-security-groups   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query "SecurityGroups[*].[GroupName,GroupId,VpcId]"   --output table
```

---

### Audit Security Group Rules

```bash
aws ec2 describe-security-groups   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query '
SecurityGroups[*].{
Name:GroupName,
Id:GroupId,
Ingress:IpPermissions
}'   --output yaml
```

---

### Verify Security Group Chain

Expected:

ALB SG
80 -> 0.0.0.0/0

ECS SG
5000 -> ALB SG

RDS SG
5432 -> ECS SG

Test EC2 SG
22 -> My IP

```bash
aws ec2 describe-security-groups   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query '
SecurityGroups[*].{
Name:GroupName,
InboundPorts:IpPermissions[*].FromPort,
SourceCidrs:IpPermissions[*].IpRanges[*].CidrIp,
SourceSGs:IpPermissions[*].UserIdGroupPairs[*].GroupId
}'   --output yaml
```

---

### Verify Security Group Descriptions

```bash
aws ec2 describe-security-groups   --filters "Name=vpc-id,Values=vpc-08604ddd6aec862c2"   --query '
SecurityGroups[*].{
Name:GroupName,
Description:Description
}'   --output table
```

---

## Verify EC2

### Get Public IP

```bash
aws ec2 describe-instances   --filters "Name=tag:Name,Values=network-test-ec2"   --query "Reservations[*].Instances[*].[PublicIpAddress,State.Name]"   --output table
```

---

### SSH

```bash
ssh-keygen -R <public-ip>

ssh -i "C:\Users\Toan\.ssh\wallet-dev-key.pem" ec2-user@<public-ip>
```

---

### Verify Internet Access

```bash
curl -s https://checkip.amazonaws.com
```

Expected:

Public IP of EC2 instance.

---

### Verify Package Repository Access

```bash
sudo dnf update -y
```

Expected:

Complete!

---

### Verify Instance Metadata

```bash
curl http://169.254.169.254/latest/meta-data/local-ipv4

curl http://169.254.169.254/latest/meta-data/public-ipv4
```

Expected:

Private IP:
10.10.x.x

Public IP:
AWS Public IP

---

## Lab 03 Success Criteria

- SSH successful
- Internet access successful
- Route Tables correct
- Route Table Associations correct
- NAT Gateway route configured
- Private Data subnet isolated
- Security Group chain correct
- EC2 outbound traffic successful
