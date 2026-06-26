# Lab 02 - Dockerize WalletMinimal → ECR → ECS Fargate → ALB → CloudWatch

## Mục tiêu

Bước tiếp theo sau Lab #1 — chuyển từ "EC2 chạy app trực tiếp" sang "container orchestration serverless". Sau lab này cần hiểu được:

* Docker image cho ASP.NET Core
* ECR (Elastic Container Registry)
* ECS Fargate (serverless container)
* Task Definition / Service / Cluster
* Application Load Balancer (ALB)
* CloudWatch Logs cho container (ECS tự gửi stdout/stderr, không cần Agent như Lab 1)

## Prerequisites

* Đã hoàn thành Lab #1 (RDS `csnp-wallet-dev` và S3 bucket `csnp-wallet-dev` vẫn giữ lại, dùng chung)
* Docker Desktop (Windows + WSL2 backend)
* AWS CLI đã configure với quyền ECR/ECS
* AWS Region: **us-east-1**

> EC2 từ Lab 1 không cần thiết cho Lab 2, có thể terminate nếu muốn tiết kiệm — ECS Fargate thay thế vai trò compute.

## Architecture

```text
                          Internet
                              |
                              v
                    Application Load Balancer
                         (csnp-wallet-alb)
                              |
                              v
                       Target Group :5000
                              |
                              v
                    ECS Fargate Service
                    (csnp-wallet-service)
                              |
              +---------------+---------------+
              |                               |
              v                               v
        Fargate Task 1                  Fargate Task 2
        (container :5000)               (container :5000)
              |                               |
              +---------------+---------------+
                              |
                 +------------+------------+
                 |                         |
                 v                         v
          RDS PostgreSQL                S3 Bucket
          (csnp-wallet-dev)         (csnp-wallet-dev)
                              |
                              v
                      CloudWatch Logs
                   (/ecs/csnp-wallet-api)
```

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| ECR | Lưu container image `csnp-wallet-api` |
| ECS Cluster | `csnp-wallet-cluster` |
| ECS Task Definition | `csnp-wallet-api`, 0.25 vCPU / 0.5 GB |
| ECS Service | `csnp-wallet-service`, desired count 2 |
| ALB | `csnp-wallet-alb`, public port 80 → Target Group port 5000 |
| CloudWatch Logs | `/ecs/csnp-wallet-api`, log driver `awslogs` |

## Estimated Cost

| Resource | Chi phí ước tính |
| -------- | ----------------- |
| ECR | $0.10/GB/tháng lưu trữ — image vài chục MB, không đáng kể |
| ECS Fargate | ~$0.04/giờ cho 0.25 vCPU + 0.5GB, tính theo task đang chạy |
| ALB | ~$16/tháng + $0.008/LCU-giờ — **tốn nhất trong lab này, tính theo giờ kể cả không có traffic** |

> Xoá ALB ngay sau khi xong lab — đây là resource cần ưu tiên cleanup nhất.

## Region

`us-east-1`

## Terraform inputs

Terraform state của Lab 2 được lưu trên shared labs S3 backend tại `aws/lab-02/terraform.tfstate`. Chạy [`../bootstrap/`](../bootstrap/) trước lần `terraform init` đầu tiên; state tách biệt hoàn toàn với Lab 1 và production.

Terraform khong build/push Docker image. Chay lab nay theo 2 phase:

1. Tao ECR repository truoc.
2. Build/push image len ECR.
3. Apply toan bo ECS/Fargate/ALB stack.

Vao thu muc `terraform/` va copy file example:

```powershell
Set-Location .\terraform
Copy-Item .\terraform.tfvars.example .\terraform.tfvars
```

Lay Default VPC ID:

```powershell
aws ec2 describe-vpcs `
  --filters "Name=is-default,Values=true" `
  --query "Vpcs[*].[VpcId,CidrBlock]" `
  --output table `
  --region us-east-1
```

Lay subnet trong Default VPC:

```powershell
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=vpc-xxxxxxxx" `
  --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" `
  --output table `
  --region us-east-1
```

Mac dinh Lab 2 Terraform se tu tao lai RDS + S3 can cho app, nen van chay duoc neu Lab 1 da `terraform destroy`.

Dien vao `terraform.tfvars`:

```hcl
vpc_id                   = "vpc-xxxxxxxx"
subnet_ids               = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
create_data_dependencies = true
db_password              = "CHANGE_ME"
```

Neu anh muon reuse RDS/S3 co san thay vi tao moi, set `create_data_dependencies = false`, lay RDS security group ID:

```powershell
aws rds describe-db-instances `
  --db-instance-identifier csnp-wallet-dev `
  --query "DBInstances[*].VpcSecurityGroups[*].VpcSecurityGroupId" `
  --output table `
  --region us-east-1
```

Va dien them:

```hcl
rds_security_group_id = "sg-xxxxxxxx"
db_host               = "csnp-wallet-dev.xxxxxxxxxx.us-east-1.rds.amazonaws.com"
s3_bucket             = "csnp-wallet-dev"
```

Tao ECR repository truoc:

```powershell
terraform init
terraform apply -target=aws_ecr_repository.wallet_api
```

Build va push image:

```powershell
aws ecr get-login-password --region us-east-1 `
  | docker login --username AWS --password-stdin <ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com

docker build -t csnp-wallet-api:v1 ..\src\Lab02.WalletMinimal
docker tag csnp-wallet-api:v1 <ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api:v1
docker push <ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com/csnp-wallet-api:v1
```

Sau khi image da co tren ECR, set `container_image` trong `terraform.tfvars`, roi apply toan bo:

```powershell
terraform apply
```

## Cleanup

* [ ] Xoá ECS Service (`csnp-wallet-service`) trước
* [ ] Xoá ECS Cluster (`csnp-wallet-cluster`)
* [ ] **Xoá ALB (`csnp-wallet-alb`) — ưu tiên cao nhất, tốn tiền theo giờ**
* [ ] Xoá Target Group
* [ ] Xoá ECR repository hoặc image cũ nếu không cần giữ
* [ ] Xoá CloudWatch log group `/ecs/csnp-wallet-api`
* [ ] RDS và S3 do Lab 2 tạo, hoặc resource reuse từ Lab 1 nếu có
* [ ] Nếu chạy qua Terraform: `terraform destroy` trong `terraform/`

## Lessons Learned

* ECS Fargate đơn giản hơn EKS ở quy mô nhỏ — không cần quản lý node group, AWS tự scale. EKS đáng dùng khi đã có nhiều cluster/multi-cloud hoặc cần K8s ecosystem (Helm, Operators...).
* Container chỉ nhận traffic từ ALB Security Group, không bao giờ mở thẳng ra `0.0.0.0/0` ở port container.
* Multi-stage Docker build: stage `build` dùng SDK image để compile, stage `runtime` dùng ASP.NET runtime image — image cuối không có source code hay SDK.
* Chi tiết đầy đủ + Q&A phỏng vấn xem [`docs/lab-02-hands-on.md`](./docs/lab-02-hands-on.md) và [`docs/lab-02-interview-notes.md`](./docs/lab-02-interview-notes.md).

## Trạng thái

Lab đã làm thủ công qua Console (xem `docs/lab-02-hands-on.md`). `terraform/` hiện đã dựng lại phần hạ tầng chính tương đương Console: ECR scan-on-push, ECS Cluster, Task Execution Role, Task Role cho app gọi S3, ALB/Target Group/Listener, Security Groups, RDS PostgreSQL + S3 data dependencies, Task Definition, ECS Service Fargate và CloudWatch Logs. Image vẫn phải build/push thủ công (`docker build` / `docker push`); Terraform chỉ provision phần AWS, không build image.
