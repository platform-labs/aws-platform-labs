# Lab 18 - Hands-on

## Deliberate practice loop

1. **Mental model:** application spans → OTLP → collector processors → X-Ray backend và trace context propagation.
2. **Console discovery:** xem X-Ray service map/trace details và collector workload sau deploy.
3. **Implementation:** cài ADOT, cấp identity và instrument Wallet API.
4. **CLI verification:** xem collector logs, pod env/config và tìm trace ID/correlation ID.
5. **Failure drill:** break exporter permission hoặc downstream call; xác định span nào lỗi và vì sao.
6. **Rebuild without guide:** tự tạo end-to-end trace cho một request qua ít nhất hai components.
7. **Cleanup/cost audit:** gỡ collector/instrumentation test, kiểm tra sampling và telemetry ingestion.
8. **Interview recap:** giải thích metrics/logs/traces, head/tail sampling và vendor neutrality.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

1. Cài AWS Distro for OpenTelemetry operator/collector theo tài liệu AWS hiện hành.
2. Cấp IRSA/Pod Identity cho collector với `AWSXrayWriteOnlyAccess` hoặc policy scoped tương đương.
3. Apply collector và patch deployment.
4. Gửi request có correlation ID, tìm trace trong X-Ray.

Verify service map, latency segments và error status. Tạo một downstream call lỗi để thấy distributed trace nối span.
