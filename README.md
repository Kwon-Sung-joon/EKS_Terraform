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
cd ./env/dev/manifest
kubectl apply -f metrics-server.yml
```
## coredns addon 설치
```bash
# 현재 버전 확인
kubectl describe deployment coredns --namespace kube-system | grep coredns: | cut -d : -f 3
#
aws eks describe-addon --cluster-name dev_cluster_1 --addon-name coredns --query addon.addonVersion --output text
```

## Karpenter 설치
#### 정상 동작하지 않을 시 coredns deploy restart
```bash
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --namespace kube-system --create-namespace \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::$ACCOUNT_ID:role/irsa_karpenter_controller" \
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
--set "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].values[0]=dev_node_group_private" \
--set "affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution=null"

kubectl apply -f ./env/dev/manifest/PrivateNodePool.yml
```
## AWS-Load-Balancer-Controller 설치
### Karpenter NodePool 지정하여 생성
```bash

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
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
``` 

## Argocd server ssl 비활성화

```yaml
#edit configmap : argocd-cmd-params-cm
apiVersion: v1
data:
  server.insecure: "true"
kind: ConfigMap
metadata:
...

kubectl rollout restart deployment argocd-server -n argocd

```

## Promethues 설치
```bash

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics


cat >> prometheus_values.yaml
serviceAccounts:
  server:
    name: amp-iamproxy-ingest-service-account
    annotations: 
      eks.amazonaws.com/role-arn: ${IAM_PROXY_PROMETHEUS_ROLE_ARN}
server:
  remoteWrite:
    - url: https://aps-workspaces.${REGION}.amazonaws.com/workspaces/${WORKSPACE_ID}/api/v1/remote_write
      sigv4:
        region: ${REGION}
      queue_config:
        max_samples_per_send: 1000
        max_shards: 200
        capacity: 2500

helm install prometheus prometheus-community/prometheus -n kube-system \
-f prometheus_values.yaml


#참조 https://aws.amazon.com/ko/blogs/korea/amazon-managed-service-for-prometheus-collector-provides-agentless-metric-collection-for-amazon-eks/
```