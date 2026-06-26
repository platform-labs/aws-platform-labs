# AWS Hands-on Lab #5

## Deliberate practice loop

1. **Mental model:** vẽ ALB public → ECS private-app → RDS private-data và IAM execution/task paths.
2. **Console discovery:** xem networking, task definition, target group, RDS subnet group và S3 permissions sau apply.
3. **Implementation:** lấy output Lab 4, tạo ECR/image rồi apply toàn stack.
4. **CLI verification:** kiểm tra task không có public IP, target healthy, hai IAM role khác nhau và S3 access.
5. **Failure drill:** dùng image sai, SG sai hoặc secret sai từng lỗi một; ghi symptom tương ứng.
6. **Rebuild without guide:** từ output Lab 4 và source app, tự đưa service về healthy.
7. **Cleanup/cost audit:** destroy Lab 5 trước Lab 4; kiểm tra ALB, RDS, ECS task/ENI và S3.
8. **Interview recap:** giải thích ownership giữa network state và application state.

Quy tắc luyện nhiều vòng: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Terraform ECS Platform — checklist thực hành

> Chỉ chạy phần này SAU KHI Lab 3 (Console + CLI) và Lab 4 (Terraform Platform Foundation) đã `terraform apply` thành công thật trên AWS.

## Step 0 - Lấy output từ Lab 4

```bash
cd ../../lab-04-terraform-platform-foundation/terraform
terraform output
```

Copy các giá trị sau vào `terraform.tfvars` của Lab 5:

* `vpc_id`
* `public_subnet_ids`
* `private_app_subnet_ids`
* `private_data_subnet_ids` — **NEW in Lab 5: RDS sẽ chạy trong 2 private data subnet này**
* `alb_security_group_id`
* `ecs_security_group_id`
* `rds_security_group_id` — **NEW in Lab 5: RDS sẽ dùng SG này, đã configured ở Lab 4 để accept từ ECS SG**

## Step 1 - Chuẩn bị RDS credentials

**Thay đổi từ Lab 4 tới Lab 5:** Lab 5 **tự tạo RDS PostgreSQL instance** (không sử dụng lại instance từ Lab 4). Điền các giá trị sau vào `terraform.tfvars`:

```bash
db_name = "wallet"                    # Database name, hoặc đặt tên khác
db_user = "postgres"                  # Master username
db_password = "YOUR_SECURE_PASSWORD"  # Mật khẩu mạnh (25+ ký tự, mix upper/lower/digit/special)
```

⚠️ **Lưu ý:** Các giá trị này sẽ được dùng để tạo RDS instance lần đầu. Nếu sau này muốn đổi password, phải dùng AWS Console hoặc `aws rds modify-db-instance` — Terraform sẽ không tự đổi nó.

## Step 2 - Build và push image lên ECR

**Lab 5 tạo ECR repository** qua Terraform. Workflow là:

### 2.1 - Apply lần 1 (tạo ECR repository)

```bash
terraform apply -target="aws_ecr_repository.wallet_api"
```

Copy ECR URI từ output:

```bash
terraform output ecr_repository_url
# Output: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api
```

### 2.2 - Build & Push image (từ source code của Lab 2)

```bash
# Chuyển tới folder source code của ứng dụng
cd ../../lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal

# Chuyển tới terraform directory
cd ../../lab-05-terraform-ecs-platform/terraform

# Login ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

# Build (quay lại source code folder)
cd ../../lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal
docker build -t csnp-platform-wallet-api:latest .

# Tag & Push
docker tag csnp-platform-wallet-api:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 2.3 - Điền terraform.tfvars

```bash
container_image = "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api:latest"
```

hoặc dùng script:

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
sed -i "s|container_image = \".*\"|container_image = \"${ECR_URL}:latest\"|" terraform.tfvars
```

## Step 3 - terraform apply toàn bộ

```bash
terraform apply
```

## Step 4 - Verify

### 4.1 ECS Service đang chạy đủ task

```bash
aws ecs describe-services \
  --cluster csnp-platform-cluster \
  --services csnp-platform-wallet-api-service \
  --query "services[0].{running:runningCount,desired:desiredCount}"
```

Kỳ vọng: `running` = `desired` = 2 (sau vài phút khởi động).

### 4.2 ALB trả response

```bash
terraform output alb_dns_name
curl http://<alb-dns-name>/health
```

Kỳ vọng: HTTP 200.

### 4.3 ECS task KHÔNG có Public IP

Console: ECS → Cluster → Service → Tasks → chọn 1 task → kiểm tra **Network** section.

Kỳ vọng: chỉ có Private IP, không có Public IP — khác hẳn Lab 2.

### 4.4 Task Role tách biệt Execution Role

```bash
terraform output task_execution_role_arn
terraform output task_role_arn
```

Kỳ vọng: 2 ARN khác nhau. Console: IAM → Roles → kiểm tra `task_role` chỉ có policy S3 scoped, không có `AmazonECSTaskExecutionRolePolicy` (role đó chỉ gắn cho `task_execution`).

## Step 5 - Verify app gọi được S3 qua Task Role

**Lab 5 tạo S3 bucket mới** (không sử dụng bucket từ Lab 1 hay Lab 4). Gọi endpoint `/upload` của app qua ALB (nếu app support), kiểm tra object xuất hiện trong S3 bucket được tạo bởi Terraform:

```bash
# Xem tên bucket được tạo
terraform output s3_bucket_name

# Liệt kê objects trong bucket
aws s3 ls s3://$(terraform output -raw s3_bucket_name)
```

Nếu object xuất hiện, chứng minh Task Role hoạt động đúng — app bên trong ECS container có thể gọi S3 mà không cần Access Key (credential được cấp qua IAM role).

## Cleanup

```bash
terraform destroy
```
