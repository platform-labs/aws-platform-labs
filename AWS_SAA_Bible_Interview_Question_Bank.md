# AWS Platform Labs - Volume 5: AWS SAA Bible (Theory Track) Interview Question Bank

> Tài liệu ôn tập theo dạng **câu hỏi phỏng vấn + câu trả lời chuẩn + ghi nhớ production**.
>
> Phạm vi: AWS SAA Theory Track — Storage (S3 Classes/Lifecycle/Replication/Glacier), Data Transfer (Snowball/DataSync/Storage Gateway), File Services (EFS/FSx), Networking Advanced (VPC Peering/Transit Gateway/PrivateLink), Hybrid (Direct Connect/VPN), Enterprise (Organizations/Control Tower), Edge Cases (Outposts/Local Zones/Wavelength).

---

# 1. S3 Storage Classes

## 1. So sánh S3 Standard, S3 Intelligent-Tiering, S3 Standard-IA, S3 One Zone-IA?

**Trả lời chuẩn:**
S3 Standard: truy cập thường xuyên, độ bền 11 số 9, lưu trên nhiều AZ, chi phí lưu trữ cao nhất trong nhóm "hot". S3 Intelligent-Tiering: tự động di chuyển object giữa tier theo pattern truy cập thực tế, phù hợp khi không chắc tần suất truy cập. S3 Standard-IA: truy cập không thường xuyên nhưng cần nhanh khi cần, lưu nhiều AZ, phí lưu thấp hơn nhưng phí lấy ra (retrieval) cao hơn. S3 One Zone-IA: giống Standard-IA nhưng chỉ lưu 1 AZ, rẻ hơn, đổi lại mất khả năng chịu lỗi mất cả AZ.

**Ghi nhớ:**
Trade-off chính: tần suất truy cập càng thấp, phí lưu càng rẻ nhưng phí lấy ra càng đắt và độ bền/HA có thể giảm.

---

## 2. S3 Glacier Instant Retrieval, Glacier Flexible Retrieval, và Glacier Deep Archive khác nhau ra sao?

**Trả lời chuẩn:**
Glacier Instant Retrieval: lấy ngay trong milliseconds, dùng cho data archive nhưng đôi khi vẫn cần truy cập nhanh (1 lần/quý). Glacier Flexible Retrieval: cần chờ vài phút tới vài giờ để lấy dữ liệu, rẻ hơn Instant, phù hợp archive ít truy cập. Glacier Deep Archive: rẻ nhất trong tất cả storage class S3, nhưng thời gian lấy dữ liệu lâu nhất (thường 12 giờ), dùng cho dữ liệu lưu trữ dài hạn theo quy định pháp lý gần như không bao giờ cần đọc lại.

**Ghi nhớ:**
Instant Retrieval = archive nhưng vẫn cần nhanh. Flexible = archive thường. Deep Archive = "gửi rồi quên", chỉ lấy khi bắt buộc.

---

## 3. S3 Lifecycle Policy dùng để làm gì, ví dụ một rule điển hình?

**Trả lời chuẩn:**
Lifecycle Policy tự động chuyển object giữa storage class theo thời gian, hoặc tự xóa object sau một khoảng thời gian, không cần can thiệp thủ công. Ví dụ điển hình: object mới upload ở S3 Standard, sau 30 ngày tự chuyển sang Standard-IA, sau 90 ngày chuyển sang Glacier Flexible Retrieval, sau 365 ngày tự expire (xóa) — tối ưu chi phí theo độ "lạnh" của dữ liệu theo thời gian.

**Ghi nhớ:**
Lifecycle Policy biến việc tối ưu chi phí storage thành tự động hóa, không phải việc làm tay định kỳ.

---

## 4. S3 Replication (CRR và SRR) khác nhau ở đâu, dùng khi nào?

**Trả lời chuẩn:**
SRR (Same-Region Replication) sao chép object sang bucket khác trong cùng region, dùng cho mục đích như tổng hợp log từ nhiều bucket, hoặc tuân thủ yêu cầu giữ bản sao độc lập trong cùng region. CRR (Cross-Region Replication) sao chép sang bucket ở region khác, dùng cho DR (giảm thiểu rủi ro mất dữ liệu toàn region), giảm latency cho người dùng ở xa, hoặc tuân thủ yêu cầu lưu dữ liệu ở nhiều địa lý.

**Ghi nhớ:**
SRR = tách bucket trong cùng region (compliance/aggregation). CRR = bảo vệ chống rủi ro toàn region (DR/latency).

---

## 5. Vì sao S3 Replication yêu cầu Versioning phải được bật?

**Trả lời chuẩn:**
Replication hoạt động dựa trên việc theo dõi các version mới của object để biết cái gì cần đồng bộ sang bucket đích. Nếu không bật Versioning, S3 không có cơ chế xác định chính xác "thay đổi nào là mới" để replicate, vì vậy AWS yêu cầu Versioning là điều kiện bắt buộc cho cả bucket nguồn và đích trước khi thiết lập Replication.

**Ghi nhớ:**
Không Versioning = không Replication. Đây là điều kiện cứng, không phải best practice tùy chọn.

---

## 6. S3 Transfer Acceleration giải quyết vấn đề gì?

**Trả lời chuẩn:**
Khi client upload object từ xa (địa lý cách region của bucket rất xa), tốc độ upload qua Internet thông thường có thể chậm do khoảng cách. Transfer Acceleration định tuyến traffic qua CloudFront Edge Location gần client nhất trước, sau đó dùng mạng backbone tối ưu của AWS để đưa data vào bucket, giảm thời gian upload đáng kể.

**Ghi nhớ:**
Transfer Acceleration tối ưu tốc độ *upload* từ xa, khác với CloudFront tối ưu tốc độ *phân phối* nội dung tới người dùng.

---

# 2. Data Transfer (Snowball, DataSync, Storage Gateway)

## 7. Khi nào nên dùng AWS Snowball thay vì truyền dữ liệu qua mạng Internet thông thường?

**Trả lời chuẩn:**
Khi khối lượng dữ liệu rất lớn (hàng chục TB tới PB) và băng thông Internet hiện có sẽ tốn quá nhiều thời gian để truyền (ví dụ tính ra mất hàng tuần/tháng), Snowball (thiết bị vật lý AWS gửi tới) cho phép copy dữ liệu offline rồi gửi lại cho AWS để upload vào S3 — nhanh hơn nhiều so với chờ mạng, đặc biệt ở nơi có hạ tầng mạng kém.

**Ghi nhớ:**
Quy tắc thô: nếu thời gian truyền qua mạng lâu hơn thời gian gửi thiết bị vật lý qua đường bộ/hàng không, nên chọn Snowball.

---

## 8. AWS DataSync khác Snowball ở điểm nào?

**Trả lời chuẩn:**
DataSync là dịch vụ truyền dữ liệu online, tự động qua mạng (LAN/Internet/Direct Connect), phù hợp cho di chuyển liên tục hoặc đồng bộ định kỳ giữa on-premise và AWS (hoặc giữa các AWS storage service), có khả năng tăng tốc truyền tải và xác thực tính nguyên vẹn dữ liệu tự động. Snowball là giải pháp offline dùng thiết bị vật lý, phù hợp cho di chuyển một lần khối lượng cực lớn khi mạng không đủ nhanh.

**Ghi nhớ:**
DataSync = online, lặp lại được, tự động hóa. Snowball = offline, thường dùng một lần cho khối lượng siêu lớn.

---

## 9. Storage Gateway có bao nhiêu loại chính, mỗi loại dùng cho mục đích gì?

**Trả lời chuẩn:**
File Gateway: expose S3 dưới dạng file share (NFS/SMB) cho on-premise server truy cập như một file system thông thường. Volume Gateway: expose storage dưới dạng iSCSI block volume, có 2 mode — Cached (giữ cache local, dữ liệu chính ở S3) và Stored (giữ toàn bộ dữ liệu local, backup snapshot lên S3). Tape Gateway: giả lập tape library vật lý (VTL) để tích hợp với backup software hiện có mà không cần đổi quy trình backup tape truyền thống.

**Ghi nhớ:**
File Gateway = file-level. Volume Gateway = block-level. Tape Gateway = giả lập tape cho hệ thống backup cũ.

---

## 10. Vì sao một công ty đang dùng hệ thống backup tape truyền thống lại chọn Tape Gateway thay vì migrate hẳn sang backup native AWS?

**Trả lời chuẩn:**
Nhiều tổ chức có sẵn quy trình, compliance, và software backup gắn chặt với khái niệm tape (đã đầu tư và đào tạo nhân sự theo workflow đó). Tape Gateway cho phép giữ nguyên software/quy trình backup hiện tại trong khi thực tế dữ liệu được lưu trên AWS (S3/Glacier), giúp migrate dần mà không cần thay đổi toàn bộ quy trình vận hành ngay lập tức.

**Ghi nhớ:**
Tape Gateway là cầu nối migration dần, không phải đích đến cuối cùng — phù hợp cho tổ chức cần chuyển đổi từ từ.

---

# 3. File Services (EFS, FSx)

## 11. EFS khác EBS như thế nào?

**Trả lời chuẩn:**
EBS là block storage, chỉ gắn được vào một EC2 instance tại một thời điểm (trừ Multi-Attach cho một số trường hợp đặc biệt), hoạt động trong một AZ. EFS là file storage (NFS), có thể mount đồng thời từ nhiều EC2 instance/AZ cùng lúc, tự động scale dung lượng theo dữ liệu thực tế mà không cần provision trước.

**Ghi nhớ:**
EBS = ổ cứng riêng cho một instance. EFS = file share dùng chung cho nhiều instance đồng thời, multi-AZ.

---

## 12. FSx for Windows File Server khác EFS ở điểm nào, khi nào nên chọn FSx?

**Trả lời chuẩn:**
EFS dùng protocol NFS, phù hợp hệ thống Linux. FSx for Windows File Server dùng protocol SMB, hỗ trợ đầy đủ tính năng Windows-native (Active Directory integration, NTFS permission, DFS) — nên chọn khi ứng dụng/server cần chạy trên Windows và cần file share tương thích hoàn toàn với hệ sinh thái Windows.

**Ghi nhớ:**
EFS = Linux/NFS-first. FSx for Windows = Windows/SMB-first, tích hợp sâu Active Directory.

---

## 13. FSx for Lustre dùng cho use case nào đặc thù?

**Trả lời chuẩn:**
FSx for Lustre là file system hiệu năng cao (high-throughput, low-latency), thiết kế cho workload tính toán nặng như HPC (High Performance Computing), Machine Learning training, và xử lý dữ liệu lớn cần đọc/viết song song tốc độ cao từ nhiều compute node — không phù hợp cho file sharing thông thường vì chi phí và độ phức tạp cao hơn EFS/FSx Windows.

**Ghi nhớ:**
FSx for Lustre = chuyên biệt cho compute-intensive workload (ML/HPC), không phải file share đa dụng.

---

# 4. Networking Advanced (VPC Peering, Transit Gateway, PrivateLink)

## 14. VPC Peering khác Transit Gateway như thế nào, khi nào Peering không còn đủ?

**Trả lời chuẩn:**
VPC Peering kết nối trực tiếp 1-1 giữa hai VPC, không transitive (VPC A peer với B, B peer với C, A không tự động thấy được C). Khi số lượng VPC cần kết nối tăng lên (ví dụ 10 VPC cần thông nhau), số lượng Peering connection cần thiết tăng theo cấp số nhân (mesh), khó quản lý. Transit Gateway giải quyết bằng một hub trung tâm, mọi VPC chỉ cần attach vào TGW một lần, TGW xử lý routing giữa tất cả VPC đó — quan hệ hub-and-spoke thay vì full-mesh.

**Ghi nhớ:**
Vài VPC: Peering đủ dùng. Nhiều VPC (>3-4) cần thông nhau: Transit Gateway tránh bùng nổ số lượng connection.

---

## 15. Vì sao VPC Peering không hỗ trợ transitive routing, ảnh hưởng gì tới thiết kế?

**Trả lời chuẩn:**
Đây là giới hạn kiến trúc cố định của AWS: route table chỉ biết route trực tiếp tới VPC peer ngay cạnh, không tự "đi xuyên qua" VPC trung gian để tới VPC thứ ba. Thiết kế hệ thống cần peer trực tiếp giữa từng cặp VPC cần thông nhau, hoặc chuyển sang Transit Gateway nếu cần mô hình phức tạp hơn 1-1.

**Ghi nhớ:**
"A peer B, B peer C" không có nghĩa "A thông được C" — đây là lỗi thiết kế phổ biến cần tránh khi vẽ network diagram.

---

## 16. PrivateLink giải quyết vấn đề gì khác với VPC Peering?

**Trả lời chuẩn:**
VPC Peering kết nối toàn bộ network range giữa hai VPC (cần quản lý route table, NACL chi tiết hai chiều, và CIDR không được overlap). PrivateLink chỉ expose một service cụ thể (qua Network Load Balancer hoặc Endpoint Service) tới VPC khác thông qua một Endpoint Network Interface riêng, không cần kết nối toàn bộ network, không lo CIDR overlap, và kiểm soát truy cập ở mức service cụ thể chứ không phải toàn VPC.

**Ghi nhớ:**
Peering = "thông cả hai network với nhau". PrivateLink = "chỉ expose một service cụ thể", an toàn và gọn hơn cho SaaS/multi-tenant.

---

## 17. Vì sao PrivateLink phù hợp cho mô hình SaaS cung cấp dịch vụ cho nhiều khách hàng khác nhau hơn VPC Peering?

**Trả lời chuẩn:**
Với mô hình SaaS có nhiều khách hàng (mỗi khách hàng một VPC riêng), dùng Peering nghĩa là phải tạo peering connection riêng với từng khách hàng và quản lý route/NACL riêng biệt — rất khó scale và rủi ro lộ toàn network. PrivateLink cho phép SaaS provider chỉ expose endpoint của dịch vụ cụ thể, khách hàng chỉ thấy đúng service đó, không thấy gì khác trong VPC của provider, dễ scale tới hàng nghìn khách hàng.

**Ghi nhớ:**
PrivateLink là lựa chọn chuẩn cho kiến trúc SaaS multi-tenant cần expose service mà không lộ toàn bộ network.

---

# 5. Hybrid (Direct Connect, VPN)

## 18. AWS Site-to-Site VPN khác Direct Connect như thế nào?

**Trả lời chuẩn:**
Site-to-Site VPN tạo kết nối mã hóa qua Internet công khai giữa on-premise và VPC, thiết lập nhanh (vài phút tới vài giờ) nhưng băng thông và độ ổn định phụ thuộc vào Internet công khai. Direct Connect là kết nối vật lý riêng (dedicated line) giữa datacenter on-premise và AWS, băng thông cao và ổn định hơn, độ trễ thấp hơn, nhưng cần thời gian setup lâu hơn (vài tuần tới vài tháng) và chi phí cao hơn.

**Ghi nhớ:**
VPN = nhanh, qua Internet công khai, biến động. Direct Connect = ổn định, riêng tư, cần thời gian/chi phí setup lớn hơn.

---

## 19. Vì sao nhiều thiết kế production dùng VPN làm backup cho Direct Connect, không phải ngược lại?

**Trả lời chuẩn:**
Direct Connect là kết nối vật lý chính, mạnh và ổn định nhưng vẫn có thể gặp sự cố (đứt cáp, lỗi thiết bị). VPN qua Internet công khai có thể được cấu hình làm route phụ (failover) tự động kích hoạt khi Direct Connect gặp sự cố, đảm bảo kết nối hybrid không bị mất hoàn toàn — đây là kiến trúc resilience tiêu chuẩn cho kết nối hybrid quan trọng.

**Ghi nhớ:**
Direct Connect = đường chính (primary). VPN = đường dự phòng (failover) — kết hợp cả hai cho HA hybrid connectivity.

---

## 20. Direct Connect Gateway dùng để làm gì khi có nhiều VPC ở nhiều region cần kết nối với on-premise?

**Trả lời chuẩn:**
Một Direct Connect connection vật lý thông thường chỉ gắn với một VPC/region cụ thể qua Virtual Interface. Direct Connect Gateway cho phép một kết nối Direct Connect duy nhất route tới nhiều VPC ở nhiều region khác nhau, tránh phải thiết lập nhiều đường Direct Connect vật lý riêng biệt cho từng region.

**Ghi nhớ:**
Direct Connect Gateway = nhân rộng một kết nối vật lý cho nhiều VPC/region, tránh tốn nhiều đường truyền riêng.

---

# 6. Enterprise (AWS Organizations, Control Tower)

## 21. AWS Organizations cung cấp lợi ích chính nào về billing?

**Trả lời chuẩn:**
Consolidated Billing cho phép tổng hợp chi phí của toàn bộ account thành viên vào một bill duy nhất ở account quản lý (management account), đồng thời tận dụng được Volume Discount và Reserved Instance/Savings Plan sharing giữa các account trong cùng Organization — tổng chi phí thường thấp hơn so với mỗi account mua riêng lẻ.

**Ghi nhớ:**
Consolidated Billing không chỉ gọn về quản lý, mà còn thực sự tiết kiệm tiền nhờ chia sẻ discount giữa account.

---

## 22. Control Tower khác Organizations thông thường ở điểm nào?

**Trả lời chuẩn:**
Organizations chỉ cung cấp cơ chế nền (account grouping, SCP, consolidated billing) nhưng không tự động hóa việc setup landing zone chuẩn. Control Tower xây trên nền Organizations, cung cấp landing zone đã được dựng sẵn theo best practice (account factory để tạo account mới tự động theo template, guardrail mặc định, dashboard compliance tập trung) — giúp triển khai nhanh hơn so với tự cấu hình Organizations từ đầu.

**Ghi nhớ:**
Organizations = nền tảng (building blocks). Control Tower = giải pháp đóng gói sẵn, tự động hóa nhanh trên nền đó.

---

## 23. OU (Organizational Unit) trong AWS Organizations dùng để làm gì?

**Trả lời chuẩn:**
OU là cách nhóm các account theo cấu trúc cây (ví dụ OU "Production", OU "Sandbox", OU "Security") để áp dụng Service Control Policy theo nhóm thay vì từng account riêng lẻ. Việc nhóm theo OU giúp quản lý guardrail nhất quán theo mục đích sử dụng của từng nhóm account, dễ scale khi có thêm account mới chỉ cần đặt đúng OU.

**Ghi nhớ:**
OU giúp áp SCP theo "vai trò của nhóm account" thay vì phải lặp lại policy cho từng account riêng lẻ.

---

# 7. Edge Cases (Outposts, Local Zones, Wavelength)

## 24. AWS Outposts giải quyết vấn đề gì cho tổ chức cần hạ tầng AWS chạy tại chỗ (on-premise)?

**Trả lời chuẩn:**
Một số tổ chức có yêu cầu pháp lý/độ trễ cực thấp buộc dữ liệu/compute phải nằm vật lý tại datacenter riêng của họ, không thể chạy hoàn toàn trên cloud công khai. Outposts là phần cứng AWS được lắp đặt ngay tại datacenter on-premise của khách hàng, chạy cùng API/tooling như AWS thật trên cloud, cho phép dùng các service AWS quen thuộc (EC2, EBS, ECS...) ngay tại chỗ, đồng bộ với AWS Region qua kết nối mạng.

**Ghi nhớ:**
Outposts = "mang AWS Region tới đặt ngay trong datacenter của bạn", phục vụ yêu cầu data residency/latency cực thấp.

---

## 25. Local Zones khác Region thông thường và khác Outposts như thế nào?

**Trả lời chuẩn:**
Local Zones là một extension nhỏ của AWS Region, đặt gần các thành phố/khu vực dân cư lớn để giảm latency cho người dùng cuối tại đó, nhưng vẫn do AWS vận hành hoàn toàn (không cần khách hàng có datacenter riêng) và chỉ hỗ trợ một tập con service AWS giới hạn. Khác Outposts (phần cứng đặt tại datacenter của khách hàng), Local Zones vẫn là hạ tầng do AWS sở hữu và quản lý, chỉ là đặt gần người dùng hơn Region chính.

**Ghi nhớ:**
Outposts = hạ tầng AWS đặt trong datacenter của khách hàng. Local Zones = hạ tầng AWS đặt gần thành phố lớn, vẫn do AWS quản lý hoàn toàn.

---

## 26. Wavelength được thiết kế cho use case nào đặc thù?

**Trả lời chuẩn:**
Wavelength đưa compute/storage AWS vào ngay trong hạ tầng mạng 5G của nhà mạng viễn thông (Telecom Provider), giúp ứng dụng cần độ trễ siêu thấp (AR/VR, gaming streaming, ứng dụng IoT thời gian thực) phục vụ trực tiếp tại "biên" mạng 5G, không phải đi qua nhiều hop về tới Region AWS chính.

**Ghi nhớ:**
Wavelength = tối ưu cho ứng dụng cần latency siêu thấp gắn liền với hạ tầng mạng di động 5G, một niche rất cụ thể so với Local Zones/Outposts.

---

## 27. Khi nào nên chọn Outposts, Local Zones, hay Wavelength — làm sao phân biệt nhanh trong phỏng vấn?

**Trả lời chuẩn:**
Câu hỏi cần đặt ra: "Dữ liệu/compute phải nằm vật lý ở đâu, và vì sao?". Nếu bắt buộc nằm trong chính datacenter khách hàng (compliance, data residency) → Outposts. Nếu chỉ cần gần một thành phố lớn cụ thể để giảm latency cho người dùng khu vực đó, không cần hạ tầng riêng → Local Zones. Nếu ứng dụng gắn chặt với mạng 5G di động và cần latency cực thấp ở "biên" mạng telecom → Wavelength.

**Ghi nhớ:**
Outposts = "tại nhà tôi". Local Zones = "gần thành phố tôi". Wavelength = "trong mạng 5G của nhà mạng".

---

# 8. Mapping tổng hợp với hands-on Lab (theo Roadmap)

## 28. S3 (theory) liên hệ với Lab nào trong hands-on track?

**Trả lời chuẩn:**
S3 được thực hành trực tiếp ở Lab 1 (S3 Bucket cơ bản cho WalletMinimal) và Lab 5 (S3 Bucket Terraform hóa, gắn với Task Role IAM permission). Phần lý thuyết sâu hơn (Storage Class, Lifecycle, Replication, Glacier) thuộc SAA Theory Track vì roadmap không có lab riêng cho từng tính năng này, nhưng vẫn bắt buộc nắm vững cho kỳ thi.

**Ghi nhớ:**
Không phải mọi kiến thức SAA đều có lab tương ứng — một số phải học song song qua theory track thuần lý thuyết.

---

## 29. VPC (theory) liên hệ với Lab nào, vì sao VPC Peering/TGW không có lab riêng?

**Trả lời chuẩn:**
VPC cơ bản (Subnet, Route Table, IGW, NAT) được thực hành sâu ở Lab 3A/3B (Console + CLI) và Terraform hóa ở Lab 4. VPC Peering/Transit Gateway/PrivateLink không có lab riêng trong roadmap vì các khái niệm này chủ yếu xuất hiện ở kiến trúc multi-VPC/multi-account phức tạp hơn quy mô hiện tại của CSNP (một VPC chính), nên được xếp vào theory track để biết khi cần dùng trong tương lai (ví dụ khi làm Lab 19 Multi Account).

**Ghi nhớ:**
Độ ưu tiên có lab hands-on hay chỉ theory phụ thuộc vào việc CSNP có đang cần dùng thật resource đó hay không ở giai đoạn hiện tại.

---

## 30. RDS (theory) liên hệ với Lab nào, và vì sao roadmap không có lab riêng cho EFS/FSx?

**Trả lời chuẩn:**
RDS được thực hành ở Lab 1 (RDS PostgreSQL cơ bản) và Lab 9 (Aurora PostgreSQL, so sánh sâu với RDS). EFS/FSx không có lab riêng vì CSNP (kiến trúc microservices stateless, dùng PostgreSQL/Redis/S3 cho mọi nhu cầu lưu trữ) chưa có use case thực tế cần shared file system POSIX (như NFS) — kiến thức EFS/FSx vẫn cần cho kỳ thi SAA nhưng chưa cấp thiết cho CSNP hiện tại.

**Ghi nhớ:**
Việc thiếu lab hands-on cho một service không có nghĩa là service đó kém quan trọng cho kỳ thi — chỉ là không khớp với use case thực tế hiện tại của dự án.
