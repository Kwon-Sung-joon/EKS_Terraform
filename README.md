# EKS_Terraform

- Terraform 기반 EKS 구성  
![image](https://user-images.githubusercontent.com/43159901/224625063-caeda862-c05f-43ca-9afb-7c2722264198.png)

## 사전 조건
- Terraform 환경 구성
- IAM 구성 (Terraform User)
- S3 및 DynamoDB를 사용한 Terraform Backend 구성


## metrics 서버 배포
```bash
cd ./env/dev/manifest
kubectl apply -f metrics-server.yml
```
## Karpenter 설치
```bash
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --namespace kube-system --create-namespace \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_karpenter_controller" \
--set settings.clusterName=dev_cluster_1 \
--set settings.interruptionQueue=dev_karpenter_1_sqs \
--set settings.featureGates.drift=false \
--set controller.resources.requests.cpu=0.5 \
--set controller.resources.requests.memory=512Mi \
--set controller.resources.limits.cpu=0.5 \
--set controller.resources.limits.memory=512Mi \
--set settings.featureGates.spotToSpotConsolidation=true \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight=100" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key=karpenter.sh/nodepool" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator=In" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]=dev-private-node" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].weight=1" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].key=eks.amazonaws.com/nodegroup" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].operator=In" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].values[0]=dev-dev_node_group_private" \
--set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution=null"


kubectl applf -f karpenter.yml
kubectl apply -f ./env/dev/manifest/PublicNodePool.yml
kubectl apply -f ./env/dev/manifest/PrivateNodePool.yml
```
## Karpenter NodePool 지정하여 Deploy 생성
```bash
e.g. alb 타입 
helm repo add eks https://aws.github.io/eks-charts

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --namespace kube-system --create-namespace \
  --set clusterName=dev_cluster_1 \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_aws_load_balancer_controller" \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=karpenter.sh/nodepool \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=In \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]=dev-public-node \
  --set affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution.topologyKey=kubernetes.io/hostname
  
```

## AWS-Load-Balancer-Controller 설치
```bash

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
 --set clusterName=dev_cluster_1 \
 --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_aws_load_balancer_controller"

```



## Argo 설치
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


```