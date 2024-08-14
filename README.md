# EKS_Terraform

- Terraform 기반 EKS 구성  
![image](https://user-images.githubusercontent.com/43159901/224625063-caeda862-c05f-43ca-9afb-7c2722264198.png)

## 사전 조건
- Terraform 환경 구성
- IAM 구성 (Terraform User)
- S3 및 DynamoDB를 사용한 Terraform Backend 구성
- ECR 및 테스트 앱

## 모듈 변수 구성
- 각 모듈의 구성의 변수는 map(object({})) 타입으로 구성

## metrics 서버 배포
```bash
cd ./env/main/manifest
kubectl apply -f metrics-server.yml
```

## Karpenter 설치
```bash
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --namespace kube-system --create-namespace \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/irsa_karpenter_controller" \
--set settings.clusterName=dev_cluster_1 \
--set settings.interruptionQueue=dev_karpenter_1_sqs \
--set settings.featureGates.drift=false \
--set settings.featureGates.spotToSpotConsolidation=true \
--set dnsPolicy=Default \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight=100" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key=karpenter.sh/nodepool" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator=In" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]=dev-private-node-on-demand" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].weight=1" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].key=eks.amazonaws.com/nodegroup" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].operator=In" \
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].values[0]=dev-private-node-on-demand" \
--set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution=null"

kubectl apply -f ./env/main/manifest/PrivateNodePool.yml
```

## ClusterAutoScaler 설치
```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace "kube-system" \
  --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}" \
  --set "awsRegion=${AWS_REGION}" \
  --set "image.tag=v${CLUSTER_AUTOSCALER_IMAGE_TAG}" \
  --set "rbac.serviceAccount.name=cluster-autoscaler" \
  --set "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$CLUSTER_AUTOSCALER_ROLE" \
  --wait

```


## AWS-Load-Balancer-Controller 설치
### Karpenter NodePool 지정하여 생성
```bash
#참고 https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/ingress/annotations/

helm repo add eks https://aws.github.io/eks-charts
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --namespace kube-system --create-namespace \
  --set clusterName=dev_cluster_1 \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/irsa_aws_load_balancer_controller" \
  --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=karpenter.sh/nodepool" \
  --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=In" \
  --set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]=dev-private-node" \
  --set "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].key=app.kubernetes.io/name"\
  --set "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].operator=In" \
  --set "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].matchExpressions[0].values[0]=aws-load-balancer-controller" \
  --set "affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey=kubernetes.io/hostname"
```

## Argo 설치
```bash
#참고 https://artifacthub.io/packages/helm/argo/argo-cd
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm upgrade --install argo-cd argo-cd/argo-cd --namespace argo-cd --create-namespace -f argo-custom-values.yaml

kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

#argocd cli install
# Download the binary
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

argocd login http://argo-cd.com --username admin --password el2E3xR1J8rTLL5r --insecure

```

## KEDA 설치
```bash
#https://github.com/kedacore/keda
helm repo add kedacore https://kedacore.github.io/charts

helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=arn:aws:iam::$ACCOUNT_ID:role/irsa_keda" \
  --wait

```