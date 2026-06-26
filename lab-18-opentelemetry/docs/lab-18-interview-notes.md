# Lab 18 - Interview Notes

## Trace ID và correlation ID

Trace context là chuẩn truyền quan hệ parent/child qua service. Correlation ID có thể là business/request identifier; nên log cả trace ID để nối logs và traces.

## Sampling

Head sampling quyết định sớm, rẻ nhưng có thể bỏ trace lỗi. Tail sampling quyết định sau khi thấy toàn trace, mạnh hơn nhưng cần collector state/capacity.

## Vendor neutrality

OpenTelemetry chuẩn hóa instrumentation và OTLP pipeline; backend vẫn có feature/cost/query model riêng.
