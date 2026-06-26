# AWS Lab #3 - Key Concepts & Interview Notes

## 1. Tại sao cần Custom VPC thay vì Default VPC?

Default VPC dùng chung 1 subnet public cho mọi resource, không phân tầng theo mức độ tin cậy (trust level).

Custom VPC cho phép thiết kế network theo đúng kiến trúc ứng dụng: Public tier cho thành phần chịu traffic từ internet (ALB), Private App tier cho compute nội bộ (ECS), Private Data tier cho database (RDS) — mỗi tier có Route Table và Security Group riêng, kiểm soát rõ traffic được đi đâu.

### Keywords

* Custom VPC
* Default VPC
* Network Segmentation
* Trust Boundary

---

## 2. Internet Gateway khác NAT Gateway như thế nào?

Internet Gateway (IGW) cho phép traffic 2 chiều giữa VPC và internet — dùng cho Public Subnet, nơi resource có Public IP (ALB, test EC2).

NAT Gateway chỉ cho phép traffic 1 chiều: resource trong Private Subnet **chủ động gọi ra** internet (ví dụ pull image, gọi API ngoài), nhưng internet **không thể chủ động kết nối vào** resource đó. NAT Gateway nằm trong Public Subnet và dùng Elastic IP làm địa chỉ nguồn khi traffic đi ra.

### Keywords

* Internet Gateway
* NAT Gateway
* Bidirectional vs Outbound-only
* Elastic IP

---

## 3. Tại sao Private Data Subnet không cần Route ra Internet?

RDS là managed service — application kết nối tới RDS qua DB Endpoint nội bộ trong VPC, không cần RDS tự gọi ra internet để hoạt động (backup, patching, monitoring đều do AWS xử lý ở control plane, không qua route table của subnet).

Route Table của Private Data Subnet trong lab này chỉ có route `local` (tự động, ngầm định cho mọi VPC) — không có `0.0.0.0/0` trỏ tới IGW hoặc NAT. Đây là minh chứng bằng hạ tầng cho nguyên tắc Defense in Depth, không chỉ dựa vào Security Group.

### Keywords

* Local Route
* Managed Service
* Defense in Depth
* No Internet Route

---

## 4. 1 NAT Gateway hay 1 NAT Gateway / AZ?

1 NAT Gateway cho cả VPC là lựa chọn tiết kiệm chi phí (~$32/tháng so với ~$64/tháng cho 2), phù hợp cho lab/dev/staging. Nhược điểm: NAT trở thành Single Point of Failure — nếu AZ chứa NAT bị down, mọi Private Subnet ở AZ khác cũng mất khả năng ra internet, dù compute ở AZ đó vẫn chạy bình thường.

Production nên dùng 1 NAT Gateway / AZ, mỗi Private Subnet route qua NAT trong cùng AZ của nó — giữ đúng tinh thần Multi-AZ, một AZ down không ảnh hưởng AZ khác.

### Keywords

* NAT Gateway
* Single Point of Failure
* High Availability
* Cost vs Resilience Trade-off

---

## 5. Route Table Association là gì, tại sao dễ bị quên?

Tạo Route Table xong không tự động áp dụng cho Subnet nào cả — phải tạo thêm Route Table Association để gắn Route Table vào Subnet cụ thể.

Nếu quên association, Subnet vẫn dùng Main Route Table của VPC (thường chỉ có route `local`), khiến Subnet đó "không ra được internet" dù Route Table đúng đã được tạo — lỗi rất hay gặp khi mới làm VPC thủ công hoặc viết Terraform.

### Keywords

* Route Table Association
* Main Route Table
* Implicit Association
* Common Misconfiguration

---

## 6. Tại sao Security Group chain là ALB → ECS → RDS, không phải mở thẳng?

Mỗi tier chỉ nên nhận traffic từ tier ngay phía trước nó trong luồng xử lý, không nhận trực tiếp từ internet hoặc tier xa hơn.

* ALB SG: nhận port 80 từ `0.0.0.0/0` — đây là tier duy nhất chấp nhận traffic công khai.
* ECS SG: chỉ nhận port container từ ALB SG.
* RDS SG: chỉ nhận port 5432 từ ECS SG.

Nếu RDS SG vô tình mở `0.0.0.0/0`, toàn bộ Defense in Depth của VPC bị phá vỡ ngay tại tier quan trọng nhất. Chain này đảm bảo dù ALB hay ECS có lỗi cấu hình, RDS vẫn được bảo vệ bởi một lớp SG độc lập.

### Keywords

* Security Group Chain
* Defense in Depth
* Least Privilege
* Security Group Reference

---

## 7. Tại sao test EC2 dựng riêng, không dùng lại EC2 của Lab 1?

EC2 ở Lab 1 chạy trong Default VPC (Generation 1, đã đóng băng). Nếu di chuyển nó vào Custom VPC mới, Lab 1 không còn nguyên trạng để tham khảo, và việc "migrate resource cũ" làm lẫn lộn mục tiêu của Lab 3 (hiểu networking) với mục tiêu khác (migration).

Dựng EC2 test mới, độc lập, chỉ để verify network rồi terminate, giữ Lab 3 tập trung đúng vào một mục tiêu duy nhất: xác nhận VPC/Subnet/Route Table/NAT hoạt động đúng như thiết kế.

### Keywords

* Generation 1 vs Generation 2
* Test Isolation
* Throwaway Resource
* Single Responsibility per Lab

---

## 8. Multi-AZ trong Lab 3 chuẩn bị cho điều gì ở các lab sau?

2 AZ (us-east-1a, us-east-1b) cho mỗi tier là nền tảng bắt buộc cho:

* RDS Subnet Group cần ít nhất 2 subnet ở 2 AZ khác nhau để hỗ trợ Multi-AZ failover (dù Lab 3 chưa tạo RDS, subnet đã sẵn sàng).
* ECS Service chạy Desired Count nhiều task, ECS có thể đặt task ở nhiều AZ để chịu được một AZ down.
* ALB cũng cần ít nhất 2 AZ để chính nó không trở thành single point of failure.

Thiết kế subnet theo cặp AZ ngay từ Lab 3 giúp Lab 4 (Terraform Platform Foundation) và các lab compute sau này (ECS, RDS) không cần sửa lại network.

### Keywords

* Multi-AZ
* RDS Subnet Group
* High Availability
* Forward-compatible Design

---

## 9. Security Group khác NACL (Network ACL) như thế nào?

Security Group là **Stateful** — nếu inbound được cho phép, response traffic tự động được phép, không cần khai báo outbound rule tương ứng (đã nhắc ở Lab 1). Security Group áp dụng ở mức **instance/ENI** (ví dụ từng ECS task, từng RDS instance).

NACL (Network ACL) là **Stateless** — inbound và outbound phải khai báo rule riêng biệt, response traffic không tự động được phép. NACL áp dụng ở mức **subnet**, là lớp filter trước khi traffic chạm tới Security Group.

Thứ tự traffic đi qua khi vào VPC: `Internet → NACL (subnet level) → Security Group (instance level) → Resource`. Lab 3 không tạo NACL riêng (dùng Default NACL của VPC, mở toàn bộ) — Security Group đã đủ kiểm soát truy cập ở mức cần thiết cho lab. NACL custom đáng dùng khi cần block một CIDR cụ thể ở mức subnet, không phụ thuộc Security Group của resource bên trong.

### Keywords

* Security Group vs NACL
* Stateful vs Stateless
* Instance-level vs Subnet-level
* Default NACL

---

# Tóm tắt phỏng vấn trong 60 giây

"Tôi thiết kế Custom VPC 3-tier thay cho Default VPC: Public Subnet cho ALB và NAT Gateway, Private App Subnet cho ECS routing ra internet qua NAT, và Private Data Subnet cho RDS hoàn toàn không có route ra internet — chỉ route local, đúng nguyên tắc database không cần internet để hoạt động. Tôi dùng 1 NAT Gateway cho toàn VPC để tiết kiệm chi phí ở môi trường lab, dù hiểu rõ đây là single point of failure và production nên có 1 NAT/AZ. Security Group được chain theo đúng luồng traffic: ALB SG mở port 80 công khai, ECS SG chỉ nhận từ ALB SG, RDS SG chỉ nhận từ ECS SG — không tier nào mở thẳng ra internet ngoài ALB. Mọi subnet được thiết kế theo cặp 2 AZ ngay từ đầu để sẵn sàng cho RDS Multi-AZ và ECS Service nhiều task ở các lab tiếp theo, tránh phải sửa lại network sau này. Security Group là Stateful và áp dụng ở mức instance, còn NACL là Stateless và áp dụng ở mức subnet — lab này dùng Default NACL, để toàn bộ access control nằm ở Security Group."
