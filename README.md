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
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version 0.37.0 --namespace kube-system --create-namespace \
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
  --set "awsRegion=ap-northeast-2" \
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

## Nginx Ingress Controller 설치

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

#custom_values.yml
controller:
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-name: "nlb-name"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: '60'

helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx  --namespace kube-system -f custom_values.yml
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
argocd account update-password

argocd repo add https://Git주소 --username <계정> --password 로그인키등록

```
## Argo Image Update 설치
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd-image-updater argo/argocd-image-updater  --namespace argo-cd --create-namespace -f argocd-image-updater-custom-value.yml

#ArgoCD Account 생성, RBAC 권한 부여 후 토큰 발급하여 secret 생성
#ArgoCD Application Annotation 설정
#argocd-image-updater.argoproj.io/image-list = test-app=<ACCOUNT-ID>.dkr.ecr.ap-northeast-2.amazonaws.com/test
#argocd-image-updater.argoproj.io/test-app.helm.image-name=deployment.image.name <Helm 변수>
#argocd-image-updater.argoproj.io/test-app.helm.image-tag=deployment.image.tag <Helm 변수>
#argocd-image-updater.argoproj.io/test-app.update-strategy=newest-build


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

## Observability
```bash
# prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --create-namespace \
    --set alertmanager.persistentVolume.storageClass="gp3" \
    --set server.persistentVolume.storageClass="gp3"

kubectl apply -f prometheus-server-ingress.yml 


# grafana
helm repo add grafana https://grafana.github.io/helm-charts

helm upgrade --install grafana grafana/grafana \
    --namespace grafana --create-namespace \
    --set persistence.storageClassName="gp3" \
    --set persistence.enabled=true \
    --set adminPassword='admin0!' \
    -f grafana.yaml
#Pixie
```


