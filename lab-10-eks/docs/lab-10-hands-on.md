# Lab 10 - Hands-on

## Deliberate practice loop

1. **Mental model:** map ECS concepts sang cluster/node/pod/deployment/service/ingress/HPA và vẽ IAM/network paths.
2. **Console discovery:** xem EKS control plane, node group, add-ons và workload sau Terraform/kubectl apply.
3. **Implementation:** apply cluster, cài controllers rồi deploy app/HPA.
4. **CLI verification:** kết hợp `aws eks` và `kubectl get/describe/events`.
5. **Failure drill:** bad readiness probe, crash loop hoặc pod Pending; chẩn đoán đúng layer trước khi sửa.
6. **Rebuild without guide:** từ cluster output, tự đưa workload tới ingress healthy.
7. **Cleanup/cost audit:** xóa Ingress/LoadBalancer trước node group/cluster; kiểm tra ENI, SG và ALB.
8. **Interview recap:** giải thích control plane, data plane, HPA và node capacity scaling.

Theo dõi lượt luyện: [`../../DELIBERATE_PRACTICE.md`](../../DELIBERATE_PRACTICE.md).

## 1. Apply cluster

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
aws eks update-kubeconfig --name csnp-lab10 --region us-east-1
kubectl get nodes -o wide
```

Giới hạn `public_access_cidrs` thành public IP `/32` của máy admin; không để `0.0.0.0/0`.

## 2. Cài metrics-server và AWS Load Balancer Controller

Dùng EKS add-on/Helm theo tài liệu AWS hiện hành. Controller cần IRSA hoặc EKS Pod Identity với policy scoped phù hợp.

## 3. Deploy app

Sửa image trong `kubernetes/deployment.yaml`, sau đó:

```bash
kubectl apply -f kubernetes/
kubectl rollout status deployment/wallet-api
kubectl get deploy,pod,svc,ingress,hpa
```

## 4. Test HPA

Tạo traffic ngắn, quan sát `kubectl get hpa -w`. HPA cần resource requests và metrics-server.

## 5. Cleanup đúng thứ tự

```bash
kubectl delete -f kubernetes/
terraform destroy
```
