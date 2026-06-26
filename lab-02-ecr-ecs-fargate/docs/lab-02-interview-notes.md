# AWS Lab #2 - Key Concepts & Interview Notes

## 1. Tại sao Dockerfile cần Multi-stage Build?

Stage `build` dùng SDK image (nặng, có compiler) chỉ để compile và publish code.

Stage `runtime` dùng ASP.NET runtime image (nhẹ hơn nhiều) để chạy.

Image cuối cùng chỉ copy phần `publish` từ stage build sang, không có source code hay SDK — nhỏ gọn hơn và giảm bề mặt tấn công (ít tool, ít thư viện không cần thiết trong image production).

### Keywords

* Multi-stage Build
* Build Stage vs Runtime Stage
* Image Size
* Attack Surface

---

## 2. ECS Fargate khác EC2 (Lab 1) như thế nào?

EC2 là compute cố định — phải tự chọn instance, tự quản lý OS, tự cài Agent.

ECS Fargate là serverless container compute — không cần quản lý node/instance, chỉ cần định nghĩa Task Definition (CPU/Memory/Image), AWS tự cấp phát compute cho từng task.

### Keywords

* Serverless Compute
* Task Definition
* Self-managed vs AWS-managed
* Container Orchestration

---

## 3. Tại sao ECS cần 2 IAM Role thay vì 1 như EC2?

EC2 chỉ có 1 Instance Role duy nhất, dùng chung cho cả hạ tầng và ứng dụng.

ECS Fargate tách rõ 2 vai trò:

* **Task Execution Role** — quyền của hạ tầng ECS, để pull image từ ECR và ghi log lên CloudWatch.
* **Task Role** — quyền của chính ứng dụng đang chạy bên trong container, ví dụ gọi S3.

Tách riêng giúp áp dụng Least Privilege chi tiết hơn: hạ tầng khởi động container không cần quyền gọi S3, và ứng dụng không cần quyền pull image.

### Keywords

* Task Execution Role
* Task Role
* Least Privilege
* Separation of Duties

---

## 4. Tại sao Target Group phải dùng Target Type "IP addresses" thay vì "Instance"?

Fargate task không phải là EC2 instance cố định — mỗi task có network interface và IP riêng, có thể thay đổi khi task bị restart hoặc thay thế.

Target Type "Instance" giả định target là một EC2 instance ổn định, không phù hợp với Fargate. Target Type "IP addresses" cho phép ALB route trực tiếp đến IP hiện tại của từng task.

### Keywords

* Target Type
* IP Target
* awsvpc Network Mode
* Ephemeral IP

---

## 5. Tại sao Security Group của ECS Tasks chỉ cho phép từ ALB Security Group?

Container chỉ nên nhận traffic đã đi qua ALB, không nên expose thẳng container port ra Internet.

Bằng cách reference Security Group của ALB (`csnp-alb-sg`) thay vì `0.0.0.0/0`, chỉ traffic đã qua ALB mới chạm được container port 5000 — traffic public chỉ vào được qua ALB port 80.

### Keywords

* Security Group Reference
* Defense in Depth
* Network Isolation
* Application Tier

---

# Tóm tắt phỏng vấn trong 30 giây

"Tôi container hóa Wallet API bằng Docker multi-stage build để image gọn và an toàn hơn, sau đó push lên ECR và deploy qua ECS Fargate — serverless, không cần tự quản lý node. ECS tách IAM thành Task Execution Role cho hạ tầng và Task Role cho ứng dụng, áp dụng Least Privilege chi tiết hơn EC2. Traffic vào qua Application Load Balancer với Target Type IP addresses vì Fargate task không có IP cố định, và Security Group của container chỉ chấp nhận traffic từ ALB, không mở thẳng ra Internet."

---

## 6. CloudWatch Logs ở ECS khác EC2 (Lab 1) như thế nào?

Ở Lab 1, phải tự cài CloudWatch Agent và config file để đọc `/var/log/app/application.log` rồi gửi lên CloudWatch.

Ở ECS, chỉ cần khai báo log driver `awslogs` trong Task Definition. ECS tự động gửi `stdout`/`stderr` của container lên CloudWatch ngay khi container start, không cần Agent hay config thủ công.

### Keywords

* awslogs Driver
* Centralized Logging
* No Agent Required
* Container Logging

---

## 7. Tại sao Desired Count = 2 quan trọng?

Lab 1 chỉ chạy 1 EC2 instance — một điểm lỗi duy nhất (single point of failure), nếu instance crash thì app down cho đến khi can thiệp thủ công.

ECS Service với Desired Count = 2 chạy song song 2 task. Nếu 1 task crash, ECS tự khởi động task mới để duy trì đúng số lượng mong muốn — đây là cơ chế self-healing.

### Keywords

* Desired Count
* High Availability
* Self-healing
* Single Point of Failure

---

## 8. Application Load Balancer hoạt động ở Layer nào?

ALB hoạt động ở Layer 7 (Application Layer) — hiểu được HTTP, có thể route theo path, host header, và thực hiện health check ở tầng application (ví dụ gọi `/health`).

Khác với Network Load Balancer (Layer 4), chỉ route theo IP/port mà không hiểu nội dung HTTP.

### Keywords

* Layer 7 Load Balancing
* ALB vs NLB
* Path-based Routing
* Health Check

---

## 9. Tại sao Container chạy port 5000 nhưng ALB nghe port 80?

Giống lý do ở Lab 1 (port nhỏ hơn 1024 là Privileged Port), container vẫn chạy ở port không privileged như 5000.

ALB đứng giữa, lắng nghe public port 80 (hoặc 443 cho HTTPS) và forward nội bộ sang container port 5000 qua Target Group. Client gọi ALB không cần biết container đang chạy port nào.

### Keywords

* Privileged Ports
* Listener
* Target Group Port Mapping
* Reverse Proxy Pattern

---

## 10. Tại sao phải tạo Security Group rule mới cho RDS thay vì dùng lại rule của EC2?

Fargate task chạy ở network mode `awsvpc`, mỗi task có network interface (ENI) riêng, không dùng chung IP hay Security Group với EC2 instance ở Lab 1.

Vì vậy RDS Security Group cần thêm rule mới cho phép Security Group của ECS Tasks (`csnp-ecs-sg`) truy cập port 5432, bên cạnh rule cũ của EC2 nếu vẫn còn dùng.

### Keywords

* awsvpc Network Mode
* Elastic Network Interface (ENI)
* Security Group Reference
* Multi-source Access Rule

---

## 11. Tại sao cần Access Key tạm thời khi test local, trong khi cả lab đều dùng IAM Role?

Máy local không có Instance Metadata Service (IMDS) như EC2, và không có Task Role như Fargate, nên không thể lấy Temporary Credentials qua các cơ chế đó.

Đây là **ngoại lệ duy nhất** trong toàn bộ lab — dùng Access Key tạm thời chỉ để test container chạy local trước khi push lên ECR. Khi deploy lên Fargate, container sẽ dùng Task Role thật, không cần Access Key. Access Key tạm này nên được revoke ngay sau khi test xong.

### Keywords

* Local Testing Exception
* Temporary Access Key
* IMDS Unavailable Locally
* Task Role

---

## 12. ECS Task Definition khác ECS Service như thế nào?

Task Definition là **blueprint** — định nghĩa image, CPU/Memory, port, environment variables, IAM roles, logging config cho một loại task.

ECS Service là **trình quản lý vòng đời** — giữ cho đúng số lượng task (Desired Count) luôn chạy dựa trên Task Definition, gắn với Load Balancer, và tự thay task chết.

Quan hệ tương tự Docker image (blueprint) và container đang chạy (instance), nhưng ở tầng orchestration cao hơn.

### Keywords

* Task Definition
* ECS Service
* Blueprint vs Runtime State
* Desired State Management

---

## 13. Khi nào chọn ECS Fargate, khi nào chọn EKS?

| | ECS Fargate | EKS |
| - | ----------- | --- |
| Control plane | AWS quản lý, không trả phí riêng | $0.10/giờ cho control plane |
| Quản lý node | Không cần, serverless | Cần quản lý node group hoặc Fargate profile |
| Learning curve | Thấp, chỉ cần hiểu Task Definition | Cao, cần hiểu kubectl, manifests, RBAC |
| Phù hợp | Team nhỏ, ít service, ship nhanh | Team lớn, nhiều service, cần K8s ecosystem |

ECS Fargate phù hợp khi muốn đơn giản, rẻ ở quy mô nhỏ-vừa, không cần đội riêng vận hành control plane. EKS đáng dùng khi đã có nhiều cluster/multi-cloud hoặc cần hệ sinh thái K8s (Helm, Operators).

### Keywords

* ECS vs EKS
* Control Plane
* Learning Curve
* Workload Fit

---

## 14. ECS Fargate map sang khái niệm Kubernetes như thế nào?

Với người đã quen self-hosted K8s, có thể map trực tiếp:

* ECS Service ≈ Kubernetes Deployment
* Application Load Balancer ≈ Ingress Controller
* Task Definition ≈ Pod Spec
* Desired Count ≈ `replicas` trong Deployment

Khác biệt lớn nhất: AWS quản lý control plane hộ mình ở ECS Fargate, còn self-hosted K8s phải tự vận hành control plane.

### Keywords

* ECS to Kubernetes Mapping
* Deployment
* Ingress Controller
* Pod Spec

---

## 15. Tại sao không nên để DB_PASSWORD ở dạng plain text trong Task Definition?

Environment variable dạng plain text trong Task Definition có thể bị xem trực tiếp qua AWS Console hoặc qua log, ai có quyền đọc Task Definition cũng đọc được password.

Cách tốt hơn là dùng AWS Secrets Manager reference trong Task Definition — ECS sẽ lấy giá trị thật tại runtime mà không lưu plain text trong definition.

### Keywords

* Secrets Manager
* Plain Text Secret
* Task Definition Security
* Runtime Secret Injection

---

## 16. Self-healing trong ECS hoạt động như thế nào khi 1 task bị crash?

ECS Service liên tục theo dõi số task đang `RUNNING` so với Desired Count đã khai báo.

Nếu 1 task bị stop hoặc health check fail liên tục, ECS sẽ tự dừng task đó và khởi động task mới để duy trì đúng Desired Count — không cần can thiệp thủ công, khác hẳn với việc 1 EC2 instance chết ở Lab 1.

### Keywords

* Self-healing
* Desired Count Reconciliation
* Health Check Failure
* Service Scheduler

---

# Tóm tắt phỏng vấn trong 60 giây

"Tôi dockerize Wallet API bằng multi-stage build rồi push image lên ECR. Trên ECS Fargate, tôi tách IAM thành Task Execution Role cho hạ tầng và Task Role cho ứng dụng, thay vì 1 role duy nhất như EC2. Service chạy với Desired Count = 2 đứng sau Application Load Balancer, Target Group dùng Target Type IP addresses vì mỗi Fargate task có IP riêng không cố định. Security Group của container chỉ chấp nhận traffic từ ALB, và RDS có thêm rule riêng cho Security Group của ECS Tasks vì Fargate dùng network mode awsvpc, không chung IP với EC2. CloudWatch nhận log tự động qua awslogs driver, không cần cài Agent như Lab 1. Khi 1 task crash, ECS Service tự khởi động task mới để duy trì Desired Count — đây là self-healing, khác hẳn với EC2 đơn lẻ ở Lab 1. So với self-hosted Kubernetes, ECS Service tương đương Deployment, ALB tương đương Ingress Controller, Task Definition tương đương Pod Spec, nhưng AWS quản lý control plane hộ mình."
