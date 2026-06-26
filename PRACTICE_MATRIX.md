# AWS Labs Deliberate Practice Matrix

File này là bản đồ luyện tập nhanh. Chi tiết triển khai vẫn nằm trong `docs/*-hands-on.md` của từng lab.

| Lab | Console discovery | CLI verification | Failure drill | Rebuild target |
| --- | --- | --- | --- | --- |
| 00 | Billing, Budgets, SNS, Billing alarm | Budget/SNS/CloudWatch describe commands | SNS chưa confirm hoặc alarm thiếu data | Tự dựng guardrail và giải thích độ trễ billing |
| 01 | IAM, EC2, RDS, S3, CloudWatch | Describe instance/DB/role/bucket/log group | Chặn SG hoặc gỡ IAM permission | Wallet API healthy từ EC2 |
| 02 | ECR, ECS, ALB, target health | Describe service/tasks/targets/logs | Image tag sai hoặc health check sai | Build → push → service healthy |
| 03A | VPC resource map | Describe route tables/subnets/SG | Bỏ route association | Tự dựng VPC 3-tier bằng Console |
| 03B | Map CLI output với Console | Chính các lệnh create/describe/delete | Xóa sai dependency order | VPC sandbox từ CLI rồi cleanup |
| 04 | Map HCL với VPC Console | Terraform output + EC2 describe | Route/NAT/SG sai có chủ đích | Network foundation từ README |
| 05 | ECS/RDS/S3/IAM resource map | ECS/ELB/RDS/S3 describe | Task không pull image hoặc target unhealthy | ECS private-subnet stack healthy |
| 06 | Dashboard, alarm, logs, secret | CloudWatch/Logs/Secrets CLI | Trigger app error hoặc CPU alarm | Tự dựng dashboard + alarms |
| 07 | Scaling activity, deployments | ECS + Application Auto Scaling describe | Stop task, deploy image lỗi | Scaling policies + recovery |
| 08 | GitHub run + ECS deployment events | ECR image and ECS revision queries | Deploy bad SHA rồi rollback | Pipeline không dùng AWS access key |
| 09 | Aurora topology/events | RDS cluster/member queries | Controlled failover | Writer/reader + reconnect proof |
| 9.5 | Không tạo resource | Thu thập cost/ops evidence | Challenge decision bằng scenario mới | Tự viết ADR từ blank page |
| 10 | EKS cluster/node/add-ons | `aws eks` + `kubectl` | Pod crash, bad readiness, Pending pod | Cluster + workload + HPA |
| 11 | ElastiCache topology/metrics | Replication group query + Redis CLI | Failover hoặc cache unavailable | Cache-aside có fallback |
| 12A | MQ broker/queues/metrics | MQ describe + client observation | Poison message → retry → DLQ | Producer/consumer idempotent |
| 12B | MSK cluster/metrics | MSK describe + Kafka client | Consumer lag/replay | Topic + two consumer groups |
| 13 | Route 53 record, ACM, listeners | DNS, ACM, ELB queries | DNS/validation/listener mismatch | HTTPS endpoint verified |
| 14 | WAF rules/sample requests | WAF get/list commands | Trigger managed/rate rule | Block proof without breaking healthy traffic |
| 15 | Distribution/behaviors | CloudFront get-distribution + curl headers | Wrong cache key or stale object | Explain hit/miss and invalidate safely |
| 16 | Argo CD app/sync/diff | `kubectl`/Argo CD CLI | Manual drift and bad Git commit | Git-only recovery |
| 17 | ESO status, target Secret | `kubectl describe` + IAM checks | Break trust policy or property name | Rotation reaches workload |
| 18 | X-Ray service map/traces | Collector logs + trace lookup | Break exporter or downstream call | End-to-end trace with correlation |
| 19 | Organizations/Control Tower discovery only | Policy validation/simulation | Find SCP blast-radius issue | OU/SCP design from requirements |
| 20 | Backup jobs/recovery points | AWS Backup list/describe | Restore into isolated target | Measured RPO/RTO restore drill |

## Recommended repetitions by cost

- **Low-cost repeat often:** 00, 03B, 08 IAM/OIDC design, 9.5, 16 manifests, 17 manifests, 18 manifests, 19.
- **Short-lived repeat:** 01, 02, 04–07, 11, 13–15.
- **Schedule and destroy same day:** 09, 10, 12A, 12B, 20 restore drills.
