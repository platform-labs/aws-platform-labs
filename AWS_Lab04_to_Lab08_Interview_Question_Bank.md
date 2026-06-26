# AWS Platform Labs - Lab 04 → Lab 08 Interview Question Bank

> Tài liệu ôn tập theo dạng **câu hỏi phỏng vấn + câu trả lời chuẩn + ghi nhớ production**.
>
> Phạm vi: Lab 04 VPC Foundation, Lab 05 ECS Platform, Lab 06 Observability, Lab 07 Auto Scaling, Lab 08 GitHub Actions CI/CD.

---

# 0. Bức tranh tổng thể

## Runtime request flow

```text
Browser
  ↓
wallet.csnp.xyz
  ↓
DNS
  ↓
Application Load Balancer
  ↓
Target Group
  ↓
ECS Task
  ↓
Container .NET API
  ↓
PostgreSQL RDS
```

## Deployment flow

```text
Git Push
  ↓
GitHub Actions
  ↓
OIDC → IAM Role
  ↓
Docker Build
  ↓
Push Image to ECR
  ↓
Render Task Definition
  ↓
Register New Revision
  ↓
Update ECS Service
  ↓
Rolling Update
  ↓
ALB Health Check
  ↓
Deployment Success
```

## Auto Scaling flow

```text
Request tăng
  ↓
CPU / Memory tăng
  ↓
CloudWatch Metrics
  ↓
CloudWatch Alarm
  ↓
Application Auto Scaling
  ↓
Desired Count tăng
  ↓
ECS Service tạo Task mới
  ↓
Target Group Health Check
  ↓
ALB chia traffic sang Task mới
```

---

# LAB 04 - VPC Foundation

## 1. VPC là gì?

**Câu hỏi:** VPC dùng để làm gì trong AWS?

**Trả lời chuẩn:**
VPC, viết tắt của Virtual Private Cloud, là một mạng riêng ảo trên AWS. Nó tạo ra một vùng mạng cô lập để triển khai tài nguyên như ALB, ECS, RDS, NAT Gateway, Security Group và Subnet.

VPC giúp mình cô lập hạ tầng, chia mạng thành subnet, kiểm soát route, kiểm soát security, và thực hiện network segmentation giữa tầng public, app và data.

**Ghi nhớ:**
Không nên trả lời đơn giản “VPC là mạng”. Câu tốt hơn là: VPC là vùng mạng riêng ảo dùng để cô lập và kiểm soát hạ tầng AWS của ứng dụng.

---

## 2. CIDR `10.10.0.0/16` nghĩa là gì?

**Trả lời chuẩn:**
`10.10.0.0/16` là dải IP của VPC. `/16` nghĩa là 16 bit đầu dùng cho network, còn 16 bit còn lại dùng cho host. Tổng số IP là `2^16 = 65,536`.

Dải này bao phủ:

```text
10.10.0.0 → 10.10.255.255
```

**Ghi nhớ:**
VPC CIDR là không gian IP cha. Subnet phải nằm trong dải này.

---

## 3. Vì sao subnet phải nằm trong CIDR của VPC?

**Trả lời chuẩn:**
Vì subnet là một phần của VPC. CIDR của subnet phải là tập con của CIDR VPC. AWS cần đảm bảo routing trong VPC rõ ràng, không chồng lấn và không vượt ra khỏi không gian IP của VPC.

Ví dụ hợp lệ:

```text
VPC:     10.10.0.0/16
Subnet:  10.10.1.0/24
Subnet:  10.10.2.0/24
```

Ví dụ không hợp lệ:

```text
VPC:     10.10.0.0/16
Subnet:  192.168.1.0/24
```

**Ghi nhớ:**
Subnet là con của VPC và không được overlap với subnet khác.

---

## 4. Vì sao AWS reserve 5 IP mỗi subnet?

**Trả lời chuẩn:**
Ví dụ subnet `10.10.1.0/24` có 256 IP, nhưng AWS giữ lại 5 IP:

| IP | Ý nghĩa |
|---|---|
| 10.10.1.0 | Network address |
| 10.10.1.1 | VPC router |
| 10.10.1.2 | Amazon DNS |
| 10.10.1.3 | AWS reserved |
| 10.10.1.255 | Địa chỉ cuối subnet, AWS reserve |

Vì vậy `/24` còn 251 IP usable.

**Ghi nhớ:**
AWS reserve 5 IP mỗi subnet, không phải mỗi VPC.

---

## 5. Public Subnet được quyết định bởi gì?

**Trả lời chuẩn:**
Một subnet được gọi là Public Subnet khi route table của nó có route:

```text
0.0.0.0/0 → Internet Gateway
```

Auto-assign Public IP chỉ là tính năng hỗ trợ, không phải yếu tố quyết định chính.

**Ghi nhớ:**
Public/Private được quyết định bởi Route Table.

---

## 6. Public Subnet thường chứa resource nào?

**Trả lời chuẩn:**
Public Subnet thường chứa Application Load Balancer và NAT Gateway. ECS Task và RDS không nên đặt trong Public Subnet.

**Ghi nhớ:**
ALB public, ECS private, RDS private.

---

## 7. Vì sao ECS nằm ở Private App Subnet?

**Trả lời chuẩn:**
ECS Task là nơi chạy application nên không nên expose trực tiếp ra Internet. Nếu đặt ở Public Subnet và có public IP, attack surface tăng lên. Kiến trúc chuẩn là Internet vào ALB, ALB forward tới ECS private.

```text
Internet → ALB → ECS Task trong Private App Subnet
```

**Ghi nhớ:**
ECS chỉ nhận traffic từ ALB Security Group.

---

## 8. Vì sao RDS nằm ở Private Data Subnet?

**Trả lời chuẩn:**
RDS chứa dữ liệu quan trọng nên không được truy cập trực tiếp từ Internet. RDS nên nằm ở Private Data Subnet và Security Group chỉ cho phép ECS SG kết nối qua port database, ví dụ PostgreSQL 5432.

```text
RDS SG inbound: 5432 from ECS SG
```

**Ghi nhớ:**
Database không public.

---

## 9. Internet Gateway là gì?

**Trả lời chuẩn:**
Internet Gateway là AWS-managed component giúp VPC kết nối Internet. Nó attach vào VPC, không nằm trong subnet, và không có private IP riêng.

Muốn resource truy cập Internet qua IGW cần có đủ:
1. IGW attach vào VPC.
2. Subnet route `0.0.0.0/0` tới IGW.
3. Resource có public IP hoặc là public ALB.
4. Security Group/NACL cho phép traffic.

**Ghi nhớ:**
IGW là cổng Internet của VPC, không phải của một subnet riêng lẻ.

---

## 10. Vì sao một VPC chỉ attach một Internet Gateway?

**Trả lời chuẩn:**
Internet Gateway là dịch vụ AWS-managed và đã highly available sẵn. Một VPC chỉ cần một IGW làm điểm kết nối duy nhất ra Internet. Nếu có nhiều IGW, route `0.0.0.0/0` sẽ trở nên phức tạp và mơ hồ.

**Ghi nhớ:**
IGW đã HA bởi AWS.

---

## 11. NAT Gateway là gì?

**Trả lời chuẩn:**
NAT Gateway cho phép resource trong Private Subnet outbound ra Internet mà không cho Internet chủ động kết nối ngược vào resource đó.

```text
ECS Task → NAT Gateway → Internet Gateway → Internet API
```

**Ghi nhớ:**
NAT = outbound Internet cho Private Subnet.

---

## 12. Vì sao NAT Gateway phải nằm trong Public Subnet?

**Trả lời chuẩn:**
NAT Gateway cần route ra Internet Gateway và cần Elastic IP để giao tiếp với Internet, nên nó phải nằm trong Public Subnet. Nếu NAT nằm trong Private Subnet, chính nó cũng không có đường ra Internet.

**Ghi nhớ:**
Private App → NAT ở Public Subnet → IGW → Internet.

---

## 13. Internet có chủ động đi qua NAT vào ECS được không?

**Trả lời chuẩn:**
Không. NAT Gateway chỉ hỗ trợ kết nối outbound từ private subnet ra Internet và cho phép response quay về. Nó không nhận connection mới từ Internet vào private resource.

**Ghi nhớ:**
NAT là outbound-only.

---

## 14. Production nên dùng mấy NAT Gateway?

**Trả lời chuẩn:**
Lab dùng 1 NAT để tiết kiệm chi phí. Production nên dùng 1 NAT Gateway mỗi AZ để đảm bảo HA và tránh cross-AZ traffic charge.

```text
Private App AZ-a → NAT AZ-a
Private App AZ-b → NAT AZ-b
```

**Ghi nhớ:**
Đây là AZ Affinity / AZ Independence.

---

## 15. VPC Endpoint dùng để làm gì?

**Trả lời chuẩn:**
VPC Endpoint cho phép resource trong VPC truy cập AWS Services qua AWS private backbone, không cần đi ra Internet qua NAT Gateway.

Dùng được cho S3, ECR, CloudWatch, DynamoDB, Secrets Manager. Không dùng được cho Stripe, PayPal, OpenAI, Firebase.

**Ghi nhớ:**
Endpoint giảm NAT cost và tăng security cho AWS-to-AWS traffic.

---

## 16. Security Group là gì?

**Trả lời chuẩn:**
Security Group là firewall stateful áp dụng lên ENI/resource như EC2, ECS Task, RDS, ALB.

Đặc điểm:
- Layer 3/4.
- Stateful.
- Chỉ có Allow rule.
- Hỗ trợ Security Group reference.

**Ghi nhớ:**
Security Group không phải Layer 7.

---

## 17. Security Group Stateful nghĩa là gì?

**Trả lời chuẩn:**
Nếu request được cho phép đi vào, response được tự động cho phép đi ra mà không cần rule ngược lại.

**Ghi nhớ:**
SG nhớ trạng thái kết nối.

---

## 18. Vì sao dùng Security Group Reference thay vì IP?

**Trả lời chuẩn:**
ECS Task có thể bị thay mới và private IP thay đổi. Nếu hardcode IP thì deploy hoặc scale sẽ làm rule sai. Dùng SG reference thì bất kỳ Task nào mang ECS SG đều được phép kết nối.

```text
RDS SG inbound: 5432 from ECS SG
```

**Ghi nhớ:**
SG reference rất quan trọng trong production.

---

## 19. NACL khác Security Group thế nào?

| Security Group | NACL |
|---|---|
| Resource/ENI level | Subnet level |
| Stateful | Stateless |
| Chỉ Allow | Allow + Deny |
| Hỗ trợ SG reference | Chỉ CIDR/IP |
| Dễ maintain | Dùng cho boundary/compliance |

**Ghi nhớ:**
Phần lớn production dùng SG là chính, NACL có thể để default hoặc dùng thêm cho compliance.

---

## 20. Defense in Depth là gì?

**Trả lời chuẩn:**
Defense in Depth nghĩa là nhiều lớp bảo vệ chồng lên nhau. Không tin vào một lớp duy nhất.

Ví dụ:
- VPC.
- Private Subnet.
- Route Table.
- Security Group.
- Database Password.
- IAM.
- Encryption.

**Ghi nhớ:**
Nếu một lớp bị phá, vẫn còn lớp khác.

---

## 21. Blast Radius là gì?

**Trả lời chuẩn:**
Blast Radius là phạm vi thiệt hại nếu một thành phần bị compromise. Thiết kế tốt là giảm blast radius.

**Ghi nhớ:**
Defense in Depth = nhiều lớp bảo vệ. Blast Radius = giới hạn thiệt hại.

---

# LAB 05 - ECS Platform

## 22. ECS Cluster là gì?

**Trả lời chuẩn:**
ECS Cluster là logical boundary để quản lý ECS Services và Tasks. Với Fargate, cluster không đại diện cho một nhóm EC2 mà là nơi tổ chức workload.

**Ghi nhớ:**
Cluster không scale. Service/Task mới là thứ scale.

---

## 23. Quan hệ Cluster → Service → Task → Container là gì?

```text
Cluster
  ↓
Service
  ↓
Task
  ↓
Container
```

- Cluster: boundary quản lý.
- Service: duy trì số lượng Task mong muốn.
- Task: đơn vị chạy workload.
- Container: process/app chạy bên trong Task.

**Ghi nhớ:**
Running = 2 nghĩa là 2 Tasks, không nhất thiết là 2 Containers.

---

## 24. Service tồn tại để làm gì khi đã có Task?

**Trả lời chuẩn:**
Service chịu trách nhiệm duy trì desired state cho Task. Nó quản lý Desired Count, Running Count, self-healing, rolling update, deployment, auto scaling, và register/deregister Target Group.

**Ghi nhớ:**
Task là đơn vị chạy. Service là người quản lý vòng đời Task.

---

## 25. Desired Count khác Running Count thế nào?

**Trả lời chuẩn:**
Desired Count là số Task mình muốn chạy. Running Count là số Task thực tế đang chạy.

```text
Desired = 2
Running = 1
```

ECS Service sẽ cố tạo thêm 1 Task.

**Ghi nhớ:**
Service luôn cố đưa Running Count về Desired Count.

---

## 26. Nếu stop Task bằng tay thì chuyện gì xảy ra?

**Trả lời chuẩn:**
Nếu service desired count là 2 và anh stop 1 task, ECS Service sẽ tạo task mới để thay thế vì nó phải duy trì Desired Count.

**Ghi nhớ:**
Đây là self-healing.

---

## 27. Nếu Desired Count = 0 thì sao?

**Trả lời chuẩn:**
ECS Service sẽ stop toàn bộ Task cho đến khi Running Count = 0. Service vẫn tồn tại nhưng không chạy Task nào.

**Ghi nhớ:**
Desired = 0 là cách tắt app mà chưa xóa Service.

---

## 28. Task Definition là gì?

**Trả lời chuẩn:**
Task Definition là bản mô tả cách chạy một ECS Task. Nó định nghĩa Docker image, CPU, Memory, Port, Environment Variables, Secrets, Logging, Task Role, Execution Role, Network Mode.

Nó giống Docker Compose service definition hoặc Kubernetes Pod/Deployment spec ở góc độ run container.

**Ghi nhớ:**
Dockerfile build image. Task Definition run image.

---

## 29. Task Definition Revision là gì?

**Trả lời chuẩn:**
Task Definition là immutable. Khi sửa image, CPU, memory, env, port, role hoặc log config, ECS tạo revision mới.

```text
csnp-platform-wallet-api:3
csnp-platform-wallet-api:4
csnp-platform-wallet-api:5
```

**Ghi nhớ:**
Không sửa revision cũ. Luôn tạo revision mới.

---

## 30. Sửa env `DB_HOST` có tạo revision mới không?

**Trả lời chuẩn:**
Có. Environment variable là một phần của Task Definition, nên sửa env sẽ tạo revision mới.

**Ghi nhớ:**
Mọi thay đổi runtime spec đều tạo revision mới.

---

## 31. Task Role khác Execution Role thế nào?

```text
Execution Role = quyền cho ECS/Fargate platform
Task Role      = quyền cho application bên trong container
```

Execution Role dùng để pull image từ ECR, ghi log CloudWatch, lấy secrets lúc start container.

Task Role dùng để .NET API gọi S3, DynamoDB, SQS, Secrets Manager runtime.

**Ghi nhớ:**
Execution Role = ECS chạy container. Task Role = App gọi AWS.

---

## 32. Nếu .NET API upload file lên S3 thì quyền nằm ở role nào?

**Trả lời chuẩn:**
Task Role. Vì người gọi S3 là ứng dụng .NET bên trong container.

---

## 33. Nếu ECS không pull được image từ ECR thì kiểm tra role nào?

**Trả lời chuẩn:**
Kiểm tra Execution Role, ECR permission, image tag, repository, network route/NAT/VPC Endpoint.

---

## 34. Fargate khác EC2 Launch Type thế nào?

**Trả lời chuẩn:**
Fargate là serverless compute engine cho container. Mình chỉ định CPU/RAM cho Task, AWS quản lý hạ tầng bên dưới.

EC2 Launch Type thì mình phải quản lý EC2 instance, AMI, patching, capacity, scaling, security.

**Ghi nhớ:**
Fargate dễ vận hành. EC2 kiểm soát sâu hơn nhưng phải tự quản lý.

---

## 35. Rolling Update hoạt động thế nào?

**Trả lời chuẩn:**
ECS tạo task mới từ Task Definition revision mới, chờ health check pass, register vào Target Group, rồi drain và stop task cũ.

```text
Start new task → Health check pass → Register target → Drain old task → Stop old task
```

**Ghi nhớ:**
Không sửa Task cũ. Tạo Task mới.

---

## 36. Deployment configuration 100% / 200% nghĩa là gì?

**Trả lời chuẩn:**
Giả sử Desired Count = 2.

- Minimum 100% nghĩa là luôn giữ ít nhất 2 healthy tasks.
- Maximum 200% nghĩa là tạm thời có thể chạy tối đa 4 tasks khi deploy.

**Ghi nhớ:**
100/200 giúp zero downtime deployment.

---

## 37. Steady State nghĩa là gì?

**Trả lời chuẩn:**
Steady State nghĩa là service đã ổn định: Desired Count = Running Count, Task healthy, deployment hoàn tất, Target Group healthy.

**Ghi nhớ:**
Running thôi chưa đủ. Phải healthy.

---

## 38. Connection Draining là gì?

**Trả lời chuẩn:**
Connection draining giúp task cũ ngừng nhận request mới nhưng vẫn có thời gian xử lý request đang chạy trước khi bị stop.

**Ghi nhớ:**
Giảm downtime và tránh cắt ngang request.

---

## 39. Task có ENI riêng nghĩa là gì?

**Trả lời chuẩn:**
Fargate dùng `awsvpc` network mode. Mỗi Task có ENI riêng, Private IP riêng, Security Group riêng.

**Ghi nhớ:**
Fargate Target Group thường dùng target type IP.

---

## 40. Task mới có giữ IP cũ không?

**Trả lời chuẩn:**
Không. Task mới thường có private IP mới.

**Ghi nhớ:**
Không hardcode Task IP.

---

## 41. Task là Stateful hay Stateless?

**Trả lời chuẩn:**
Task nên được thiết kế Stateless. Không nên lưu session, file upload, cache quan trọng hoặc state lâu dài trong container. State nên lưu ở RDS, Redis, S3 hoặc DynamoDB.

**Ghi nhớ:**
Task là disposable.

---

## 42. Nếu lưu session trong RAM của Task thì sao?

**Trả lời chuẩn:**
User có thể bị logout khi Task crash hoặc bị thay mới. Production nên lưu session ở Redis hoặc dùng stateless token tùy kiến trúc.

---

## 43. ALB biết Task mới bằng cách nào?

**Trả lời chuẩn:**
ECS Service đăng ký Task mới vào Target Group. ALB forward traffic tới các healthy targets trong Target Group.

---

## 44. Nếu Task không có public IP thì ALB có truy cập được không?

**Trả lời chuẩn:**
Có. ALB và ECS Task cùng nằm trong VPC. ALB forward tới private IP của Task qua Target Group, miễn là SG và route nội bộ đúng.

---

## 45. Health Check có cần thiết không khi Task đang Running?

**Trả lời chuẩn:**
Có. Running chỉ nói container/process đang chạy. Health check nói application thật sự phục vụ được không.

**Ghi nhớ:**
Running ≠ Healthy.

---

## 46. Health Check Path nên là `/` hay `/health`?

**Trả lời chuẩn:**
Nên dùng endpoint chuyên biệt như `/health`, `/healthz` hoặc `/ready`. Không nên dùng `/` nếu endpoint đó nặng, gọi nhiều dependency hoặc cần auth.

---

## 47. Nếu `/health` trả 500 thì ALB có gửi traffic không?

**Trả lời chuẩn:**
Không. ALB chỉ forward traffic tới target healthy.

---

## 48. Nếu deploy revision mới fail health check thì sao?

**Trả lời chuẩn:**
Task mới không nhận traffic. Nếu deployment circuit breaker bật, ECS đánh dấu deployment failed và rollback về revision trước.

---

# LAB 06 - Observability

## 49. Observability gồm những gì?

| Thành phần | Trả lời câu hỏi |
|---|---|
| Logs | Chuyện gì đã xảy ra? |
| Metrics | Hệ thống có khỏe không? |
| Traces | Request đi qua những service nào? |

**Ghi nhớ:**
Logs, Metrics, Traces bổ sung cho nhau.

---

## 50. Vì sao ECS không ghi log vào `/var/log`?

**Trả lời chuẩn:**
Container/Task có thể bị stop hoặc recreate bất cứ lúc nào. Nếu log chỉ nằm local trong container thì sẽ mất. ECS Fargate không SSH để tail log, nên log được đẩy ra CloudWatch.

**Ghi nhớ:**
Container stdout/stderr → CloudWatch Logs.

---

## 51. Log Group khác Log Stream thế nào?

**Trả lời chuẩn:**
Log Group là nơi gom log của một service/app. Log Stream thường đại diện cho từng Task/container instance.

```text
Log Group: /ecs/csnp-platform-wallet-api
Log Stream: ecs/wallet-api/task-id
```

---

## 52. Nếu Desired Count = 100 thì có bao nhiêu Log Stream?

**Trả lời chuẩn:**
Thường sẽ có 100 log streams, mỗi Task/container có một stream riêng.

---

## 53. Task crash thì log có mất không?

**Trả lời chuẩn:**
Nếu log đã gửi lên CloudWatch thì vẫn còn. Nếu chỉ ghi local file thì mất.

---

## 54. `Console.WriteLine()` có lên CloudWatch không?

**Trả lời chuẩn:**
Có, nếu container log configuration đang gửi stdout/stderr tới CloudWatch.

---

## 55. Làm sao tìm ERROR trong 100 Log Streams?

**Trả lời chuẩn:**
Dùng CloudWatch Logs search hoặc Logs Insights để query across streams. Không cần mở từng stream.

**Ghi nhớ:**
Production nên dùng structured logging dạng JSON.

---

## 56. Metrics khác Logs thế nào?

| Logs | Metrics |
|---|---|
| Stack trace | CPU % |
| Exception detail | Memory % |
| UserId, requestId | Request count |
| Debug message | Latency |

**Ghi nhớ:**
Metrics trả lời WHAT. Logs trả lời WHY.

---

## 57. CPU cao nhưng Memory thấp thì scale theo gì?

**Trả lời chuẩn:**
Scale theo CPU vì CPU là bottleneck.

---

## 58. Memory 98% nhưng CPU 15%, CPU alarm có scale không?

**Trả lời chuẩn:**
Không. CPU alarm chỉ phản ứng với CPU metric. Muốn scale theo memory thì cần memory scaling policy/alarm.

---

## 59. App throw exception thì CPU có tăng không?

**Trả lời chuẩn:**
Không nhất thiết. Exception có thể xuất hiện trong logs nhưng CPU vẫn thấp. Nếu exception xảy ra trong loop liên tục thì CPU có thể tăng.

---

## 60. Deadlock thì CPU, logs hay health check phát hiện trước?

**Trả lời chuẩn:**
Health check có thể phát hiện trước nếu endpoint bị timeout. CPU có thể thấp vì thread bị block. Logs giúp tìm nguyên nhân sau đó.

---

# LAB 07 - Auto Scaling

## 61. Auto Scaling flow là gì?

```text
Request tăng
  ↓
CPU/Memory tăng
  ↓
CloudWatch Metrics
  ↓
CloudWatch Alarm
  ↓
Application Auto Scaling
  ↓
Desired Count thay đổi
  ↓
ECS Service tạo hoặc stop Task
```

---

## 62. CPU 95%, ai nhìn thấy đầu tiên?

**Trả lời chuẩn:**
CloudWatch Metrics.

---

## 63. CloudWatch có tự tạo Task không?

**Trả lời chuẩn:**
Không. CloudWatch alarm kích hoạt scaling policy thông qua Application Auto Scaling. Application Auto Scaling thay đổi Desired Count, rồi ECS Service tạo Task.

---

## 64. Scale Out tăng cái gì trước?

**Trả lời chuẩn:**
Application Auto Scaling cập nhật Desired Count trước. ECS Service thấy Desired Count tăng thì tạo Task mới.

---

## 65. Min Capacity và Max Capacity là gì?

**Trả lời chuẩn:**
Min Capacity là số task thấp nhất service được phép chạy. Max Capacity là số task cao nhất service được phép scale lên.

Ví dụ Min = 2, Max = 4: service không chạy dưới 2 và không vượt quá 4.

---

## 66. CPU thấp thì có scale in không?

**Trả lời chuẩn:**
Có thể có, nếu scaling policy cho phép scale in. Nó sẽ giảm Desired Count dần nhưng không thấp hơn Min Capacity.

---

## 67. Cooldown dùng để làm gì?

**Trả lời chuẩn:**
Cooldown giúp hệ thống có thời gian ổn định sau một lần scale trước khi tiếp tục scale. Nếu không có cooldown, hệ thống có thể scale out/in liên tục do metric dao động.

---

## 68. Thrashing là gì?

**Trả lời chuẩn:**
Thrashing là hiện tượng hệ thống scale out/in liên tục.

```text
CPU 95% → scale out 2 → 4
CPU 20% → scale in 4 → 2
CPU 95% → scale out 2 → 4
```

Hậu quả: tốn tiền, task tạo/stop liên tục, hệ thống không ổn định.

---

## 69. Target Tracking Scaling là gì?

**Trả lời chuẩn:**
Target Tracking cố duy trì metric quanh một target value. Ví dụ CPU target = 10%, Memory target = 70%.

**Ghi nhớ:**
Target Tracking giống thermostat.

---

# LAB 08 - GitHub Actions CI/CD

## 70. CI/CD flow đầy đủ là gì?

```text
Git Push
  ↓
GitHub Actions Trigger
  ↓
Checkout source
  ↓
Configure AWS Credentials via OIDC
  ↓
Login to ECR
  ↓
Docker Build
  ↓
Docker Push to ECR
  ↓
Render Task Definition
  ↓
Register New Task Definition Revision
  ↓
Update ECS Service
  ↓
Rolling Update
  ↓
ALB Health Check
  ↓
Service Stable
```

---

## 71. Ai thấy Git commit mới đầu tiên?

**Trả lời chuẩn:**
GitHub Actions thấy commit trước vì workflow được trigger bởi GitHub event như push hoặc workflow_dispatch.

---

## 72. GitHub deploy AWS bằng cách nào?

**Trả lời chuẩn:**
GitHub Actions dùng OIDC token để assume IAM Role trong AWS thông qua `AssumeRoleWithWebIdentity`.

```text
GitHub Actions → OIDC Token → AWS IAM Role Trust Policy → Temporary Credentials → AWS API
```

---

## 73. OIDC khác Access Key như thế nào?

**Trả lời chuẩn:**
OIDC cấp temporary credentials theo từng workflow run. Không cần lưu long-lived secret trong GitHub. IAM Role trust policy còn giới hạn repo, branch hoặc environment nào được assume role.

**Ghi nhớ:**
OIDC giảm rủi ro lộ access key.

---

## 74. Docker image push lên đâu?

**Trả lời chuẩn:**
Push lên ECR, Elastic Container Registry.

---

## 75. Push image lên ECR xong app đã chạy chưa?

**Trả lời chuẩn:**
Chưa. Image mới chỉ được lưu trong ECR. Cần register task definition revision mới và update ECS Service.

---

## 76. Vì sao không dùng image tag `latest`?

**Trả lời chuẩn:**
`latest` không immutable và khó biết chính xác version nào đang chạy. Commit SHA giúp trace image tương ứng với source code nào và rollback chính xác.

```text
wallet-api:1cb8306
wallet-api:840e75c
wallet-api:4c6d7c7
```

---

## 77. Render Task Definition là gì?

**Trả lời chuẩn:**
Render Task Definition là quá trình lấy file task-definition template và thay image của container bằng image tag mới vừa build.

Before:

```json
"image": "csnp-platform-wallet-api:old"
```

After:

```json
"image": "289069331511.dkr.ecr.us-east-1.amazonaws.com/csnp-platform-wallet-api:1cb8306"
```

---

## 78. ECS update gì khi deploy?

**Trả lời chuẩn:**
Nó register Task Definition Revision mới và update ECS Service dùng revision mới đó.

---

## 79. Rollback là rollback Docker image hay Task Definition Revision?

**Trả lời chuẩn:**
Rollback về Task Definition Revision trước đó. Revision cũ đã chứa image tag cũ.

---

## 80. GitHub Actions có SSH vào server để deploy không?

**Trả lời chuẩn:**
Không. GitHub Actions gọi AWS API để update ECS Service. Với Fargate, không có server để SSH.

---

## 81. Vì sao build trên GitHub Runner thay vì máy developer?

**Trả lời chuẩn:**
GitHub Runner cung cấp môi trường sạch, repeatable, có log, có kiểm soát permission và không phụ thuộc máy cá nhân. Máy developer có thể khác môi trường, có credential rủi ro, tắt máy hoặc bị cấu hình sai.

---

## 82. Nếu 3 commit được push thì ECR có bao nhiêu image?

**Trả lời chuẩn:**
Có 3 image tag tương ứng với 3 commit SHA.

---

## 83. Deploy step “wait for stability” làm gì?

**Trả lời chuẩn:**
Nó chờ ECS Service đạt steady state: Task mới được tạo, pull image, container start, health check pass, target group healthy, task cũ drain/stop, deployment complete.

---

## 84. OIDC Trust Policy nên giới hạn gì?

**Trả lời chuẩn:**
Nên giới hạn theo repository, branch, environment và audience.

Ví dụ:

```text
repo:platform-labs/aws-platform-labs:ref:refs/heads/main
repo:platform-labs/aws-platform-labs:environment:dev
```

---

# End-to-End Interview Questions

## 85. Hãy giải thích request từ user đến RDS

**Trả lời chuẩn:**
Khi user truy cập `wallet.csnp.xyz`, DNS phân giải domain tới ALB. Request đi vào VPC qua Internet Gateway và tới ALB trong Public Subnet. ALB dùng Listener Rule để forward request tới Target Group. Target Group chỉ chứa các ECS Task healthy. Mỗi ECS Task có ENI và private IP trong Private App Subnet. Container .NET API xử lý request. Nếu cần database, app kết nối PostgreSQL RDS trong Private Data Subnet. RDS chỉ cho phép ECS Security Group truy cập qua port 5432. Response đi ngược lại qua ALB về client.

---

## 86. Hãy giải thích deploy từ Git Push đến user traffic

**Trả lời chuẩn:**
Developer push code lên GitHub. GitHub Actions workflow được trigger. Runner checkout source code, dùng OIDC để assume IAM Role trên AWS. Pipeline build Docker image và push image lên ECR với tag commit SHA. Sau đó render task definition bằng cách thay image mới vào container definition. GitHub Action register Task Definition revision mới và update ECS Service. ECS thực hiện rolling update bằng cách tạo task mới, chờ ALB health check pass, register task mới vào target group, drain task cũ rồi stop task cũ. Nếu task mới fail health check và circuit breaker bật, ECS rollback về revision trước.

---

## 87. Hãy giải thích Auto Scaling end-to-end

**Trả lời chuẩn:**
Khi traffic tăng, CPU hoặc memory của ECS Service tăng. CloudWatch thu thập metric và alarm chuyển sang ALARM nếu vượt threshold/target. Application Auto Scaling nhận tín hiệu từ scaling policy và cập nhật Desired Count của ECS Service. ECS Service tạo thêm Task mới. Task mới được ALB health check. Khi healthy, Target Group nhận task mới và ALB bắt đầu chia traffic. Khi tải giảm, scale-in có thể giảm Desired Count nhưng không thấp hơn Min Capacity.

---

## 88. Vì sao container phải stateless?

**Trả lời chuẩn:**
ECS Task có thể bị stop, recreate, deploy mới hoặc scale in/out bất cứ lúc nào. Task mới thường có IP mới và local filesystem/RAM mất hết. Vì vậy app không nên lưu session, cache quan trọng hoặc uploaded files trong container. State nên đưa ra external services như RDS, Redis, S3 hoặc DynamoDB.

---

## 89. Nếu deployment lỗi thì user có bị ảnh hưởng không?

**Trả lời chuẩn:**
Nếu rolling update và circuit breaker cấu hình đúng, user thường không bị ảnh hưởng. ALB vẫn forward traffic tới task cũ healthy. Task mới fail health check sẽ không nhận traffic. Nếu fail liên tục, ECS rollback về revision cũ.

---

## 90. Làm sao debug khi user báo API lỗi 502/503?

**Trả lời chuẩn:**
Check theo thứ tự:

1. ALB listener.
2. Target Group health.
3. ECS Service events.
4. Running/Pending task count.
5. Task logs trong CloudWatch.
6. Task Definition image/port.
7. Security Group ALB → ECS.
8. Health check path.
9. Application exception.
10. RDS/network dependency nếu app cần DB.

---

## 91. Làm sao debug khi ECS task không start?

**Trả lời chuẩn:**
Check ECS Service Events, Task stopped reason, CannotPullContainerError, ECR image tag, Execution Role, Subnet/NAT/VPC Endpoint, CPU/memory setting, env/secrets, container startup command.

---

## 92. Làm sao debug khi task running nhưng ALB unhealthy?

**Trả lời chuẩn:**
Check health check path, health check port, app có listen đúng port không, `ASPNETCORE_URLS`, Security Group ALB SG → ECS SG, app trả 200 hay 500, timeout, container logs.

---

## 93. Vì sao ALB Target Type là IP với Fargate?

**Trả lời chuẩn:**
Fargate không expose EC2 instance cho người dùng. Mỗi Task có ENI/private IP riêng, Target Group register IP của Task.

---

## 94. Vì sao secret không nên để plaintext trong Task Definition?

**Trả lời chuẩn:**
Secret plaintext có thể bị lộ qua console, logs, Terraform state hoặc người có quyền xem task definition. Production nên dùng AWS Secrets Manager hoặc SSM Parameter Store.

---

## 95. Nếu NAT Gateway bị xóa thì ECS có chết không?

**Trả lời chuẩn:**
Task đang chạy có thể vẫn phục vụ traffic nội bộ/ALB/RDS nếu không cần Internet. Nhưng task mới có thể không pull image được nếu không có VPC Endpoint. App cũng không gọi được API ngoài như Stripe, PayPal, OpenAI.

---

## 96. Nếu RDS SG allow `0.0.0.0/0` thì sao?

**Trả lời chuẩn:**
Rủi ro bảo mật lớn vì mọi IP có thể thử kết nối RDS. Production nên chỉ allow từ ECS SG hoặc bastion/VPN SG nếu cần admin access.

---

## 97. Nếu ECS SG không allow ALB SG thì sao?

**Trả lời chuẩn:**
ALB nhận request từ Internet nhưng không forward được tới ECS Task. Target Group sẽ unhealthy hoặc request trả 502/503 tùy tình huống.

---

## 98. Nếu container listen port 5000 nhưng Target Group port 8080 thì sao?

**Trả lời chuẩn:**
Health check và request sẽ fail vì ALB gửi đến port không có app listen. Target unhealthy.

---

## 99. Vì sao Lab dùng 2 Tasks?

**Trả lời chuẩn:**
2 tasks giúp high availability cơ bản. Nếu một task chết, task còn lại vẫn phục vụ. Nó cũng giúp rolling update ít downtime hơn và phân phối qua 2 AZ.

---

## 100. Tóm tắt toàn bộ Lab 04 → Lab 08 trong 1 câu

**Trả lời chuẩn:**
Em đã xây và hiểu một nền tảng AWS ECS end-to-end: network được thiết kế bằng VPC, public/private subnets, route table, IGW, NAT và security group; ứng dụng chạy trên ECS Fargate bằng Service, Task Definition và Task; traffic đi qua ALB và Target Group với health check; logs và metrics được quan sát qua CloudWatch; Auto Scaling điều chỉnh Desired Count dựa trên metrics; CI/CD dùng GitHub Actions OIDC để build image, push ECR, render task definition và deploy ECS bằng rolling update không SSH vào server.

---

# Quick Cheat Sheet

## Lab 04

```text
VPC = network boundary
Subnet = network segment
Route Table = đường đi
IGW = public internet gateway
NAT = outbound internet for private subnet
SG = stateful firewall on resource
NACL = stateless firewall on subnet
```

## Lab 05

```text
Cluster → Service → Task → Container
Task Definition = run spec
Revision = version của run spec
Service = desired state manager
Task = disposable runtime unit
```

## Lab 06

```text
Logs = chuyện gì xảy ra
Metrics = hệ thống khỏe không
Traces = request đi qua đâu
CloudWatch Logs = stdout/stderr của container
```

## Lab 07

```text
Metric → Alarm → Application Auto Scaling → Desired Count → ECS Service → Tasks
```

## Lab 08

```text
Git Push → GitHub Actions → OIDC → IAM Role → Docker Build → ECR → Task Definition Revision → ECS Update Service → Rolling Update
```

---

# English Speaking Practice

## Explain VPC

A VPC is a private network in AWS where I can isolate and control my application resources. Inside the VPC, I create public subnets for the load balancer, private app subnets for ECS tasks, and private data subnets for RDS.

## Explain ECS

In ECS, a cluster is a logical boundary. A service maintains the desired number of tasks. A task is the runtime unit, and each task runs one or more containers.

## Explain CI/CD

When I push code to GitHub, GitHub Actions runs the pipeline. It assumes an AWS IAM role through OIDC, builds a Docker image, pushes it to ECR, renders a new ECS task definition, and updates the ECS service. ECS then performs a rolling update and only sends traffic to healthy tasks.

## Explain Auto Scaling

ECS Auto Scaling uses CloudWatch metrics and alarms. When CPU or memory increases, Application Auto Scaling updates the desired count of the ECS service. ECS then creates new tasks, and once they pass the load balancer health check, they start receiving traffic.

---

# Final Mindset

Không học AWS theo kiểu nhớ tên dịch vụ.

Học theo flow:

```text
Request đi đâu?
Deploy đi đâu?
Log đi đâu?
Metric đi đâu?
Scale xảy ra thế nào?
Security chặn ở đâu?
Rollback xảy ra thế nào?
```

Đây là mindset của Platform Engineer.
