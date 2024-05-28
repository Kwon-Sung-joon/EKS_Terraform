# EKS_Terraform

- Terraform 기반 EKS 구성  
![image](https://user-images.githubusercontent.com/43159901/224625063-caeda862-c05f-43ca-9afb-7c2722264198.png)

## 사전 조건
- Terraform 환경 구성
- IAM 구성 (Terraform User)
- S3 및 DynamoDB를 사용한 Terraform Backend 구성

## AWS-Load-Balancer-Controller 설치
```bash

kubectl create sa aws-load-balancer-controller -n kube-system
kubectl annotate serviceaccount -n kube-system aws-load-balancer-controller eks.amazonaws.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_aws_load_balancer_controller

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
 --set clusterName=dev_cluster_1 \
 --set serviceAccount.create=false \
 --set serviceAccount.name=aws-load-balancer-controller
```

## Test-app 배포
```bash
cd ./env/dev/manifest
kubectl apply -f test-app.yml
```


## Karpenter 설치
```bash
helm upgrade --install --namespace kube-system --create-namespace \
karpenter oci://public.ecr.aws/karpenter/karpenter --version 0.35.2 \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_karpenter_controller" \
--set settings.clusterName=dev_cluster_1 \
--set settings.interruptionQueue=dev_karpenter_1_sqs \
--set settings.featureGates.drift= false
--set controller.resources.requests.cpu=1 \
--set controller.resources.requests.memory=1Gi \
--set controller.resources.limits.cpu=1 \
--set controller.resources.limits.memory=1Gi \
--set settings.featureGates.spotToSpotConsolidation=true \
--wait

kubectl apply -f ./env/dev/manifest/NodePool.yml
```



