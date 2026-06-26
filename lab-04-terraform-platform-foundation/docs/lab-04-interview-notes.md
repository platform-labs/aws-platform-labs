# AWS Lab #4 - Key Concepts & Interview Notes

> Lab 4 tái sử dụng toàn bộ khái niệm VPC/Subnet/NAT/Route Table đã ghi ở [`lab-03a-vpc-networking-console/docs/lab-03-interview-notes.md`](../../lab-03a-vpc-networking-console/docs/lab-03-interview-notes.md) — không lặp lại ở đây. File này chỉ ghi các khái niệm mới phát sinh khi đưa network đó vào Terraform.

## 1. Terraform credential khác AWS Console login session như thế nào?

Console login (kể cả qua IAM Identity Center/SSO) cấp một session token tạm thời gắn với trình duyệt. Terraform chạy như một CLI process độc lập, cần đọc credential từ một nguồn riêng — thường là Access Key/Secret Key của IAM User (`~/.aws/credentials`), hoặc một AssumeRole/SSO profile được cấu hình rõ trong `~/.aws/config`.

Đây là lý do `terraform apply` báo lỗi "no valid credential sources" dù vẫn đang đăng nhập Console bình thường trên trình duyệt — hai cơ chế xác thực không tự động chia sẻ với nhau.

### Keywords

* IAM User Access Key
* Session Token vs Long-lived Credential
* `~/.aws/credentials`
* AWS Provider Credential Chain

---

## 2. Tại sao dùng IAM User riêng (`terraform-cli`) thay vì IAM Role?

IAM User với Access Key là cách đơn giản nhất cho máy cá nhân/lab — phù hợp khi chạy Terraform từ laptop, không qua CI/CD. IAM Role (qua AssumeRole, hoặc gắn vào EC2 Instance Profile nếu chạy Terraform từ một EC2/CI runner) là cách production thật dùng, vì Role cấp credential tạm thời, tự xoay vòng (rotate), không bị "treo" vĩnh viễn như Access Key của User.

Trong CI/CD pipeline thật (ví dụ GitHub Actions ở Lab 8), nên dùng OIDC + AssumeRole thay vì lưu Access Key dạng secret — tránh rủi ro rò Access Key tồn tại lâu dài.

### Keywords

* IAM User vs IAM Role
* Long-lived vs Temporary Credential
* OIDC + AssumeRole (CI/CD)
* Credential Rotation

---

## 3. Terraform State là gì, tại sao quan trọng?

State (`terraform.tfstate`) là file Terraform dùng để map giữa resource khai báo trong code (`.tf`) và resource thật đã tồn tại trên AWS. Không có State, Terraform không biết resource nào đã tạo, dẫn tới tạo trùng hoặc không biết để update/destroy đúng resource.

Lab 4 dùng **remote state** trên S3 và DynamoDB lock, với key riêng `aws/lab-04/terraform.tfstate`. Cách này tránh phụ thuộc vào một máy cá nhân, giữ version history của state và ngăn hai tiến trình apply cùng lúc. Bucket labs tách biệt hoàn toàn với backend production.

### Keywords

* terraform.tfstate
* Local State vs Remote State
* State Locking (DynamoDB)
* Single Source of Truth

---

## 4. Vì sao Lab 4 không `-target` từng resource mà apply 1 lần?

Terraform tự build dependency graph từ các reference ngầm trong code (ví dụ `aws_subnet` reference `aws_vpc.main.id`) — không cần khai báo thứ tự tạo thủ công như khi làm CLI ở Lab 3B. `terraform apply` một lần sẽ tự tạo theo đúng thứ tự: VPC → IGW → Subnet → EIP → NAT Gateway → Route Table → Association → Security Group.

`-target` chỉ nên dùng khi cần áp dụng/troubleshoot một phần nhỏ (ví dụ Lab 5 dùng `-target=aws_ecr_repository.wallet_api` để lấy URL ECR sớm trước khi build image) — không nên dùng `-target` làm cách vận hành chính, vì dễ khiến state lệch khỏi toàn bộ cấu hình thật.

### Keywords

* Dependency Graph
* Implicit Dependency (resource reference)
* `-target` flag (dùng hạn chế)
* Declarative vs Imperative

---

## 5. `count = length(var.azs)` giải quyết vấn đề gì so với viết tay từng resource?

Nếu viết tay, mỗi AZ cần lặp lại y nguyên 1 block `aws_subnet`, chỉ khác `cidr_block` và `availability_zone` — vi phạm DRY rõ ràng. Dùng `count` với list variable index-aligned (`var.azs`, `var.public_subnet_cidrs`,...) cho phép 1 block resource sinh ra N resource thật, mỗi resource lấy giá trị tại đúng index của nó.

Rủi ro: nếu các list không cùng length, Terraform báo lỗi ngay ở bước `plan`, không chờ tới `apply` — đây là điểm khác biệt so với code thường (runtime error), Terraform catch được nhiều lỗi cấu hình ngay từ giai đoạn plan.

### Keywords

* `count` meta-argument
* Index-aligned variables
* DRY (Don't Repeat Yourself)
* Plan-time validation

---

# Tóm tắt phỏng vấn trong 60 giây

"Trước khi Terraform có thể gọi AWS API, tôi cấu hình AWS CLI credentials riêng vì session đăng nhập Console không tự được CLI/Terraform sử dụng. Với môi trường công ty, tôi ưu tiên IAM Role, SSO hoặc OIDC thay vì Access Key dài hạn. Lab 4 lưu state trên S3, bật versioning/encryption và dùng DynamoDB lock; key của lab tách biệt khỏi production. Tôi dùng `count` với list variable index-aligned để tạo subnet theo từng AZ mà không lặp code, và để Terraform tự tính dependency graph thay vì tự sắp thứ tự bằng `-target` như khi làm CLI thủ công."
