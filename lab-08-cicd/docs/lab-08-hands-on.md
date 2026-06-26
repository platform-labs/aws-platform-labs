# Lab 08 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ Git push -> OIDC -> STS -> ECR -> task revision -> ECS deployment.
2. **Console discovery:** xem IAM trust policy, GitHub run, ECR image digest và ECS deployment events.
3. **Implementation:** apply OIDC role, cấu hình repository variables và chạy workflow.
4. **CLI verification:** query CloudTrail assume-role event, ECR tag/digest và task definition revision.
5. **Failure drill:** deploy bad image rồi rollback về SHA tốt gần nhất.
6. **Rebuild without guide:** viết lại workflow tối thiểu không dùng AWS access key.
7. **Cleanup/cost audit:** xóa workflow test/role nếu không dùng; dọn image tags và failed revisions khi cần.
8. **Interview recap:** giải thích CI/CD boundary, immutable artifact và OIDC trust conditions.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Source layout

Lab này dùng code WalletMinimal ở:

```text
lab-02-ecr-ecs-fargate/src/Lab02.WalletMinimal
```

Workflow đã hardcode `APP_DIR` theo path trên để chạy:

- `dotnet restore Lab02.WalletMinimal.sln`
- `dotnet build Lab02.WalletMinimal.sln --configuration Release`
- `docker build` từ đúng thư mục chứa `Dockerfile`

## Terraform

Từ `lab-08-cicd/terraform`:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output github_actions_variables
```

Nếu account đã có GitHub OIDC provider, đặt:

```hcl
create_oidc_provider       = false
existing_oidc_provider_arn = "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
```

Với repo hiện tại, trust policy phải có subject:

```text
repo:platform-labs/aws-platform-labs:ref:refs/heads/main
repo:platform-labs/aws-platform-labs:environment:dev
```

Deploy job đang dùng `environment: dev`, nên GitHub OIDC sẽ gửi subject dạng `environment:dev`. Nếu bỏ `environment` trong workflow thì subject sẽ quay về dạng `ref:refs/heads/main`.

## Export task definition

Nếu cần tạo lại `task-definition.json` từ revision ECS hiện hành:

```bash
aws ecs describe-task-definition \
  --task-definition csnp-platform-wallet-api \
  --query taskDefinition \
  > ../task-definition.json
```

Nếu export bằng PowerShell, tránh dùng redirect `>` vì Windows PowerShell có thể ghi UTF-16. Dùng lệnh này để file JSON là UTF-8 không BOM:

```powershell
$json = aws ecs describe-task-definition --task-definition csnp-platform-wallet-api --query taskDefinition
[System.IO.File]::WriteAllText((Resolve-Path ..\task-definition.json), ($json -join [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
```

Giữ file này ở:

```text
lab-08-cicd/task-definition.json
```

GitHub variable tương ứng:

```text
ECS_TASK_DEFINITION=lab-08-cicd/task-definition.json
```

## GitHub variables

Tạo Actions variables, không phải secrets:

- `AWS_ROLE_ARN`: output Terraform.
- `AWS_REGION`: `us-east-1`.
- `ECR_REPOSITORY`: `csnp-platform-wallet-api`, là tên repository, không phải full URI.
- `ECS_CLUSTER`: `csnp-platform-cluster`.
- `ECS_SERVICE`: `csnp-platform-wallet-api-service`.
- `ECS_TASK_DEFINITION`: `lab-08-cicd/task-definition.json`.
- `CONTAINER_NAME`: `wallet-api`.

## Verify

- PR chỉ chạy restore/build/test.
- Push `main` phải tạo ECR tag bằng commit SHA.
- ECS deployment phải đạt stable state.
- CloudTrail event phải là `AssumeRoleWithWebIdentity`, không phải IAM user access key.

```bash
aws ecr describe-images \
  --repository-name csnp-platform-wallet-api \
  --query "sort_by(imageDetails,& imagePushedAt)[-1].{Tags:imageTags,Digest:imageDigest,Pushed:imagePushedAt}"

aws ecs describe-services \
  --cluster csnp-platform-cluster \
  --services csnp-platform-wallet-api-service \
  --query "services[0].deployments[*].{Status:status,Rollout:rolloutState,TaskDefinition:taskDefinition}"

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 5
```

## Rollback drill

Deploy một image lỗi health check, quan sát pipeline fail khi chờ service stable, sau đó redeploy SHA tốt gần nhất bằng cách revert commit hoặc chạy workflow từ commit tốt.

## Cleanup

Trước khi destroy Lab 8, disable hoặc xóa workflow để tránh push mới cố assume role đã bị xóa.
