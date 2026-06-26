# AWS Lab #1 - Key Concepts & Interview Notes

## 1. Tại sao phải dùng IAM Role?

IAM Role cung cấp danh tính (Identity) và quyền (Permissions) cho EC2.

AWS sẽ tự cấp Temporary Credentials thông qua Instance Metadata Service (IMDS), giúp application truy cập các AWS Services như S3, CloudWatch, DynamoDB... mà không cần lưu Access Key trong source code, file config hoặc CI/CD pipeline.

### Keywords

* Identity
* Permissions
* IMDS (Instance Metadata Service)
* Temporary Credentials

---

## 2. Tại sao không dùng Access Key?

Access Key là Static Credential.

Nếu bị lộ qua Git, log, CI/CD hoặc máy developer thì attacker có thể sử dụng ngay các quyền được cấp cho Access Key đó.

IAM Role sử dụng Temporary Credentials được AWS tự động rotate định kỳ nên an toàn hơn, đồng thời không cần quản lý secret thủ công.

### Keywords

* Static Credential
* Temporary Credential
* Credential Rotation
* Least Privilege

---

## 3. Tại sao RDS Public Access = No?

Database không nên expose trực tiếp ra Internet.

RDS nên nằm trong private network và chỉ cho phép application server truy cập.

Việc giới hạn network exposure giúp giảm Attack Surface và tuân thủ nguyên tắc Defense in Depth.

### Keywords

* Private Network
* Private Subnet
* Attack Surface
* Defense in Depth

---

## 4. Tại sao Security Group của RDS chỉ cho EC2 Security Group truy cập?

Thay vì mở theo IP Address, Security Group của RDS chỉ cho phép Security Group của EC2 kết nối.

Điều này đảm bảo chỉ các EC2 thuộc nhóm ứng dụng mới có thể truy cập database, kể cả khi IP của EC2 thay đổi.

### Keywords

* Security Group Reference
* Application Tier
* Network Isolation

---

## 5. CloudWatch Agent làm gì?

CloudWatch Agent thu thập Logs, Metrics và System Information từ EC2 rồi gửi lên CloudWatch.

Trong Lab #1, Agent đọc file:

/var/log/app/application.log

và gửi dữ liệu lên CloudWatch Logs để phục vụ:

* Monitoring
* Troubleshooting
* Centralized Logging
* Observability

### Keywords

* Centralized Logging
* Metrics Collection
* Observability
* Troubleshooting

---

# Tóm tắt phỏng vấn trong 30 giây

"Tôi sử dụng IAM Role thay vì Access Key để tránh lưu Static Credentials trên EC2. RDS được cấu hình Private Access và chỉ cho phép Security Group của EC2 truy cập nhằm giảm Attack Surface. CloudWatch Agent được dùng để thu thập Logs và Metrics từ EC2, sau đó gửi lên CloudWatch phục vụ Monitoring và Troubleshooting tập trung."

---

## 6. EC2 lấy Credentials từ đâu?

Khi EC2 được attach IAM Role, application không cần Access Key.

EC2 sẽ gọi Instance Metadata Service (IMDS) để lấy Temporary Credentials do AWS cấp.

AWS tự động rotate các credentials này định kỳ nên không cần quản lý secret thủ công.

### Keywords

* IMDS (Instance Metadata Service)
* Temporary Credentials
* Credential Rotation
* IAM Role

---

## 7. IAM User khác IAM Role như thế nào?

IAM User là danh tính cố định, thường đi kèm Access Key hoặc Password.

IAM Role là danh tính tạm thời có thể được Assume bởi AWS Services, Users hoặc Applications.

Trong production, EC2 nên sử dụng IAM Role thay vì IAM User.

### Keywords

* IAM User
* IAM Role
* Assume Role
* Temporary Credentials
* Static Credentials

---

## 8. Security Group là Stateful hay Stateless?

Security Group là Stateful Firewall.

Nếu inbound request được cho phép thì response traffic sẽ tự động được cho phép mà không cần cấu hình outbound rule tương ứng.

Điều này giúp quản lý firewall đơn giản hơn.

### Keywords

* Stateful Firewall
* Inbound Rules
* Outbound Rules
* Connection Tracking

---

## 9. Security Group Reference là gì?

Thay vì mở port theo IP Address, Security Group có thể cho phép traffic từ một Security Group khác.

Trong Lab #1, RDS chỉ cho phép Security Group của EC2 truy cập PostgreSQL port 5432.

Cách này an toàn hơn và không bị ảnh hưởng khi IP của EC2 thay đổi.

### Keywords

* Security Group Reference
* Dynamic Membership
* Network Isolation
* Application Tier

---

## 10. Tại sao dùng RDS thay vì PostgreSQL trên EC2?

RDS là Managed Database Service.

AWS chịu trách nhiệm cho nhiều tác vụ vận hành như:

* Backup
* Monitoring
* Minor Version Upgrade
* Patching
* Failover (khi sử dụng Multi-AZ)

Developer tập trung vào application thay vì quản trị database server.

### Keywords

* Managed Service
* Backup
* Patching
* Monitoring
* Operational Overhead

---

## 11. Có SSH vào RDS được không?

Không.

RDS không cung cấp SSH Access như EC2.

Application hoặc Database Client chỉ có thể kết nối thông qua Database Endpoint và Protocol tương ứng.

Ví dụ:

* PostgreSQL → Port 5432
* MySQL → Port 3306

### Keywords

* Managed Database
* Database Endpoint
* PostgreSQL Protocol
* No SSH Access

---

## 12. S3 là File System hay Object Storage?

S3 là Object Storage.

Mỗi object bao gồm:

* Data
* Metadata
* Key

S3 không phải là File System truyền thống và không được thiết kế để mount như NFS hoặc SMB.

### Keywords

* Object Storage
* Bucket
* Object
* Metadata
* Key

---

## 13. Tại sao không lưu file upload trên EC2?

EC2 là Compute Resource có thể bị terminate hoặc thay thế bất kỳ lúc nào.

Nếu file chỉ tồn tại trên EC2 thì dữ liệu có thể mất khi instance bị xóa hoặc scale lại.

S3 được thiết kế cho việc lưu trữ lâu dài với độ bền và tính sẵn sàng rất cao.

### Keywords

* Durable Storage
* Ephemeral Compute
* High Availability
* Object Storage

---

## 14. Tại sao phải đẩy Logs lên CloudWatch?

Nếu logs chỉ tồn tại trên EC2:

```text
/var/log/app/application.log
```

thì khi EC2 bị terminate, logs sẽ mất theo.

CloudWatch giúp tập trung logs từ nhiều instance về một nơi để phục vụ:

* Monitoring
* Troubleshooting
* Auditing
* Incident Investigation

### Keywords

* Centralized Logging
* Monitoring
* Troubleshooting
* Audit Trail
* Observability

---

## 15. Tại sao Application chạy port 5000 thay vì 80?

Trên Linux, các port nhỏ hơn 1024 là Privileged Ports.

User thông thường như ec2-user không được phép bind trực tiếp vào các port này.

Thông thường application sẽ chạy ở port 5000 và sử dụng Reverse Proxy như Nginx hoặc Load Balancer để expose ra port 80 hoặc 443.

### Keywords

* Privileged Ports
* Reverse Proxy
* Nginx
* Kestrel
* Port Binding

---

## 16. Request Flow từ Internet đến Database

Khi user gửi request:

```text
Internet
    ↓
Security Group
    ↓
EC2
    ↓
Wallet API
    ↓
RDS PostgreSQL
    ↓
Response
```

Nếu upload file:

```text
Internet
    ↓
Wallet API
    ↓
IAM Role
    ↓
S3
```

Nếu ghi logs:

```text
Wallet API
    ↓
application.log
    ↓
CloudWatch Agent
    ↓
CloudWatch Logs
```

### Keywords

* Request Flow
* Data Flow
* Application Tier
* Database Tier
* Observability Flow

---

# Tóm tắt phỏng vấn trong 60 giây

"Tôi triển khai Wallet API trên EC2 và sử dụng IAM Role để EC2 lấy Temporary Credentials từ Instance Metadata Service thay vì dùng Access Key. Database PostgreSQL chạy trên RDS với Public Access tắt và chỉ cho phép Security Group của EC2 truy cập nhằm giảm Attack Surface. Dữ liệu file được lưu trên S3 thay vì EC2 vì S3 là Object Storage có độ bền cao hơn. Application logs được thu thập bởi CloudWatch Agent và gửi lên CloudWatch Logs để phục vụ Monitoring và Troubleshooting tập trung. Toàn bộ request flow đi từ Internet → Security Group → EC2 → Application → RDS hoặc S3 tùy nghiệp vụ."
