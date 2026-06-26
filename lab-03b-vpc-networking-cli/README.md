# Lab 03B - VPC Networking (CLI)

## Mục tiêu

Phần tiếp theo của Lab 3A — chuyển từ **AWS Console** sang **AWS CLI** để hiểu Console thực chất gọi những API AWS nào, và quen cú pháp CLI trước khi viết Terraform ở Lab 4.

Sau lab này cần hiểu được:

* AWS CLI command structure: `aws service action --parameters`
* Resource ID (VPC ID, Subnet ID, Route Table ID) — CLI không tự nhớ context, phải truyền thủ công
* API dependency — khi xoá VPC, phải disassociate Route Table trước, xoá Subnet, rồi mới xoá VPC
* CLI output format (JSON) — từ dó extract ID dùng cho lệnh tiếp theo
* So sánh logic Console ≡ CLI: Console che giấu dependency, CLI phơi bày rõ ràng

## Prerequisites

* Đã hoàn thành **Lab 3A** (hiểu rõ VPC/Subnet/Route Table/NAT concept bằng tay Console)
* AWS CLI **phiên bản >= 2.0** cài sẵn ([download](https://aws.amazon.com/cli/))
* AWS CLI đã configure: `aws configure` hoặc IAM Identity Center SSO
* AWS Region: **us-east-1**
* Quyền EC2: CreateVpc, CreateSubnet, CreateRouteTable, AssociateRouteTable, DeleteVpc (...)

> **IMPORTANT:** Lab 3B tạo VPC **test riêng** (`10.20.0.0/16` - CLI Learning Sandbox) — **KHÔNG can thiệp tới VPC chính** (`10.10.0.0/16` ở Lab 3A). Sau lab xong, xoá VPC test ngay.

## Architecture

Lab 3B không build full network như Lab 3A. Chỉ tạo **minimal resources** để minh hoạ API:

```text
VPC Test (10.20.0.0/16)
    ↓
Subnet (10.20.1.0/24)
    ↓
Route Table + Association
    ↓
(sau đó xoá toàn bộ để học cleanup)
```

## AWS Services

| Service | Vai trò |
| ------- | ------- |
| EC2 (VPC API) | `create-vpc`, `create-subnet`, `create-route-table`, `associate-route-table`, `delete-*` |
| AWS CLI | Client để gọi API thay vì qua Console |
| IAM | Permission để thực thi EC2 API (quyền `ec2:*` hoặc specific action) |

## Chi phí

Tạo VPC, Subnet, Route Table — **free** (không charge khi không có resource chạy trong đó). **Chi phí chỉ phát sinh khi thêm resources như NAT Gateway, EC2, RDS.**

## Region

`us-east-1`

## Lessons Learned (Preview)

* Console và CLI gọi **cùng một API AWS** — khác biệt là Console tự lưu context, CLI để bạn quản lý thủ công
* **Dependency Management**: Thứ tự xoá ngược với thứ tự tạo — nếu quên, AWS báo lỗi "VPC has dependencies"
* CLI output là JSON — dễ dàng parse với `--query` để extract ID cho lệnh tiếp theo
* **Transition Point**: Sau Lab 3B (CLI), bạn sẽ thấy tại sao Lab 4 (Terraform) tự động hoá bước này — Terraform tự tính dependency graph, tự quyết định thứ tự tạo/xoá

## Nội dung Chi tiết

| File | Mục đích |
| --- | --- |
| [lab-03b-hands-on.md](./docs/lab-03b-hands-on.md) | Step-by-step: tạo VPC test → verify → cleanup bằng CLI |
| [lab-03b-interview-notes.md](./docs/lab-03b-interview-notes.md) | Q&A về CLI, API, dependency management |
| [lab-03b-verification.md](./docs/lab-03b-verification.md) | Checklist verify sau mỗi step |

## Chuẩn bị

* Mở terminal (PowerShell / Bash / WSL2)
* Chạy `aws --version` → verify AWS CLI 2.x cài sẵn
* Chạy `aws sts get-caller-identity` → verify AWS CLI configure đúng
* Sẵn sàng lấy từng VPC/Subnet ID từ output và lưu vào `export` variable

## Trạng thái

Đây là lab **hands-on** — yêu cầu chạy terminal commands. Ước tính 20-30 phút để xong (tạo + cleanup).
