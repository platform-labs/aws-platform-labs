# AWS Hands-on Lab #1

## Deliberate practice loop

1. **Mental model:** tự vẽ Internet → EC2 → RDS/S3 và EC2 role → AWS APIs trước khi xem Architecture.
2. **Console discovery:** lượt đầu tạo theo Console walkthrough; từ lượt sau chỉ dùng Console quan sát resource Terraform tạo.
3. **Implementation:** hoàn thành IAM, S3, EC2, RDS, application và CloudWatch theo các step bên dưới.
4. **CLI verification:** describe EC2/RDS/role/log group và gọi S3 từ EC2 mà không có access key.
5. **Failure drill:** lần lượt chặn RDS SG và gỡ quyền S3 khỏi role; ghi symptom, log và cách phục hồi.
6. **Rebuild without guide:** terminate/destroy rồi dựng lại chỉ bằng architecture và validation checklist.
7. **Cleanup/cost audit:** ưu tiên RDS/EC2/EBS; xác nhận không còn volume, snapshot hoặc bucket ngoài ý muốn.
8. **Interview recap:** tự trả lời traffic path, credential chain, SG reference và resource nào tính tiền khi idle.

Quy tắc luyện nhiều vòng: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## Deploy Wallet API lên AWS với EC2 + RDS PostgreSQL + S3 + IAM Role + CloudWatch

### Mục tiêu

Sau lab này cần hiểu được:

* IAM Role
* EC2
* Security Group
* RDS PostgreSQL
* S3
* CloudWatch Logs

Đây là các service nền tảng được sử dụng trong phần lớn workload AWS.

---

# Architecture

```text
                 Internet
                      |
                      v
               Security Group (csnp-ec2-sg)
                      |
                      v
                 EC2 t3.micro
                      |
       +--------------+-------------+
       |                            |
       v                            v
  RDS PostgreSQL               S3 Bucket
  (csnp-rds-sg)             (csnp-wallet-dev)
  Private, no public access

                      |
                      v
               CloudWatch Logs
               (csnp-wallet-api)
```

---

# Prerequisites

* AWS Account mới
* Credit AWS còn khả dụng
* AWS Region: **us-east-1**
* .NET SDK 10 cài sẵn trên máy local

> **Lưu ý:** Lab này dùng WalletMinimal — một minimal API .NET tạo mới, không dùng Wallet API từ CSNP vì CSNP có nhiều dependencies (RabbitMQ, Redis, Kafka) chưa có trong lab này.

---

# Cost Warning

Những resource tốn tiền cần tắt ngay sau khi lab xong:

| Resource | Chi phí ước tính |
| -------- | ---------------- |
| EC2 t3.micro | Free Tier 750h/tháng |
| RDS db.t3.micro | Free Tier 750h/tháng |
| NAT Gateway | ~$32/tháng — **không dùng trong lab này** |
| EBS Volume | Kiểm tra sau terminate, xóa nếu state = available |

Set AWS Budget alert tại $10 để cảnh báo sớm.

---

# Step 1 - Tạo IAM Role cho EC2

## Tại sao cần IAM Role?

EC2 mặc định không có quyền gì với các service AWS khác. Muốn EC2 gọi S3 hay CloudWatch thì phải gắn IAM Role.

**Không dùng Access Key** — Access Key là credential tĩnh, nếu lộ (commit git, log console) là mất toàn bộ account. IAM Role dùng credential tạm thời, AWS tự rotate mỗi vài giờ.

## Create Role

IAM → Roles → Create Role

### Trusted Entity

```text
AWS Service → EC2
```

### Attach Policies

```text
AmazonS3FullAccess
CloudWatchAgentServerPolicy
```

> **Note:** `AmazonS3FullAccess` dùng cho lab. Production nên thay bằng custom policy chỉ cho phép đúng bucket và đúng action (Least Privilege).

### Role Name

```text
csnp-api-role
```

---

# Step 2 - Tạo S3 Bucket

S3 → Create Bucket

```text
Bucket name: csnp-wallet-dev
Region: us-east-1 (cùng region với EC2)
```

## Settings

| Setting | Value |
| ------- | ----- |
| Versioning | Enable |
| Block Public Access | Giữ nguyên (enabled) |
| Object ownership | ACLs disabled (default) |

Bucket phải private — không có public access.

---

# Step 3 - Launch EC2

## Instance Settings

| Field | Value |
| ----- | ----- |
| Name | csnp-api-dev |
| AMI | Amazon Linux 2023 |
| Instance type | t3.micro |
| Key pair | Tạo mới → lưu file `.pem` cẩn thận |
| Storage | 20 GB |
| IAM instance profile | csnp-api-role |

> **Quan trọng:** Attach IAM Role ngay khi tạo EC2 ở mục **Advanced details → IAM instance profile**. Nếu quên, phải stop instance rồi attach lại.

## Security Group

Đặt tên custom thay vì để AWS tự đặt `launch-wizard-x`:

```text
Security group name: csnp-ec2-sg
```

> **Lưu ý:** Security Group name là immutable sau khi tạo. Chỉ có thể đổi Name tag sau này. Nên đặt đúng ngay từ đầu.

### Inbound Rules

| Port | Protocol | Source | Lý do |
| ---- | -------- | ------ | ----- |
| 22 | TCP | My IP | SSH — chỉ mở IP máy anh, không mở 0.0.0.0/0 |
| 80 | TCP | 0.0.0.0/0 | HTTP public (dùng cho Lab 2 khi có Nginx/reverse proxy) |
| 443 | TCP | 0.0.0.0/0 | HTTPS public |
| 5000 | TCP | My IP | Kestrel trực tiếp — lab này, test từ máy local |

> **Security:** Port 22 phải là My IP, không phải 0.0.0.0/0. Nếu mở 0.0.0.0/0 thì cả internet đều SSH được vào EC2.

---

# Step 4 - Tạo RDS PostgreSQL

RDS → Create Database → **Create with full configuration**

> Không chọn "Create with express configuration" — đó là Aurora Serverless, không nằm trong Free Tier và tốn credits nhanh hơn.

## Settings

| Field | Value | Lý do |
| ----- | ----- | ----- |
| Engine | PostgreSQL 16 | — |
| Template | **Free tier** | Tránh tốn tiền |
| DB instance identifier | csnp-wallet-dev | — |
| Master username | postgres | — |
| Instance class | db.t3.micro | Free Tier eligible |
| Storage | 20 GB | — |
| Storage autoscaling | **Disable** | Tránh tự scale lên tốn tiền |
| Availability | Single-AZ | Multi-AZ không cần thiết cho lab |
| Public access | **No** | — |
| VPC security group | Create new → `csnp-rds-sg` | — |
| Initial database name | wallet | Phải điền, nếu không RDS không tạo sẵn database |
| Backup retention | 0 days | Lab thôi, không cần backup |
| Performance Insights | **Disable** | Free 7 ngày, sau đó tính tiền |
| Enhanced Monitoring | **Disable** | Không cần cho lab |
| Auto minor version upgrade | Enable | Giữ nguyên — patch nhỏ, free, không breaking |

## Security Group cho RDS

Sau khi RDS tạo xong, vào `csnp-rds-sg` → Edit inbound rules:

| Port | Source | Lý do |
| ---- | ------ | ----- |
| 5432 | Security Group ID của EC2 (`sg-xxxxxxxxx`) | Chỉ EC2 mới được connect RDS |

**Không mở** `0.0.0.0/0` cho port 5432.

**Không mở My IP** cho port 5432 — RDS Public access: No nên máy local không connect được dù có mở IP.

---

# Step 5 - Verify IAM Role

SSH vào EC2:

```bash
ssh-keygen -R EC2-PUBLIC-IP
ssh -i "C:\Users\Toan\.ssh\wallet-dev-key.pem" ec2-user@EC2-PUBLIC-IP
```

> Chạy lệnh này trong **PowerShell trên Windows**, không dùng Git Bash (authentication context issue).

## Verify IAM Role

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
    "UserId": "AROAXXXXXXXXX:i-xxxxxxxxx",
    "Account": "<AWS_ACCOUNT_ID>",
    "Arn": "arn:aws:sts::<AWS_ACCOUNT_ID>:assumed-role/csnp-api-role/i-xxxxxxxxx"
}
```

Thấy `csnp-api-role` trong ARN là thành công.

## Verify S3 Access

```bash
echo hello > test.txt
aws s3 cp test.txt s3://csnp-wallet-dev/
```

Expected:

```text
upload: ./test.txt to s3://csnp-wallet-dev/test.txt
```

Nếu upload được → EC2 đã nhận IAM Role đúng cách, không cần Access Key.

## Verify EC2 → RDS Connectivity

Cài PostgreSQL client:

```bash
sudo yum install -y postgresql15
```

Connect vào RDS:

```bash
psql -h <RDS-ENDPOINT> \
     -U postgres \
     -d wallet
```

Expected: prompt `wallet=>` với SSL connection TLSv1.3.

Test trong psql:

```sql
\dt
-- Output: Did not find any relations.
-- Bình thường vì chưa có table

\q
-- Thoát
```

---

# Step 6 - Tạo WalletMinimal API

> **Tại sao không dùng Wallet API từ CSNP?**
> Wallet API của CSNP yêu cầu RabbitMQ, Redis, Kafka — những service chưa có trong lab này. App sẽ crash ngay khi start vì thiếu dependencies. Lab này tạo một minimal API chỉ dùng PostgreSQL + S3.

## Tạo Project trên máy local

```bash
dotnet new webapi -n WalletMinimal --no-openapi
cd WalletMinimal
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package AWSSDK.S3
dotnet add package AWSSDK.Extensions.NETCore.Setup
```

## Program.cs

```csharp
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Amazon.S3;
using Amazon.S3.Model;

var builder = WebApplication.CreateBuilder(args);

// Database — đọc từ environment variable
var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
var dbPort = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
var dbName = Environment.GetEnvironmentVariable("DB_NAME") ?? "wallet";
var dbUser = Environment.GetEnvironmentVariable("DB_USER") ?? "postgres";
var dbPass = Environment.GetEnvironmentVariable("DB_PASSWORD");

builder.Services.AddDbContext<WalletDb>(opt =>
    opt.UseNpgsql($"Host={dbHost};Port={dbPort};Database={dbName};Username={dbUser};Password={dbPass}"));

// S3 - dùng IAM Role, không cần AccessKey
builder.Services.AddAWSService<IAmazonS3>();

var app = builder.Build();

// Auto migrate
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<WalletDb>();
    db.Database.EnsureCreated();
}

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }));

// GET all wallets
app.MapGet("/wallets", async (WalletDb db) =>
    await db.Wallets.ToListAsync());

// POST create wallet
app.MapPost("/wallets", async (WalletDb db, Wallet wallet) =>
{
    wallet.Id = Guid.NewGuid();
    wallet.CreatedAt = DateTime.UtcNow;
    db.Wallets.Add(wallet);
    await db.SaveChangesAsync();
    return Results.Created($"/wallets/{wallet.Id}", wallet);
});

// POST upload file lên S3
app.MapPost("/upload", async (HttpRequest req, IAmazonS3 s3) =>
{
    var bucket = Environment.GetEnvironmentVariable("S3_BUCKET") ?? "csnp-wallet-dev";
    var key = $"uploads/{Guid.NewGuid()}.txt";
    await s3.PutObjectAsync(new PutObjectRequest
    {
        BucketName = bucket,
        Key = key,
        ContentBody = "Hello from CSNP Wallet API on AWS!"
    });
    return Results.Ok(new { bucket, key });
});

app.Run();

// Models
public class Wallet
{
    public Guid Id { get; set; }
    public string OwnerId { get; set; } = "";
    public decimal Balance { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class WalletDb : DbContext
{
    public WalletDb(DbContextOptions<WalletDb> options) : base(options) { }
    public DbSet<Wallet> Wallets => Set<Wallet>();
}
```

> **Quan trọng:** App đọc connection string từ environment variable. Nếu chạy `dotnet run` trên máy local mà không set `DB_HOST` thì sẽ crash với lỗi `ArgumentNullException: Value cannot be null. (Parameter 'Host')` — đây là behavior đúng, không phải bug.

## Publish

```bash
dotnet publish -c Release -o ./publish
```

---

# Step 7 - Deploy lên EC2

## Mở PowerShell Run as Administrator

```powershell
icacls .\wallet-dev-key.pem /inheritance:r
icacls .\wallet-dev-key.pem /remove "Authenticated Users"
icacls .\wallet-dev-key.pem /remove "BUILTIN\Users"
icacls .\wallet-dev-key.pem /grant:r "$($env:USERNAME):(R)"
```

## Copy artifact lên EC2

Chạy trên máy local (PowerShell):

```powershell
scp -i "C:\Users\Toan\.ssh\wallet-dev-key.pem" `
    -r ./lab-01-ec2-rds-s3-cloudwatch/src/Lab01.WalletMinimal/publish `
    ec2-user@EC2-PUBLIC-IP:/home/ec2-user/wallet-api
```

## Cài .NET Runtime trên EC2

```bash
# SSH vào EC2
ssh -i "C:\Users\Toan\.ssh\wallet-dev-key.pem" ec2-user@EC2-PUBLIC-IP
ls -lah /home/ec2-user/wallet-api
sudo yum install -y aspnetcore-runtime-10.0
```

## Set Environment Variables và chạy API

```bash
export DB_HOST=csnp-wallet-dev.cojossewwh83.us-east-1.rds.amazonaws.com
export DB_PORT=5432
export DB_NAME=wallet
export DB_USER=postgres
export DB_PASSWORD=<your-password>
export S3_BUCKET=csnp-wallet-dev
export ASPNETCORE_URLS=http://+:5000

cd /home/ec2-user/wallet-api
dotnet Lab01.WalletMinimal.dll
```

## Verify API hoạt động

> **Linux port note:** User `ec2-user` (non-root) không thể bind port < 1024. Port 80 sẽ crash. Dùng port 5000 với Kestrel trực tiếp. Production thì đặt Nginx phía trước làm reverse proxy từ 80 → 5000.

Expected khi app start thành công:

```text
Now listening on: http://[::]:5000
```

Từ máy local:

```bash
curl http://EC2-PUBLIC-IP:5000/health
# Expected: {"status":"ok","time":"..."}

curl http://EC2-PUBLIC-IP:5000/wallets
# Expected: []

curl -X POST http://EC2-PUBLIC-IP:5000/wallets \
  -H "Content-Type: application/json" \
  -d '{"ownerId":"user-001","balance":1000}'
# Expected: 201 Created với wallet object

curl -X POST http://EC2-PUBLIC-IP:5000/upload
# Expected: {"bucket":"csnp-wallet-dev","key":"uploads/xxx.txt"}
```

## Test Security Group trước khi deploy

Nếu `curl` bị timeout thay vì connection refused hoặc 404:

```text
timeout    → Security Group block port 80
conn refused → Port mở nhưng app chưa chạy (bình thường)
404        → App đang chạy, route không tồn tại (bình thường)
```

---

# Step 8 - Upload File lên S3

AWS SDK tự động lấy credential từ EC2 Instance Metadata Service thông qua IAM Role. Không cần set `AWS_ACCESS_KEY_ID` hay `AWS_SECRET_ACCESS_KEY`.

```text
EC2 Instance Metadata Service (IMDS)
↓
IAM Role: csnp-api-role
↓
Temporary credentials (auto-rotated)
↓
S3 PutObject
```

Code trong WalletMinimal đã handle qua endpoint `/upload`. Verify trên S3 console:

```text
S3 → csnp-wallet-dev → uploads/ → thấy file .txt
```

---

# Step 9 - CloudWatch Logs

## Install Agent

```bash
sudo yum install -y amazon-cloudwatch-agent
```

## Tạo Config File

```bash
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

Paste config:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/application.log",
            "log_group_name": "csnp-wallet-api",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
```

## Start Agent

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s
```

## Tạo log directory và redirect app logs

```bash
sudo mkdir -p /var/log/app
sudo chown ec2-user:ec2-user /var/log/app

# Chạy app với log redirect
dotnet Lab01.WalletMinimal.dll >> /var/log/app/application.log 2>&1 &
```

## Verify trên CloudWatch Console

```text
CloudWatch → Log groups → csnp-wallet-api → <instance-id>
```

Thấy log là thành công.

---

# Cleanup sau Lab

Để tránh tốn tiền, terminate/xóa theo thứ tự:

```text
1. EC2 → Terminate instance
2. EC2 → Volumes → kiểm tra volume state = "available" → Delete
3. RDS → Delete instance (uncheck final snapshot)
4. EC2 → Elastic IPs → Release (nếu có)
5. S3 → Empty bucket → Delete bucket (nếu không cần giữ)
```

Security Group và IAM Role có thể giữ lại cho Lab 2.

---

# Validation Checklist

## IAM

* [ ] EC2 attached IAM Role `csnp-api-role`
* [ ] No Access Key used
* [ ] `aws sts get-caller-identity` trả về ARN có `csnp-api-role`
* [ ] S3 upload từ EC2 thành công

## EC2

* [ ] Security Group `csnp-ec2-sg` với SSH port 22 chỉ mở My IP
* [ ] API deployed và accessible qua port 80
* [ ] `/health` trả về 200

## RDS

* [ ] `csnp-rds-sg` inbound rule: port 5432 từ EC2 Security Group (không phải 0.0.0.0/0)
* [ ] `psql` từ EC2 connect được vào RDS
* [ ] API đọc/ghi được database

## S3

* [ ] Upload object qua `/upload` endpoint
* [ ] Verify object xuất hiện trong S3 console

## CloudWatch

* [ ] CloudWatch Agent chạy trên EC2
* [ ] Log group `csnp-wallet-api` có log stream
* [ ] Application logs visible

---

# Lessons Learned

| Concept | Self-hosted (CSNP) | AWS |
| ------- | ------------------ | --- |
| Credentials | K8s Secret / Vault | IAM Role (no static key) |
| Firewall | Network Policy / pfSense | Security Group |
| Database | PostgreSQL on VM | RDS (managed) |
| Object Storage | MinIO / local disk | S3 |
| Logs | Loki + Promtail | CloudWatch Logs + Agent |

**Key takeaways:**

* IAM Role thay thế Access Key — không bao giờ dùng Access Key trên EC2
* Security Group là firewall layer đầu tiên trên AWS, không phải OS firewall
* RDS loại bỏ vận hành PostgreSQL thủ công (backup, patch, failover)
* S3 là object storage, không phải filesystem — không mount như NFS
* CloudWatch Agent cần config file riêng, không chỉ install là xong
* EC2 + IAM + RDS + S3 là nền tảng của phần lớn workload AWS
* Non-root user không bind được port < 1024 — production dùng Nginx làm reverse proxy (80/443 → 5000)

---

# Next Lab

Sau khi hoàn thành Lab #1:

```text
Dockerize WalletMinimal
↓
Push image lên ECR
↓
Deploy ECS Fargate
↓
Expose bằng ALB
↓
CloudWatch Metrics & Logs
```

**Mục tiêu Lab 2:** Hiểu tại sao nhiều công ty AWS chọn ECS Fargate trước khi dùng EKS — và so sánh với self-managed K8s trên Proxmox mà anh đang dùng trong CSNP.
