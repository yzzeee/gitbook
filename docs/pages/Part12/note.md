# 12. Terraform 기본

* Ansible이 구성관리를 한다면, Terraform은 프로비저닝을 담당
* 절차적 언어가 아닌 선언적 언어이다.
* HCL을 이용하여 정의
* 이 세상은 계속 바뀌기 마련 테라폼에서도 그 바뀌는 API 들을 위해 열심히 일을 한다.

### 1) 코드형 인프라
### 2) 실행 계획
실제 배포하기 전에 계획을 함.

### 3) 리소스 종속성
테라폼 엔진이 알아서 처리한다.

### 4) 변경 자동화
## 12.1 Terraform 소개
## 12.2 Terraform 주요기능
## 12.3 Terraform 워크플로우

1) 구성파일 작성

* git 저장소 생성
```shell
git init myinfra && cd myinfra
```
* 구성파일 작성
```shell
vi main.tf
```
* Terraform 초기화
```shell
terraform init
```

* 계획
배포를 하기전 시뮬레이션
```shell
terraform plan
```

* 적용
인프라를 배포
```shell
terraform apply
```

