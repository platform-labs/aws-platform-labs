# Lab 19 - Interview Notes

## Vì sao multi-account?

Account là isolation boundary mạnh cho billing, quotas, IAM và blast radius. OU giúp áp guardrail theo nhóm account.

## SCP có thay IAM policy?

Không. Effective permission là giao của identity/resource policies, permission boundary, session policy và SCP. SCP không grant.

## Control Tower

Control Tower xây landing zone và guardrails trên Organizations; vẫn cần ownership cho customization, drift, account lifecycle và exceptions.
