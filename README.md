# EKS_Terraform

- Terraform 기반 EKS 구성  
![image](https://github.com/user-attachments/assets/1b370bdb-91e5-4e77-941d-938c5ceeb72e)



## 사전 조건
- Terraform 환경 구성
- IAM 구성 (Terraform User)
- S3 및 DynamoDB를 사용한 Terraform Backend 구성
- ECR 및 테스트 앱

## 디렉토리 구성
- env : terraform 백엔드 및 main 파일 구성
- module : terraform 커스텀 모듈 및 manifest 구성

## 모듈 변수 구성
- 각 모듈 구성의 변수는 map(object({})) 타입으로 구성

## helm 구성
- Karpenter
- AWS Load Balancer Controller
- ArgoCD
- ArgoCD Image Updater
- Promethues
- Fluent Bit

## 사용 방법

- module.helm_release 의 local 변수 중 Karpenter를 제외 한 나머지 변수는 주석 처리 하여 최초 terraform apply
```text
최초 apply 후 karpenter 구성 전은 AutoScalingGroup 및 EC2 Launch Template을 사용하기 떄문에
초기 구성 이후 NodePool, EC2NodeClass 설정을 통하여 Karpenter 노드 구성 
```
- module.eks_node_group 주석 처리 후 최초 apply 시 주석 처리 한 module.helm_release의 local 변수 주석 해제 후 terraform apply



## Kubernetes Dashboard Install
```bash
kubectl apply -f kubernetes-dashboard-token.yml -n kubernetes-dashboard

kubectl get secret dashboard-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
#해당 값으로 configmap/kubernetes-dashboard-proxy 수정

kubectl apply -f kubernetes-dashboard-proxy.yml -n kubernetes-dashboard

```