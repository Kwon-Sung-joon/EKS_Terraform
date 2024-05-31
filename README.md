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



## AWS-Load-Balancer-Controller 설치
```bash

helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
 --set clusterName=dev_cluster_1 \
 --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_aws_load_balancer_controller"

```
## Karpenter 설치
```bash
helm template --namespace kube-system --create-namespace \
karpenter oci://public.ecr.aws/karpenter/karpenter \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/irsa_karpenter_controller" \
--set settings.clusterName=dev_cluster_1 \
--set settings.interruptionQueue=dev_karpenter_1_sqs \
--set settings.featureGates.drift=false \
--set controller.resources.requests.cpu=0.5 \
--set controller.resources.requests.memory=512Mi \
--set controller.resources.limits.cpu=0.5 \
--set controller.resources.limits.memory=512Mi \
--set settings.featureGates.spotToSpotConsolidation=true > karpenter.yml

vi karpenter.yml
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: karpenter.sh/nodepool
                operator: DoesNotExist
              - key: eks.amazonaws.com/nodegroup
                operator: In
                values:
                - dev-dev_node_group_private  #구성된 노드 그룹 명
          - weight: 50
            preference:
              matchExpressions:
              - key: karpenter.sh/nodepool
                operator: In
                values:
                - dev-private-node

kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.35.2/pkg/apis/crds/karpenter.sh_nodepools.yaml"
kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.35.2/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml"
kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.35.2/pkg/apis/crds/karpenter.sh_nodeclaims.yaml"

kubectl applf -f karpenter.yml
kubectl apply -f ./env/dev/manifest/PublicNodePool.yml
kubectl apply -f ./env/dev/manifest/PrivateNodePool.yml
```
## Karpenter NodePool 지정하여 Deploy 생성
```bash
e.g. alb 타입 


```



## Argo 설치
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


```