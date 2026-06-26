# AWS Platform Labs - Volume 3: Advanced AWS (Lab 9 → Lab 14) Interview Question Bank

> Tài liệu ôn tập theo dạng **câu hỏi phỏng vấn + câu trả lời chuẩn + ghi nhớ production**.
>
> Phạm vi: Lab 9 Aurora PostgreSQL, Lab 9.5 ECS vs EKS ADR, Lab 10 EKS, Lab 11 ElastiCache Redis, Lab 12A Amazon MQ, Lab 12B MSK Serverless, Lab 13 Route53 + ACM, Lab 14 WAF.

---

# LAB 9 - Aurora PostgreSQL

## 1. Aurora PostgreSQL khác RDS PostgreSQL ở kiến trúc nào?

**Trả lời chuẩn:**
RDS PostgreSQL chạy PostgreSQL engine gốc trên một instance với EBS storage gắn trực tiếp. Aurora tách storage layer ra thành một distributed storage layer riêng (6 copies trên 3 AZ), compute (instance) có thể scale độc lập với storage, và replication tới read replica diễn ra ở storage layer (gần như tức thì) thay vì replay log như RDS thông thường.

**Ghi nhớ:**
Aurora = storage tách rời compute, replicate ở tầng storage. RDS = storage gắn liền instance, replicate qua log.

---

## 2. Aurora Read Replica khác gì so với RDS Read Replica về độ trễ?

**Trả lời chuẩn:**
RDS Read Replica dùng async replication qua binlog/WAL, có thể trễ vài giây tùy tải. Aurora Read Replica chia sẻ cùng storage layer với writer, nên độ trễ replication thường dưới 100ms vì không cần copy toàn bộ data, chỉ cần đồng bộ metadata/cache.

**Ghi nhớ:**
Aurora replica lag thấp hơn nhiều nhờ shared storage, không phải vì "nhanh hơn" về bản chất compute.

---

## 3. Aurora Failover hoạt động như thế nào, downtime bao lâu?

**Trả lời chuẩn:**
Khi writer instance gặp sự cố, Aurora promote một read replica (hoặc tạo writer mới) thành writer mới, và endpoint DNS (cluster endpoint) tự động trỏ tới writer mới — ứng dụng không cần đổi connection string. Failover thường mất 30 giây hoặc ít hơn vì storage layer không cần khởi động lại từ đầu.

**Ghi nhớ:**
Failover nhanh vì storage layer luôn sẵn sàng, chỉ cần đổi role compute và update DNS endpoint.

---

## 4. Khi nào nên chọn RDS PostgreSQL thay vì Aurora?

**Trả lời chuẩn:**
RDS PostgreSQL phù hợp khi: chi phí phải tối thiểu (Aurora đắt hơn RDS ở mức tải thấp), cần tương thích 100% extension PostgreSQL gốc (Aurora có một số hạn chế extension), hoặc workload nhỏ không cần HA/scale phức tạp. Aurora đáng đầu tư khi cần HA mạnh, scale read nhiều, và chấp nhận chi phí cao hơn.

**Ghi nhớ:**
RDS = đơn giản, rẻ, tương thích gốc. Aurora = HA mạnh, scale tốt, chi phí cao hơn.

---

## 5. Aurora Multi-AZ khác RDS Multi-AZ standby như thế nào?

**Trả lời chuẩn:**
RDS Multi-AZ tạo một standby instance "ẩn" chỉ dùng để failover, không phục vụ read traffic (trừ khi bật Multi-AZ với 2 readable standby ở phiên bản mới). Aurora không có khái niệm "standby ẩn" — mọi Read Replica đều active và có thể phục vụ read traffic ngay, đồng thời cũng là candidate cho failover.

**Ghi nhớ:**
RDS Multi-AZ truyền thống: standby chỉ chờ failover. Aurora: mọi replica đều "sống" và hữu dụng.

---

## 6. Aurora Serverless khác Aurora Provisioned ở điểm nào, khi nào nên dùng?

**Trả lời chuẩn:**
Aurora Provisioned yêu cầu chọn sẵn instance class cố định, chạy liên tục theo công suất đó. Aurora Serverless tự động scale capacity (ACU) lên xuống theo tải thực tế, phù hợp cho workload không đoán được hoặc có giai đoạn idle dài (dev/test, ứng dụng theo mùa), giúp tiết kiệm chi phí khi traffic không liên tục.

**Ghi nhớ:**
Serverless phù hợp tải biến động mạnh hoặc không liên tục; Provisioned phù hợp tải ổn định, dự đoán được.

---

# LAB 9.5 - ECS vs EKS Architecture Decision Record

## 7. ADR (Architecture Decision Record) là gì, vì sao roadmap yêu cầu viết file ADR thật?

**Trả lời chuẩn:**
ADR là tài liệu ghi lại quyết định kiến trúc quan trọng cùng với context, các option đã xem xét, và lý do chọn option cuối. Roadmap yêu cầu viết ADR thật vì đây là kỹ năng senior thực tế: bất kỳ quyết định lớn (như chọn ECS hay EKS) đều cần được ghi lại để team sau hiểu "tại sao", tránh tranh luận lại từ đầu mỗi khi có người mới hỏi.

**Ghi nhớ:**
ADR ghi lại "tại sao", không chỉ "cái gì" — giá trị nằm ở context và trade-off, không phải kết luận.

---

## 8. Vì sao CSNP chọn ECS thay vì EKS ở giai đoạn hiện tại?

**Trả lời chuẩn:**
Ở quy mô một hệ thống cá nhân/early-stage, ECS có độ phức tạp vận hành thấp hơn nhiều (không cần quản lý control plane, không cần học thêm Kubernetes object model), tích hợp native với AWS (IAM, ALB, CloudWatch) đơn giản hơn, và đủ đáp ứng nhu cầu scale hiện tại. EKS mang lại sức mạnh ecosystem Kubernetes nhưng chi phí vận hành (cognitive load + cluster cost) chưa tương xứng với lợi ích ở giai đoạn này.

**Ghi nhớ:**
Chọn công nghệ theo độ phức tạp hệ thống hiện tại, không chọn theo "công nghệ tốt nhất trên giấy".

---

## 9. Khi nào CSNP nên migrate từ ECS sang EKS?

**Trả lời chuẩn:**
Nên xem xét EKS khi: cần đa nền tảng deploy (multi-cloud hoặc hybrid), cần ecosystem Kubernetes cụ thể (service mesh phức tạp, custom operator, Helm chart có sẵn của bên thứ ba), hoặc team đã đủ lớn để có người chuyên trách vận hành cluster. Đây không phải quyết định một chiều — ADR phải có "exit criteria" rõ ràng để biết khi nào cần đổi.

**Ghi nhớ:**
ADR tốt không chỉ giải thích quyết định hiện tại, mà còn định nghĩa điều kiện để quyết định đó cần được xem lại.

---

## 10. Trade-off chính giữa ECS và EKS về mặt chi phí vận hành (operations) là gì?

**Trả lời chuẩn:**
ECS: AWS quản lý hoàn toàn control plane, không tốn phí riêng cho control plane, learning curve thấp hơn. EKS: trả phí cố định cho control plane (theo giờ), cần học Kubernetes object model (Pod, Deployment, Service, Ingress, HPA), và cần thêm công cụ như ArgoCD/Helm để vận hành hiệu quả — chi phí vận hành (thời gian + tiền) cao hơn đáng kể.

**Ghi nhớ:**
EKS mạnh hơn về portability và ecosystem, nhưng đánh đổi bằng chi phí vận hành cao hơn rõ rệt.

---

# LAB 10 - EKS

## 11. Mapping giữa khái niệm ECS và Kubernetes như thế nào?

**Trả lời chuẩn:**
ECS Cluster tương đương Kubernetes Cluster (nhóm node compute dùng chung). ECS Service tương đương Deployment (quản lý desired state của một nhóm Task/Pod). ECS Task tương đương Pod (đơn vị chạy container nhỏ nhất). ALB + Target Group tương đương Ingress + Service (định tuyến traffic vào Pod).

**Ghi nhớ:**
Nắm mapping này giúp chuyển đổi mental model nhanh khi switch giữa hai hệ sinh thái.

---

## 12. HPA (Horizontal Pod Autoscaler) khác ECS Service Auto Scaling như thế nào?

**Trả lời chuẩn:**
Cả hai cùng mục đích: tăng/giảm số lượng instance chạy theo metric (CPU/Memory). Khác biệt nằm ở cơ chế: HPA là một Kubernetes Controller riêng, đọc metric từ Metrics Server và điều chỉnh `replicas` của Deployment; ECS Auto Scaling tích hợp trực tiếp qua Application Auto Scaling Service của AWS, đọc CloudWatch Alarm để điều chỉnh Desired Count.

**Ghi nhớ:**
Cùng ý tưởng autoscale, khác nền tảng kỹ thuật — HPA là K8s-native, ECS Scaling là AWS-native.

---

## 13. Ingress trong EKS đóng vai trò gì so với ALB trong ECS?

**Trả lời chuẩn:**
Ingress là một Kubernetes object định nghĩa rule routing HTTP/HTTPS (path, host) vào Service bên trong cluster. Trên AWS, AWS Load Balancer Controller sẽ provision một ALB thật đứng sau Ingress để thực thi routing đó — về bản chất Ingress là lớp abstraction Kubernetes-native, còn ALB vẫn là hạ tầng thật chạy phía dưới.

**Ghi nhớ:**
Ingress = khai báo intent routing trong K8s. ALB Controller = công cụ biến intent đó thành ALB thật trên AWS.

---

## 14. Node Group trong EKS là gì, khác gì so với việc ECS Fargate "không cần quản lý server"?

**Trả lời chuẩn:**
Node Group là tập hợp EC2 instance làm worker node cho EKS cluster, cần được quản lý (patch, scale, AMI) — trừ khi dùng Fargate Profile cho EKS (cũng serverless tương tự ECS Fargate). EKS truyền thống với Node Group đòi hỏi vận hành nhiều hơn ECS Fargate, vì phải tự quản lý vòng đời EC2 bên dưới.

**Ghi nhớ:**
EKS có thể chạy serverless (Fargate Profile) hoặc managed node (Node Group) — không phải lúc nào EKS cũng "nặng" hơn ECS Fargate về vận hành.

---

# LAB 11 - ElastiCache Redis

## 15. Khi nào dùng Redis làm Cache, khi nào dùng làm Distributed Lock?

**Trả lời chuẩn:**
Dùng làm Cache khi cần giảm tải truy vấn lặp lại tới database (lưu kết quả tạm với TTL). Dùng làm Distributed Lock khi cần đảm bảo chỉ một process/instance được thực hiện một đoạn logic tại một thời điểm trong hệ thống phân tán nhiều instance (ví dụ tránh double-processing một giao dịch), thường dùng lệnh `SETNX` hoặc Redlock pattern.

**Ghi nhớ:**
Cache = tối ưu performance. Distributed Lock = đảm bảo correctness/consistency trong môi trường nhiều instance.

---

## 16. Redis Rate Limiting hoạt động theo cơ chế nào phổ biến nhất?

**Trả lời chuẩn:**
Phổ biến nhất là Sliding Window hoặc Token Bucket implement bằng Redis: dùng `INCR` kèm `EXPIRE` để đếm số request trong một window thời gian cho mỗi key (user/IP/API key), nếu vượt ngưỡng thì reject. Redis phù hợp vì có atomic operation và TTL tự nhiên, hoạt động tốt trên nhiều instance app dùng chung.

**Ghi nhớ:**
`INCR` + `EXPIRE` atomic là nền tảng đơn giản nhất cho rate limiting phân tán bằng Redis.

---

## 17. Vì sao Session Store trên Redis tốt hơn lưu Session trong memory của từng instance app?

**Trả lời chuẩn:**
Nếu lưu session trong memory cục bộ từng instance, user có thể bị "mất session" khi load balancer route request sang instance khác (sticky session là giải pháp tạm nhưng kém linh hoạt khi scale/restart). Redis là session store tập trung, mọi instance app đều đọc/viết cùng một nơi, cho phép scale horizontal tự do mà không lo mất session.

**Ghi nhớ:**
Session tập trung (Redis) là điều kiện cần để app stateless thật sự scale ngang an toàn.

---

## 18. ElastiCache Redis Cluster Mode khác Non-Cluster Mode như thế nào?

**Trả lời chuẩn:**
Non-Cluster Mode (Redis Replication Group) chỉ có một primary node chứa toàn bộ data, kèm replica để đọc/failover — phù hợp dataset vừa phải. Cluster Mode chia (shard) data ra nhiều node theo hash slot, cho phép scale write throughput và dung lượng vượt giới hạn một node, nhưng phức tạp hơn về client và một số lệnh multi-key bị hạn chế.

**Ghi nhớ:**
Cluster Mode = scale ngang thật, đổi lại phức tạp hơn. Non-Cluster = đơn giản, giới hạn theo 1 node.

---

# LAB 12A - Amazon MQ (RabbitMQ)

## 19. Vì sao chọn Amazon MQ (RabbitMQ) là Required, MSK là Optional cho CSNP?

**Trả lời chuẩn:**
Các domain như Wallet, Payment, Ledger, Notification của CSNP cần message queue đảm bảo delivery theo thứ tự, hỗ trợ retry/DLQ rõ ràng cho từng message — đúng use case của RabbitMQ (message broker truyền thống). MSK (Kafka) phù hợp hơn cho event streaming/analytics khối lượng lớn (Compliance, Analytics), chưa cấp thiết ở giai đoạn hiện tại của CSNP.

**Ghi nhớ:**
RabbitMQ phù hợp transactional messaging giữa service. Kafka phù hợp event streaming/analytics quy mô lớn.

---

## 20. DLQ (Dead Letter Queue) giải quyết vấn đề gì?

**Trả lời chuẩn:**
Khi một message xử lý thất bại liên tục (sau số lần retry quy định), thay vì mất message hoặc block queue chính, broker chuyển message đó sang DLQ riêng. Việc này cho phép hệ thống chính tiếp tục xử lý message khác bình thường, đồng thời message lỗi vẫn được lưu lại để điều tra/xử lý thủ công sau.

**Ghi nhớ:**
DLQ = "ngăn cách ly" cho message lỗi, tránh poison message làm nghẽn toàn hệ thống.

---

## 21. MassTransit đóng vai trò gì khi tích hợp với Amazon MQ?

**Trả lời chuẩn:**
MassTransit là một message bus abstraction layer trong .NET, giúp định nghĩa Consumer/Publisher, retry policy, và routing convention mà không cần viết trực tiếp AMQP protocol low-level. Nó hỗ trợ cấu hình DLQ, retry với exponential backoff, và outbox pattern tích hợp sẵn, giảm boilerplate code khi làm việc với RabbitMQ.

**Ghi nhớ:**
MassTransit = lớp trừu tượng hóa giúp .NET code làm việc với message broker gọn và chuẩn hơn, không phải broker tự thân.

---

## 22. Retry với Exponential Backoff khác Retry cố định (fixed interval) như thế nào, vì sao quan trọng cho hệ thống fintech?

**Trả lời chuẩn:**
Fixed interval retry lặp lại sau khoảng thời gian cố định, dễ tạo "retry storm" khi nhiều message cùng lỗi đồng thời (ví dụ downstream service đang quá tải). Exponential Backoff tăng dần thời gian chờ giữa các lần retry, giảm áp lực dồn lên downstream service đang gặp sự cố, cho nó thời gian hồi phục trước khi nhận lại traffic.

**Ghi nhớ:**
Exponential Backoff giúp hệ thống tự "giảm nhiệt" khi có sự cố, tránh làm downstream service sập sâu hơn.

---

# LAB 12B - Amazon MSK Serverless

## 23. MSK Serverless khác MSK Provisioned như thế nào, vì sao roadmap bỏ Provisioned?

**Trả lời chuẩn:**
MSK Provisioned yêu cầu chọn sẵn số broker và capacity, phải tự quản lý scaling. MSK Serverless tự động scale theo throughput thực tế và tính phí theo dung lượng dùng, phù hợp hơn cho học tập/early-stage vì không cần đoán capacity trước và tránh trả phí cho capacity không dùng tới.

**Ghi nhớ:**
Serverless giảm rủi ro overprovision/underprovision khi chưa có dữ liệu traffic thực tế.

---

## 24. Event Streaming (Kafka) khác Message Queue (RabbitMQ) về bản chất ra sao?

**Trả lời chuẩn:**
Message Queue thường xóa message sau khi consumer xử lý xong (point-to-point hoặc competing consumer). Kafka lưu message trong log có thể replay, cho phép nhiều consumer group đọc độc lập tại các offset khác nhau, phù hợp cho streaming/analytics cần xem lại lịch sử event, không chỉ xử lý một lần rồi bỏ.

**Ghi nhớ:**
MQ tối ưu cho "xử lý một lần, xong thì xóa". Kafka tối ưu cho "lưu lại log event để nhiều bên đọc lại nhiều lần".

---

## 25. Vì sao Compliance/Analytics của CSNP phù hợp với Kafka hơn RabbitMQ?

**Trả lời chuẩn:**
Compliance cần audit trail đầy đủ, có thể replay lại toàn bộ event lịch sử khi cần re-tính toán hoặc kiểm tra; Analytics cần nhiều consumer (dashboard, ML pipeline, shadow stream) đọc cùng một stream event độc lập nhau. Đặc tính lưu log bền và hỗ trợ multi-consumer độc lập của Kafka phù hợp hơn RabbitMQ ở các use case này.

**Ghi nhớ:**
Khi cần "replay lịch sử" hoặc "nhiều consumer độc lập đọc cùng stream", nghĩ tới Kafka trước RabbitMQ.

---

# LAB 13 - Route53 + ACM

## 26. Route53 Alias Record khác CNAME Record như thế nào?

**Trả lời chuẩn:**
CNAME chỉ trỏ một subdomain tới một domain khác, không dùng được cho zone apex (root domain) và luôn tốn một lượt DNS lookup thêm. Alias Record là tính năng riêng của Route53, hoạt động giống CNAME nhưng dùng được ở zone apex và phân giải trực tiếp tới AWS resource (ALB, CloudFront) mà không tốn lượt lookup thêm, miễn phí khi trỏ tới AWS resource.

**Ghi nhớ:**
Alias Record là lựa chọn ưu tiên khi trỏ domain AWS-managed tới AWS resource — nhanh hơn và hỗ trợ zone apex.

---

## 27. ACM Certificate Validation qua DNS khác qua Email như thế nào, nên chọn cái nào?

**Trả lời chuẩn:**
Validation qua Email yêu cầu click link xác nhận gửi tới các địa chỉ admin chuẩn của domain, dễ bị miss hoặc cần thao tác thủ công, và certificate không tự renew nếu mất quyền truy cập email đó. Validation qua DNS chỉ cần thêm một CNAME record vào hosted zone, hỗ trợ auto-renew hoàn toàn nếu record đó còn tồn tại — nên luôn chọn DNS validation khi domain quản lý bằng Route53.

**Ghi nhớ:**
DNS Validation = tự động, auto-renew, nên dùng mặc định khi có quyền quản lý DNS.

---

## 28. Vì sao ACM Certificate phải request ở `us-east-1` khi dùng với CloudFront, nhưng không cần khi dùng với ALB?

**Trả lời chuẩn:**
CloudFront là dịch vụ global (không gắn với một region cụ thể), nên AWS yêu cầu certificate cho CloudFront phải nằm ở region `us-east-1` theo quy định cố định của dịch vụ. ALB là resource theo region, nên certificate chỉ cần nằm cùng region với ALB đó.

**Ghi nhớ:**
CloudFront luôn cần cert ở `us-east-1` bất kể bạn deploy ở region nào — đây là rule cố định, không phải best practice tùy chọn.

---

## 29. HTTPS Listener trên ALB hoạt động ra sao khi kết hợp với ACM Certificate?

**Trả lời chuẩn:**
ALB Listener ở port 443 gắn với ACM Certificate, thực hiện TLS termination ngay tại ALB — client kết nối HTTPS tới ALB, ALB giải mã rồi forward traffic (thường là HTTP thường) tới Target Group/ECS Task phía sau. Điều này giúp ứng dụng backend không cần tự quản lý certificate.

**Ghi nhớ:**
TLS Termination ở ALB giúp backend đơn giản hơn, không phải tự xử lý certificate/TLS handshake.

---

# LAB 14 - AWS WAF

## 30. WAF hoạt động ở Layer nào, khác gì so với Security Group (Layer 3/4)?

**Trả lời chuẩn:**
WAF hoạt động ở Layer 7 (Application Layer), kiểm tra nội dung HTTP request (header, body, query string, URI) để chặn pattern tấn công như SQL Injection, XSS, hoặc rate-based attack. Security Group chỉ kiểm soát ở Layer 3/4 (IP, port, protocol), không nhìn vào nội dung request.

**Ghi nhớ:**
SG chặn theo "ai gọi, qua port nào". WAF chặn theo "request đó nói gì, có nguy hiểm không".

---

## 31. OWASP Managed Rule Group trong WAF dùng để giải quyết vấn đề gì?

**Trả lời chuẩn:**
AWS Managed Rules - OWASP Top 10 là tập rule có sẵn được AWS duy trì, bảo vệ chống các lỗ hổng phổ biến (SQL Injection, XSS, Local File Inclusion...) theo chuẩn OWASP Top 10, giúp không phải tự viết rule chi tiết từ đầu và luôn được AWS update theo pattern tấn công mới.

**Ghi nhớ:**
Managed Rule Group = baseline bảo vệ nhanh, vẫn nên bổ sung Custom Rule riêng cho logic nghiệp vụ đặc thù.

---

## 32. Rate-based Rule trong WAF khác Rate Limiting ở tầng application (ví dụ Redis) như thế nào?

**Trả lời chuẩn:**
Rate-based Rule của WAF chặn ở biên ngoài cùng (trước khi request chạm tới ALB/ECS), dựa trên IP trong một khoảng thời gian, hữu ích chống brute-force/DDoS quy mô lớn với chi phí compute gần như zero cho backend. Rate Limiting ở application (Redis) cho phép logic linh hoạt hơn (theo user/API key, theo business rule cụ thể) nhưng vẫn tốn resource compute để xử lý tới tầng đó.

**Ghi nhớ:**
WAF rate-based = chặn sớm, thô, rẻ. App-level rate limiting = linh hoạt, chi tiết, tốn resource hơn.

---

## 33. Vì sao WAF được gắn priority Required cho Fintech/Compliance/Public API của CSNP?

**Trả lời chuẩn:**
Public API của hệ thống fintech là bề mặt tấn công trực tiếp nhất, và yêu cầu compliance (PCI-DSS và tương tự) thường đòi hỏi có lớp bảo vệ Layer 7 rõ ràng trước traffic công khai. Thiếu WAF, mọi request độc hại (SQLi, XSS, bot scraping) đều chạm trực tiếp tới ALB/ECS mà không có lớp lọc trung gian.

**Ghi nhớ:**
Với fintech, WAF không phải "nice to have" — nó là một phần của compliance posture tối thiểu cho Public API.

---

## 34. WAF gắn vào ALB và gắn vào CloudFront khác nhau ở điểm nào?

**Trả lời chuẩn:**
WAF gắn vào ALB bảo vệ traffic tại điểm vào của region cụ thể, chỉ áp dụng cho traffic đã tới ALB đó. WAF gắn vào CloudFront bảo vệ traffic ngay tại edge location toàn cầu, chặn được traffic độc hại trước khi nó đi vào hạ tầng region, đồng thời cũng giảm tải traffic xấu không cần thiết đi xa vào trong hệ thống.

**Ghi nhớ:**
Gắn WAF ở CloudFront (edge) chặn sớm hơn và hiệu quả hơn về băng thông so với gắn ở ALB.
