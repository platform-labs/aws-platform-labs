# Lab 19 - Multi-Account Strategy (Optional)

## Mục tiêu

Thiết kế AWS Organizations/landing zone cho CSNP mà không tạo account hoặc thay đổi organization thật từ lab.

## Vì sao lab này docs-first?

`aws_organizations_organization`, account vending và SCP có blast radius cấp tổ chức, cần management account, billing và security approval. Repo lab chỉ tạo design artifacts và policy samples; không tự động apply.

## Proposed OU layout

```text
Root
├── Security
│   ├── Log Archive
│   └── Security Tooling
├── Infrastructure
│   ├── Network
│   └── Shared Services
├── Workloads
│   ├── Dev
│   ├── UAT
│   └── Prod
└── Sandbox
```

## Deliverables

- [Hands-on design exercise](docs/lab-19-hands-on.md)
- [Interview notes](docs/lab-19-interview-notes.md)
- SCP examples trong `policies/`

## Trạng thái

Design-ready; intentionally no Terraform apply.
