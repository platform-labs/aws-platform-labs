# Lab 08 - GitHub Actions CI/CD cho ECS

## Mục tiêu

Build, kiểm tra, đóng gói Docker, push ECR và deploy revision mới lên ECS bằng GitHub Actions. AWS authentication dùng GitHub OIDC, không dùng long-lived access key.

## Requires / Produces

- Requires: Lab 5 đã apply và service `csnp-platform-wallet-api-service` đang healthy.
- Requires: source WalletMinimal nằm trong `lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal`.
- Produces: IAM OIDC deploy role, GitHub Actions workflow và ECS task definition input cho deploy.

## Pipeline

```text
Pull request -> restore/build/test
main push -> OIDC -> STS -> ECR push (commit SHA) -> render task definition -> ECS deploy/stabilize
```

## Security

- Không lưu `AWS_ACCESS_KEY_ID` hoặc `AWS_SECRET_ACCESS_KEY` trong GitHub Secrets.
- IAM trust policy giới hạn đúng repository, branch `main` và GitHub Environment `dev`.
- Image deploy bằng immutable commit SHA, không deploy `latest`.
- `task-definition.json` là input deploy. Với lab có thể export từ revision hiện hành; production nên chuyển DB password sang Secrets Manager hoặc SSM Parameter Store.

## Cài đặt

1. Apply Lab 4 và Lab 5 theo `../PRACTICE_SCHEDULE.md`.
2. Export ECS task definition hiện hành vào `lab-08-cicd/task-definition.json`.
3. Apply Terraform trong `terraform/` để tạo GitHub OIDC deploy role.
4. Workflow đã có ở `.github/workflows/build-test-deploy.yml` và template nằm ở `github-actions/build-test-deploy.yml`.
5. Tạo GitHub Actions repository variables từ output `terraform output github_actions_variables`.
6. Push lên `main` để workflow build image, push ECR và deploy ECS.

## GitHub Actions Variables

Tạo trong GitHub repository: Settings -> Secrets and variables -> Actions -> Variables.

```text
AWS_ROLE_ARN
AWS_REGION
ECR_REPOSITORY
ECS_CLUSTER
ECS_SERVICE
ECS_TASK_DEFINITION
CONTAINER_NAME
```

Giá trị cho lab hiện tại:

```text
AWS_ROLE_ARN=arn:aws:iam::289069331511:role/csnp-lab08-github-ecs-deploy
AWS_REGION=us-east-1
ECR_REPOSITORY=csnp-platform-wallet-api
ECS_CLUSTER=csnp-platform-cluster
ECS_SERVICE=csnp-platform-wallet-api-service
ECS_TASK_DEFINITION=lab-08-cicd/task-definition.json
CONTAINER_NAME=wallet-api
```

## Verify

```bash
aws ecr describe-images \
  --repository-name csnp-platform-wallet-api \
  --query "sort_by(imageDetails,& imagePushedAt)[-1].{Tags:imageTags,Digest:imageDigest,Pushed:imagePushedAt}"

aws ecs describe-services \
  --cluster csnp-platform-cluster \
  --services csnp-platform-wallet-api-service \
  --query "services[0].{Status:status,Desired:desiredCount,Running:runningCount,TaskDefinition:taskDefinition}"

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 5
```

## Cleanup

Xóa hoặc disable workflow trước khi destroy IAM role để tránh pipeline chạy lỗi ngoài ý muốn.

Destroy theo thứ tự trong Session 1:

```bash
cd lab-08-cicd/terraform && terraform destroy
cd ../../lab-07-auto-scaling-resilience/terraform && terraform destroy
cd ../../lab-06-observability/terraform && terraform destroy
cd ../../lab-05-terraform-ecs-platform/terraform && terraform destroy
cd ../../lab-04-terraform-platform-foundation/terraform && terraform destroy
```

## Trạng thái

Configured for monorepo source path `lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal`.
