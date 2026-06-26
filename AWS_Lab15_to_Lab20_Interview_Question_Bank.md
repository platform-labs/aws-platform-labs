# AWS Platform Labs - Volume 4: Senior Platform (Lab 15 → Lab 20) Interview Question Bank

> Tài liệu ôn tập theo dạng **câu hỏi phỏng vấn + câu trả lời chuẩn + ghi nhớ production**.
>
> Phạm vi: Lab 15 CloudFront, Lab 16 GitOps (ArgoCD), Lab 17 External Secrets, Lab 18 OpenTelemetry, Lab 19 Multi Account Strategy, Lab 20 Disaster Recovery.

---

# LAB 15 - CloudFront

## 1. CDN giải quyết vấn đề gì mà ALB không giải quyết được?

**Trả lời chuẩn:**
ALB phục vụ traffic từ một region cố định, người dùng ở xa region đó sẽ gặp latency cao. CDN (CloudFront) cache nội dung tĩnh tại edge location gần người dùng trên toàn cầu, giảm latency và giảm tải trực tiếp lên ALB/origin vì phần lớn request được trả từ cache ngay tại edge.

**Ghi nhớ:**
ALB tối ưu phân phối traffic trong region. CDN tối ưu khoảng cách địa lý tới người dùng cuối.

---

## 2. Edge Caching hoạt động ra sao, dữ liệu nào nên cache và không nên cache?

**Trả lời chuẩn:**
Edge Caching lưu response tại Point of Presence (PoP) gần người dùng, dựa trên Cache-Control header và Cache Policy của CloudFront Distribution. Nội dung tĩnh (ảnh, CSS, JS, file build frontend) nên cache lâu vì ít đổi. Nội dung động cá nhân hóa (dữ liệu tài khoản, transaction) không nên cache vì có thể trả sai dữ liệu cho người khác.

**Ghi nhớ:**
Cache những gì giống nhau cho mọi người. Không cache những gì khác nhau theo từng user.

---

## 3. Vì sao CloudFront được roadmap đánh priority "Để sau" cho CSNP?

**Trả lời chuẩn:**
CSNP là hệ thống fintech với phần lớn traffic là API động, cá nhân hóa theo user (giao dịch, số dư) — lợi ích của CDN caching tĩnh chưa lớn ở giai đoạn hiện tại so với việc hoàn thiện observability, resilience, và security (WAF) trước. CloudFront sẽ hữu ích hơn khi có nhiều static asset (frontend SPA) cần phân phối toàn cầu.

**Ghi nhớ:**
Ưu tiên đầu tư hạ tầng theo lợi ích thực tế hiện tại của hệ thống, không theo "công nghệ nên có".

---

## 4. Origin Access Control (OAC) trong CloudFront dùng để làm gì?

**Trả lời chuẩn:**
OAC đảm bảo S3 Bucket làm origin chỉ nhận traffic từ chính CloudFront Distribution đó, không cho phép truy cập S3 trực tiếp qua URL công khai. Điều này buộc mọi traffic phải đi qua CloudFront (để tận dụng cache, WAF, HTTPS), tránh người dùng bypass CDN truy cập trực tiếp origin.

**Ghi nhớ:**
OAC = đảm bảo "chỉ một cửa vào" cho origin, tránh lộ S3 endpoint trực tiếp ra ngoài.

---

# LAB 16 - GitOps (ArgoCD)

## 5. GitOps khác CI/CD truyền thống (Lab 8, GitHub Actions push trực tiếp) ở điểm nào?

**Trả lời chuẩn:**
CI/CD truyền thống (push-based) để pipeline chủ động chạy lệnh deploy thẳng vào cluster (ví dụ `kubectl apply` hoặc update ECS Service từ GitHub Actions). GitOps (pull-based) để một controller (ArgoCD) chạy trong cluster tự liên tục so sánh state khai báo trong Git với state thực tế trong cluster, và tự đồng bộ khi phát hiện khác biệt — Git trở thành single source of truth.

**Ghi nhớ:**
Push-based: pipeline đẩy thay đổi vào cluster. Pull-based (GitOps): cluster tự kéo thay đổi từ Git.

---

## 6. Vì sao GitOps được coi là an toàn hơn cho production so với CI/CD push trực tiếp?

**Trả lời chuẩn:**
GitOps không yêu cầu cấp credential cluster cho hệ thống CI/CD bên ngoài (giảm attack surface), mọi thay đổi đều đi qua Git (có review, audit trail, rollback bằng `git revert`), và controller trong cluster tự phát hiện drift (khi ai đó sửa tay trực tiếp ngoài Git) để tự sửa lại đúng theo Git.

**Ghi nhớ:**
GitOps giảm bề mặt tấn công (không cần credential ngoài) và tăng khả năng audit/rollback nhờ Git làm nguồn sự thật.

---

## 7. Drift Detection trong ArgoCD là gì, xử lý ra sao khi phát hiện drift?

**Trả lời chuẩn:**
Drift là khi state thực tế trong cluster khác với state khai báo trong Git (ví dụ ai đó `kubectl edit` trực tiếp). ArgoCD liên tục so sánh hai state này; khi phát hiện drift, tùy cấu hình Sync Policy, ArgoCD có thể tự động sync lại (auto-sync) để đưa cluster về đúng trạng thái khai báo trong Git, hoặc chỉ cảnh báo (manual sync) để người vận hành xem xét trước.

**Ghi nhớ:**
Drift Detection bảo vệ nguyên tắc "Git là nguồn sự thật duy nhất" — mọi thay đổi tay ngoài Git đều bị coi là sai lệch cần xử lý.

---

## 8. App of Apps pattern trong ArgoCD giải quyết vấn đề gì?

**Trả lời chuẩn:**
Khi có nhiều microservice (Wallet, Payment, Ledger...), quản lý từng ArgoCD Application riêng lẻ thủ công sẽ khó scale. App of Apps tạo một ArgoCD Application "cha" chỉ chứa định nghĩa của các Application "con", giúp quản lý tập trung việc thêm/sửa/xóa cả nhóm service chỉ qua một thay đổi Git duy nhất.

**Ghi nhớ:**
App of Apps = quản lý tập hợp nhiều service bằng một điểm khai báo duy nhất trong Git, dễ scale theo số lượng service.

---

# LAB 17 - External Secrets

## 9. External Secrets Operator giải quyết vấn đề gì so với việc lưu Secret trực tiếp trong Kubernetes Secret object?

**Trả lời chuẩn:**
Kubernetes Secret object chỉ encode base64 (không mã hóa thật) và phải tạo/sửa thủ công hoặc qua manifest — nếu commit nhầm vào Git thì secret bị lộ. External Secrets Operator đồng bộ secret từ một nguồn tin cậy bên ngoài (AWS Secrets Manager) vào Kubernetes Secret tự động, secret thật không bao giờ nằm trong Git, chỉ có "tham chiếu" tới secret nằm trong manifest.

**Ghi nhớ:**
External Secrets giúp Git chỉ chứa "đường dẫn tới secret", không chứa secret thật — giảm rủi ro leak qua Git.

---

## 10. Secret Rotation tự động qua Secrets Manager + External Secrets Operator hoạt động ra sao?

**Trả lời chuẩn:**
Secrets Manager có thể tự rotate secret (như đổi password RDS) theo schedule hoặc qua Lambda rotation function. External Secrets Operator định kỳ poll Secrets Manager, phát hiện secret đã đổi, và tự cập nhật lại Kubernetes Secret tương ứng trong cluster — application sau đó cần được thiết kế để đọc lại secret mới (qua restart pod hoặc reload runtime) mà không cần con người can thiệp thủ công.

**Ghi nhớ:**
Rotation tự động chỉ thật sự an toàn khi cả 3 mắt xích đồng bộ: Secrets Manager rotate → ESO đồng bộ lại K8s Secret → app reload đúng cách.

---

## 11. Vì sao không nên dùng Kubernetes ConfigMap để lưu connection string có chứa password?

**Trả lời chuẩn:**
ConfigMap được thiết kế cho dữ liệu cấu hình không nhạy cảm, không có cơ chế kiểm soát truy cập chặt như Secret object, thường hiển thị rõ ràng (plain text) khi xem qua `kubectl describe` hoặc `kubectl get configmap -o yaml`. Bất cứ thông tin nhạy cảm (password, API key) đều phải đi qua Secret object (hoặc tốt hơn, External Secrets từ Secrets Manager), không bao giờ đặt trong ConfigMap.

**Ghi nhớ:**
ConfigMap = cấu hình công khai. Secret/External Secrets = thông tin nhạy cảm, không bao giờ lẫn vào nhau.

---

# LAB 18 - OpenTelemetry

## 12. Distributed Tracing giải quyết vấn đề gì mà Logs và Metrics riêng lẻ không giải quyết được?

**Trả lời chuẩn:**
Trong hệ thống microservices, một request đi qua nhiều service (Wallet → Payment → Ledger). Logs riêng lẻ từng service khó nối lại thành một flow hoàn chỉnh, Metrics chỉ cho biết "có vấn đề" ở mức tổng quát. Distributed Tracing gắn một Trace ID xuyên suốt toàn bộ request qua mọi service, cho phép xem chính xác request đó đi qua đâu, mất bao lâu ở mỗi bước, lỗi xảy ra ở service nào.

**Ghi nhớ:**
Logs = chi tiết từng điểm. Metrics = tổng quan xu hướng. Tracing = nối toàn bộ hành trình một request cụ thể qua nhiều service.

---

## 13. OpenTelemetry khác AWS X-Ray như thế nào, vì sao roadmap dùng cả hai?

**Trả lời chuẩn:**
OpenTelemetry (OTel) là chuẩn vendor-neutral để thu thập trace/metrics/logs, không phụ thuộc AWS — giúp tránh vendor lock-in và dễ migrate backend observability khác sau này. AWS X-Ray là backend cụ thể của AWS để lưu trữ và visualize trace. Roadmap dùng OTel SDK để instrument code (chuẩn, portable) và gửi data tới X-Ray (hoặc backend khác) làm nơi lưu trữ/hiển thị.

**Ghi nhớ:**
OTel = chuẩn thu thập dữ liệu (portable). X-Ray = một trong các backend lưu trữ/hiển thị (AWS-specific) có thể thay thế.

---

## 14. Span và Trace khác nhau như thế nào trong OpenTelemetry?

**Trả lời chuẩn:**
Trace là toàn bộ hành trình của một request xuyên qua hệ thống, được định danh bởi một Trace ID duy nhất. Span là một đơn vị công việc cụ thể trong hành trình đó (ví dụ một lệnh gọi database, một HTTP call tới service khác), có thời gian bắt đầu/kết thúc riêng và có thể có Span con (child span) lồng bên trong. Một Trace gồm nhiều Span ghép lại thành một cây.

**Ghi nhớ:**
Trace = toàn bộ câu chuyện. Span = từng chương/đoạn cụ thể trong câu chuyện đó.

---

## 15. Context Propagation trong Distributed Tracing nghĩa là gì, vì sao quan trọng với message queue (RabbitMQ/Kafka)?

**Trả lời chuẩn:**
Context Propagation là việc truyền Trace ID/Span ID từ service gọi sang service được gọi, để cả hai cùng thuộc một Trace duy nhất. Với gọi đồng bộ (HTTP), context được nhúng vào header. Với message queue (bất đồng bộ), context phải được nhúng vào message metadata (header của message), để consumer đọc message vẫn nối tiếp đúng Trace của producer, dù xử lý cách nhau về thời gian.

**Ghi nhớ:**
Không propagate context qua message queue đúng cách, Trace sẽ bị "đứt" giữa producer và consumer, mất khả năng theo dõi end-to-end.

---

# LAB 19 - Multi Account Strategy

## 16. Vì sao nên tách nhiều AWS Account thay vì dùng một Account chung cho mọi môi trường?

**Trả lời chuẩn:**
Một Account chung cho dev/staging/production tạo rủi ro lớn: lỗi ở dev (xóa nhầm resource, IAM policy sai) có thể ảnh hưởng production cùng account; khó áp dụng billing/cost tracking riêng theo môi trường; và blast radius khi một credential bị leak sẽ ảnh hưởng toàn bộ hệ thống, không chỉ một môi trường. Multi Account cách ly hoàn toàn theo môi trường/team, account là security boundary mạnh nhất trong AWS.

**Ghi nhớ:**
Account boundary là ranh giới cách ly mạnh nhất AWS cung cấp — mạnh hơn IAM Policy hay VPC isolation.

---

## 17. AWS Organizations và Landing Zone đóng vai trò gì trong Multi Account Strategy?

**Trả lời chuẩn:**
AWS Organizations cho phép quản lý tập trung nhiều account (billing hợp nhất, Service Control Policy áp dụng chung). Landing Zone (qua Control Tower hoặc tự thiết kế) là bộ khung chuẩn hóa: tự động tạo account mới theo template đã định (đã có baseline security, logging, networking), đảm bảo mọi account mới đều tuân theo guardrail chung ngay từ đầu, không cần setup tay từng lần.

**Ghi nhớ:**
Organizations = quản lý nhiều account tập trung. Landing Zone = quy trình chuẩn hóa tạo account mới an toàn, nhất quán.

---

## 18. Vì sao Lab 19 được làm "docs-first" (chỉ viết ADR/docs, chưa thực thi) theo roadmap?

**Trả lời chuẩn:**
Multi Account Strategy có blast radius ở cấp AWS Organization — sai sót khi thiết lập (ví dụ Service Control Policy sai) có thể ảnh hưởng tất cả account hiện có cùng lúc, khó rollback nhanh. Vì vậy roadmap chủ động làm docs-first: thiết kế kỹ, viết ADR, review logic trước khi thực thi thật, giảm rủi ro phá vỡ toàn bộ cấu trúc account đang chạy các lab khác.

**Ghi nhớ:**
Khi blast radius của một thay đổi vượt quá một resource đơn lẻ (ảnh hưởng toàn Organization), luôn ưu tiên thiết kế kỹ trên docs trước khi thực thi.

---

## 19. Service Control Policy (SCP) khác IAM Policy như thế nào?

**Trả lời chuẩn:**
IAM Policy áp dụng cho identity (user/role) trong một account cụ thể, xác định identity đó được làm gì. SCP áp dụng ở cấp Organization/OU, đặt giới hạn tối đa (guardrail) cho toàn bộ account nằm trong phạm vi đó — SCP không cấp quyền, chỉ có thể giới hạn quyền, dù IAM Policy trong account có cho phép, SCP vẫn có thể chặn nếu nằm ngoài giới hạn.

**Ghi nhớ:**
SCP là "trần giới hạn" áp từ trên xuống toàn Organization. IAM Policy là quyền cụ thể trong từng account, không thể vượt qua trần đó.

---

# LAB 20 - Disaster Recovery

## 20. Bốn chiến lược DR phổ biến trên AWS (Backup & Restore, Pilot Light, Warm Standby, Multi-Site Active-Active) khác nhau ở đâu?

**Trả lời chuẩn:**
Backup & Restore: chi phí thấp nhất, RTO/RPO cao nhất (chậm nhất để phục hồi), chỉ có backup data, phải dựng lại hạ tầng khi cần. Pilot Light: giữ sẵn core resource tối thiểu (ví dụ database replica) ở region phụ, scale lên khi cần. Warm Standby: chạy phiên bản scale-down đầy đủ ở region phụ, sẵn sàng scale lên nhanh. Multi-Site Active-Active: cả hai region đều phục vụ traffic thật, RTO/RPO gần như zero nhưng chi phí cao nhất.

**Ghi nhớ:**
Chi phí và RTO/RPO luôn tỷ lệ nghịch: muốn phục hồi nhanh hơn (RTO/RPO thấp) phải trả nhiều tiền hơn để giữ resource sẵn sàng.

---

## 21. RTO và RPO khác nhau như thế nào, ví dụ cụ thể cho CSNP?

**Trả lời chuẩn:**
RTO (Recovery Time Objective) là thời gian tối đa chấp nhận được để hệ thống hoạt động trở lại sau sự cố. RPO (Recovery Point Objective) là khoảng dữ liệu tối đa chấp nhận được có thể bị mất (tính theo thời gian từ lần backup gần nhất). Ví dụ CSNP có thể đặt RTO = 1 giờ (hệ thống phải chạy lại trong 1 giờ) và RPO = 5 phút (chấp nhận mất tối đa 5 phút dữ liệu giao dịch gần nhất).

**Ghi nhớ:**
RTO = "bao lâu thì sống lại". RPO = "mất bao nhiêu dữ liệu là chấp nhận được".

---

## 22. Cross-Region Backup khác Cross-AZ Multi-AZ (đã học ở Lab 9 Aurora) như thế nào, vì sao vẫn cần cả hai?

**Trả lời chuẩn:**
Multi-AZ bảo vệ trước sự cố ở cấp Availability Zone (datacenter riêng lẻ trong cùng region), nhưng không bảo vệ được nếu toàn bộ region gặp sự cố nghiêm trọng (hiếm nhưng có thể xảy ra) hoặc lỗi logic xóa nhầm dữ liệu lan ra cả region. Cross-Region Backup lưu bản sao ở region hoàn toàn khác, là lớp bảo vệ cuối cùng khi mọi giải pháp trong region chính đều thất bại.

**Ghi nhớ:**
Multi-AZ chống lỗi hạ tầng cục bộ trong region. Cross-Region Backup chống rủi ro toàn region hoặc lỗi logic nghiêm trọng.

---

## 23. Vì sao chỉ test Backup mà không test Restore định kỳ là một sai lầm phổ biến?

**Trả lời chuẩn:**
Có backup không đồng nghĩa với có khả năng phục hồi — backup có thể bị corrupt, thiếu một phần dữ liệu phụ thuộc (như secret/config cần để app chạy lại), hoặc quy trình restore chưa từng được thử nên khi cần thật sự sẽ mất nhiều thời gian hơn dự kiến (vi phạm RTO). DR Drill (diễn tập restore thật, định kỳ) là cách duy nhất xác nhận chiến lược DR thực sự hoạt động.

**Ghi nhớ:**
"Backup chưa từng test restore" gần như tương đương với "không có backup" về mặt đảm bảo thực tế.
