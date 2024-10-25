# EKS_Terraform

- Terraform 기반 EKS 구성  
![image](https://github.com/user-attachments/assets/8d1ccd36-6719-4381-acd5-607c17607c8f)


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

