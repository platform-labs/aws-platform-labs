# PRACTICE_SCHEDULE.md — Thứ tự thực hành Labs

> Nguyên tắc cốt lõi:
> - **Nhóm lab theo infrastructure dùng chung** → tránh apply/destroy Lab 4+5 nhiều lần thừa.
> - **Mỗi session: apply → làm hết lab trong session → destroy ngay trong ngày**.
> - NAT Gateway, RDS, Aurora, EKS **không để chạy qua đêm**.
> - Mỗi lần rebuild Lab 4+5 = deliberate practice thêm 1 lượt — đây là điều tốt, không phải lãng phí.

---

## Dependency nhanh

```
Lab 4 output  →  Lab 5, Lab 9, Lab 10, Lab 11, Lab 12A, Lab 12B cần
Lab 5 output  →  Lab 6, Lab 7, Lab 8, Lab 13, Lab 14 cần
Lab 10 output →  Lab 16, Lab 17, Lab 18 cần
```

---

## SESSION 1 — ECS Operations Stack

**Infrastructure:** Lab 4 + Lab 5  
**Cost:** ~$0.08/hr | **Deadline:** Destroy trong ngày  
**Labs:** 4 → 5 → 6 → 7 → 8

### Bước 1 — Apply Lab 4

```bash
cd lab-04-terraform-platform-foundation/terraform

# Lấy IP hiện tại
curl -s https://checkip.amazonaws.com

# Tạo tfvars (không commit file này)
cp terraform.tfvars.example terraform.tfvars
# Điền: my_ip_cidr = "<IP>/32", key_pair_name = "<tên key pair>"

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

**Lưu output Lab 4** — dùng cho Lab 5 và các lab cần VPC:

```bash
terraform output
# Copy toàn bộ output vào terraform.tfvars của Lab 5
```

| Output cần lưu | Dùng cho |
|---|---|
| `vpc_id` | Lab 5, 11, 12A, 12B |
| `public_subnet_ids` | Lab 5 (ALB) |
| `private_app_subnet_ids` | Lab 5 (ECS), Lab 10 (EKS) |
| `private_data_subnet_ids` | Lab 5 (RDS), Lab 9 (Aurora), Lab 11 (Redis) |
| `alb_security_group_id` | Lab 5 |
| `ecs_security_group_id` | Lab 5, Lab 11 |
| `rds_security_group_id` | Lab 5, Lab 9 |

### Bước 2 — Apply Lab 5

```bash
cd ../../lab-05-terraform-ecs-platform/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ output Lab 4:
#   vpc_id, public_subnet_ids, private_app_subnet_ids,
#   private_data_subnet_ids, alb_security_group_id,
#   ecs_security_group_id, rds_security_group_id
# Điền thêm:
#   db_password = "..." (hoặc dùng TF_VAR_db_password)
#   container_image = "<account>.dkr.ecr.us-east-1.amazonaws.com/csnp-platform-wallet-api:latest"

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply

# Verify service healthy
terraform output alb_dns_name
curl http://<alb_dns_name>/health
```

**Lưu output Lab 5** — dùng cho Lab 6, 7, 8, 13, 14:

```bash
terraform output
```

| Output cần lưu | Dùng cho |
|---|---|
| `ecs_cluster_name` | Lab 6, Lab 7 |
| `ecs_service_name` | Lab 6, Lab 7 |
| `alb_dns_name` | Lab 13 |
| `ecr_repository_url` | Lab 8 |
| `task_execution_role_arn` | Lab 8 |
| `task_role_arn` | Lab 8 |

**ALB ARN suffix cho Lab 6/14:**

```bash
# ALB ARN suffix (phần từ "app/..." trở đi)
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName,'csnp')].LoadBalancerArn" \
  --output text

# Target Group ARN suffix (phần từ "targetgroup/..." trở đi)
aws elbv2 describe-target-groups \
  --query "TargetGroups[?contains(TargetGroupName,'csnp')].TargetGroupArn" \
  --output text

# ALB zone_id (dùng cho Lab 13 Route53 ALIAS)
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName,'csnp')].CanonicalHostedZoneId" \
  --output text
```

### Bước 3 — Apply Lab 6 (Observability)

```bash
cd ../../lab-06-observability/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền: ecs_cluster_name, ecs_service_name, alb_arn_suffix, target_group_arn_suffix
# Optional: alarm_email = "your@email.com"

terraform init && terraform apply

# Nạp secret ngoài state
aws secretsmanager put-secret-value \
  --secret-id "$(terraform output -raw application_secret_arn)" \
  --secret-string '{"username":"postgres","password":"REPLACE_ME"}'

# Bật Container Insights
aws ecs update-cluster-settings \
  --cluster csnp-platform-cluster \
  --settings name=containerInsights,value=enabled

# Verify
aws cloudwatch describe-alarms --alarm-name-prefix csnp-platform
aws cloudwatch list-dashboards --dashboard-name-prefix csnp-platform
```

### Bước 4 — Apply Lab 7 (Auto Scaling)

```bash
cd ../../lab-07-auto-scaling-resilience/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền: ecs_cluster_name, ecs_service_name (từ Lab 5 output)

terraform init && terraform apply

# Verify scaling policies
aws application-autoscaling describe-scaling-policies \
  --service-namespace ecs
```

### Bước 5 — Apply Lab 8 (CI/CD)

```bash
cd ../../lab-08-cicd/terraform

# Repo hiện tại dùng source app ở lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal
# terraform.tfvars đã được chuẩn bị cho:
#   github_owner      = "platform-labs"
#   github_repository = "aws-platform-labs"
#   github_branch     = "main"
# Nếu fork sang repo khác, sửa 3 giá trị này trước khi apply.

terraform fmt
terraform validate
terraform plan
terraform apply

# Copy các giá trị này sang GitHub Actions repository variables
terraform output github_actions_variables
```

Workflow đã được đặt tại:

```text
.github/workflows/build-test-deploy.yml
```

Các variables cần có trong GitHub Actions:

```text
AWS_ROLE_ARN=arn:aws:iam::289069331511:role/csnp-lab08-github-ecs-deploy
AWS_REGION=us-east-1
ECR_REPOSITORY=csnp-platform-wallet-api
ECS_CLUSTER=csnp-platform-cluster
ECS_SERVICE=csnp-platform-wallet-api-service
ECS_TASK_DEFINITION=lab-08-cicd/task-definition.json
CONTAINER_NAME=wallet-api
```

Push lên `main` và verify pipeline:

```bash
aws ecr describe-images \
  --repository-name csnp-platform-wallet-api \
  --query "sort_by(imageDetails,& imagePushedAt)[-1].{Tags:imageTags,Digest:imageDigest,Pushed:imagePushedAt}"

aws ecs describe-services \
  --cluster csnp-platform-cluster \
  --services csnp-platform-wallet-api-service \
  --query "services[0].{Status:status,Desired:desiredCount,Running:runningCount,TaskDefinition:taskDefinition}"
```

### ⚠️ DESTROY Session 1

**Thứ tự destroy — quan trọng, không làm ngược:**

```bash
# Lab 8
cd lab-08-cicd/terraform && terraform destroy

# Lab 7
cd ../../lab-07-auto-scaling-resilience/terraform && terraform destroy

# Lab 6
cd ../../lab-06-observability/terraform && terraform destroy

# Lab 5 (RDS mất ~5 phút)
cd ../../lab-05-terraform-ecs-platform/terraform && terraform destroy

# Lab 4 (NAT Gateway mất ~2 phút)
cd ../../lab-04-terraform-platform-foundation/terraform && terraform destroy

# Verify không còn resource tính tiền
aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query "NatGateways[*].NatGatewayId"
aws rds describe-db-instances --query "DBInstances[*].DBInstanceIdentifier"
aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerName"
```

---

## SESSION 2 — Aurora (Database Day)

**Infrastructure:** Lab 4 only  
**Cost:** Aurora `db.t4g.medium` ~$0.08/hr — **⚠️ destroy cùng ngày**  
**Labs:** 4 → 9

### Apply Lab 4

*(giống Session 1, bước 1 — lần này không cần nhìn guide)*

### Apply Lab 9 (Aurora)

```bash
cd lab-09-aurora-postgresql/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ Lab 4 output:
#   private_data_subnet_ids, rds_security_group_id

terraform init && terraform apply

# Failover drill
aws rds failover-db-cluster --db-cluster-identifier csnp-lab09-aurora-cluster

# Verify writer/reader endpoint
aws rds describe-db-clusters --db-cluster-identifier csnp-lab09-aurora-cluster \
  --query "DBClusters[0].{Writer:Endpoint,Reader:ReaderEndpoint}"
```

### DESTROY Session 2

```bash
cd lab-09-aurora-postgresql/terraform && terraform destroy
cd ../../lab-04-terraform-platform-foundation/terraform && terraform destroy
```

**Lab 9.5 (ADR):** Làm bất kỳ lúc nào, không cần infra.

---

## SESSION 3 — CSNP Production Services

**Infrastructure:** Lab 4 + Lab 5  
**Cost:** ~$0.12/hr | **Deadline:** Destroy trong ngày  
**Labs:** 4 → 5 → 11, 12A, (12B) → 13 → 14

### Apply Lab 4 → Lab 5

*(giống Session 1 — rebuild từ memory, không nhìn guide)*

### Apply Lab 11 (ElastiCache Redis)

```bash
cd lab-11-elasticache-redis/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ Lab 4: vpc_id, private_data_subnet_ids, ecs_security_group_id

terraform init && terraform apply

# Test Redis connectivity từ ECS task hoặc bastion
aws elasticache describe-replication-groups
```

### Apply Lab 12A (Amazon MQ — Required)

```bash
cd ../../lab-12a-amazon-mq-rabbitmq/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ Lab 4: vpc_id, private_data_subnet_ids

terraform init && terraform apply

# Verify broker
aws mq list-brokers
```

### Apply Lab 12B (MSK Serverless — Optional)

```bash
cd ../../lab-12b-msk-serverless/terraform
terraform init && terraform apply
```

### Apply Lab 13 (Route53 + ACM)

```bash
cd ../../lab-13-route53-acm/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ Lab 5:
#   alb_arn (full ARN), alb_dns_name, alb_zone_id
# Điền thêm:
#   domain_name = "api.csnp.xyz"
#   hosted_zone_id = "<Route53 hosted zone ID>"

terraform init && terraform apply

# Verify DNS + TLS
dig api.csnp.xyz
curl -I https://api.csnp.xyz/health
```

### Apply Lab 14 (AWS WAF)

```bash
cd ../../lab-14-aws-waf/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền: alb_arn (full ARN từ Lab 5)

terraform init && terraform apply

# Test WAF block
aws wafv2 list-web-acls --scope REGIONAL
```

### ⚠️ DESTROY Session 3

```bash
cd lab-14-aws-waf/terraform && terraform destroy
cd ../../lab-13-route53-acm/terraform && terraform destroy
cd ../../lab-12b-msk-serverless/terraform && terraform destroy   # nếu có apply
cd ../../lab-12a-amazon-mq-rabbitmq/terraform && terraform destroy
cd ../../lab-11-elasticache-redis/terraform && terraform destroy
cd ../../lab-05-terraform-ecs-platform/terraform && terraform destroy
cd ../../lab-04-terraform-platform-foundation/terraform && terraform destroy
```

---

## SESSION 4 — EKS + GitOps Track

**Infrastructure:** Lab 4 + Lab 10 (EKS)  
**Cost:** EKS control plane $0.10/hr + EC2 nodes ~$0.04/hr — **⚠️ destroy cùng ngày**  
**Labs:** 4 → 10 → 16 → 17 → 18

### Apply Lab 4

*(lần thứ 3+ — phải thuần thục, apply dưới 10 phút)*

### Apply Lab 10 (EKS)

```bash
cd lab-10-eks/terraform

cp terraform.tfvars.example terraform.tfvars
# Điền từ Lab 4: private_app_subnet_ids
# Điền thêm: public_access_cidrs = ["<your_ip>/32"]

terraform init && terraform apply  # ~15 phút

# Configure kubectl
aws eks update-kubeconfig --name csnp-lab10 --region us-east-1

kubectl get nodes
kubectl get pods -A
```

### Apply Lab 16 (GitOps — ArgoCD)

```bash
# ArgoCD manifest trong lab-16-gitops-argocd/argocd/
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply ArgoCD Application
kubectl apply -f ../../lab-16-gitops-argocd/argocd/project.yaml
kubectl apply -f ../../lab-16-gitops-argocd/argocd/application.yaml

# Drift drill: thay đổi trực tiếp trên cluster, verify ArgoCD sync lại
```

### Apply Lab 17 (External Secrets)

```bash
cd lab-17-external-secrets/terraform
terraform init && terraform apply

# Apply Kubernetes manifests
kubectl apply -f ../../lab-17-external-secrets/kubernetes/
```

### Apply Lab 18 (OpenTelemetry)

```bash
# Apply OTel collector manifests
kubectl apply -f ../../lab-18-opentelemetry/kubernetes/

# Verify traces trong X-Ray
aws xray get-service-graph --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s)
```

### ⚠️ DESTROY Session 4

```bash
# Xóa workloads trước, nodes tự terminate → dừng tính tiền node nhanh nhất
kubectl delete namespace argocd
kubectl delete all --all -n default

cd lab-10-eks/terraform && terraform destroy   # ~10 phút
cd ../../lab-04-terraform-platform-foundation/terraform && terraform destroy

# Verify EKS cluster đã xóa
aws eks list-clusters
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/csnp-lab10,Values=owned" \
  --query "Reservations[*].Instances[*].InstanceId"
```

---

## Labs độc lập — Làm bất kỳ lúc nào

| Lab | Cần gì | Ghi chú |
|---|---|---|
| Lab 9.5 — ECS vs EKS ADR | Không cần infra | Review `docs/ADR-0001-ECS-VS-EKS.md`, đổi status → Accepted |
| Lab 15 — CloudFront | Không cần Lab 4/5 | Có thể làm standalone |
| Lab 19 — Multi Account | Không cần infra | Docs-first, không tạo resource |
| Lab 20 — Disaster Recovery | Bất kỳ session nào có RDS | AWS Backup chọn resource theo tag |

---

## Tổng quan thứ tự

```
Session 1  Lab 4 → 5 → 6 → 7 → 8          ECS Ops — quan trọng nhất
    ↓
Session 2  Lab 4 → 9                        Aurora — destroy cùng ngày
    ↓
Lab 9.5                                     ADR — anytime, không infra
    ↓
Session 3  Lab 4 → 5 → 11, 12A → 13 → 14  CSNP Production
    ↓
Session 4  Lab 4 → 10 → 16 → 17 → 18      EKS + GitOps — tốn kém nhất
    ↓
Anytime    Lab 15, 19, 20
```

---

## Milestone

| Milestone | Hoàn thành sau |
|---|---|
| AWS SAA foundation | Session 1 + Session 2 |
| **CSNP Production Ready** | Session 1 + 2 + 3 |
| Senior Platform Engineer | Session 1 + 2 + 3 + 4 |

---

## Quick cost check

```bash
# Chạy trước khi kết thúc ngày — kiểm tra resource còn sót
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --query "NatGateways[*].{ID:NatGatewayId,Subnet:SubnetId}"

aws rds describe-db-instances \
  --query "DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass}"

aws rds describe-db-clusters \
  --query "DBClusters[*].{ID:DBClusterIdentifier,Status:Status}"

aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}"

aws eks list-clusters

aws elasticache describe-replication-groups \
  --query "ReplicationGroups[*].{ID:ReplicationGroupId,Status:Status}"

aws mq list-brokers \
  --query "BrokerSummaries[*].{Name:BrokerName,State:BrokerState}"
```

> Nếu có bất kỳ resource nào trong danh sách trên còn `available/active` mà không cần thiết → destroy ngay.
