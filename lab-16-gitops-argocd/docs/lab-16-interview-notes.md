# Lab 16 - Interview Notes

## GitOps khác CI/CD push?

Agent trong cluster pull/reconcile desired state từ Git. CI không cần credential ghi trực tiếp vào cluster.

## Prune nguy hiểm gì?

Resource bị xóa khỏi Git sẽ bị xóa khỏi cluster. Cần project boundary, sync window, review và bảo vệ resource stateful.

## Drift

GitOps phát hiện và có thể sửa drift, nhưng không thay policy admission, secret management hay backup.
