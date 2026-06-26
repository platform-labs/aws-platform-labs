# Lab 16 - Hands-on

## Deliberate practice loop

1. **Mental model:** vẽ Git desired state → Argo CD reconcile → Kubernetes live state → drift detection.
2. **Console discovery:** dùng Argo CD UI để xem app tree/diff/sync; implementation vẫn qua Git/manifests.
3. **Implementation:** cài Argo CD, AppProject và Application rồi commit desired state.
4. **CLI verification:** `kubectl`/Argo CD CLI kiểm tra sync, health, revision và events.
5. **Failure drill:** sửa replica trực tiếp và commit manifest lỗi; recovery phải đi qua Git.
6. **Rebuild without guide:** từ cluster trống, tự đưa application về Synced/Healthy.
7. **Cleanup/cost audit:** xóa Application trước Argo CD; xác nhận LoadBalancer/ALB được dọn.
8. **Interview recap:** giải thích pull-based delivery, prune risk và drift ownership.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=10m
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

Verify:

```bash
kubectl get applications -n argocd
kubectl get pods -n wallet
```

Drift drill: sửa replica trực tiếp bằng `kubectl scale`, quan sát Argo CD self-heal về Git.

Rollback: revert Git commit, không sửa tay cluster.
