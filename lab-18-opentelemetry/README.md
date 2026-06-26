# Lab 18 - OpenTelemetry + AWS X-Ray

## Mục tiêu

Thu trace chuẩn OpenTelemetry từ Wallet API qua ADOT Collector và export sang AWS X-Ray.

## Requires / Produces

- Requires: Lab 16; EKS workload.
- Produces: ADOT collector config, workload instrumentation patch và IAM policy boundary.

## Flow

```text
Wallet API (OTLP) -> ADOT Collector -> AWS X-Ray
```

## Guardrail

Sampling mặc định thấp để kiểm soát cost và PII. Không ghi request/response body hoặc secret vào span attributes.

## Trạng thái

Code-ready, chưa apply.
