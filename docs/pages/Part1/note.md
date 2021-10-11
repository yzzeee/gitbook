# 1. IaC 개요
Infrastructure as Code<br/>
Ansible, Terraform 등이 여기에 해당됨

코드의 자동화 빠른 환경 제공 가능

Ansible : 구성관리 도구<br/>
Terraform : 배포도구

## 1.1 IaC 장점
- 비용절감
- 빠른속도
- 안정성
- 코드화 및 버젼 관리
- 재사용성

## 1.2 IaC 도구 및 특징 비교
### 1) 구성 관리/배포
* 구성관리 도구<br/>
Ansible, Chef, Puppet, SaltStack 등<br/>
시스템(베어메탈, VM, Intance 등) 내에서<br/>
패키지 설지, 애플리케이션 구성, 운영체제 관련 구성 빛 구성 변경 관리하는 도구<br/>
<br/>
* 배포도구
AWS CloudFormation, OpenStack Heat, Terraform 등<br/>
새로운 인프라 리소스 배포, 이미 배포된 인프라 생명 주기 관리

### 2) 가변 인프라 / 불변 인프라
가변 인프라 : 추가 할꺼 있으면 추가하고, 시간이 지남에 따라 패치가 필요히면 패치도 함<br/>
불변 인프라 : 가상이미지, 컨테이너 이미지등 한번 배포된 후에 변하지 않는 인프라

ex) https://cloudscaling.com/blog/clod-computing/the-history-of-pets-vs-cattle/

### 3) 절차적/선언적 언어
Ansible 은 절차적 언어: 순차적으로 실행<br/>
Terraform 은 선언적 언어임: 내가 어떤 상태를 유지하겠다! 선언하면 그 상태를 유지<br/>
'최종적으로 어떻게 될 것이다!' 하고 정의를 하면 내부적으로 알아서 진행됨<br/>

### 4) 마스터 및 에이전트 유무
서버가 있으면 당연히 서버도 관리해줘야함!

agent가 있다는 것은 전용 프로토콜을 사용한다는 것임 따라서 관리 대상에 agent 설치가 필요함<br/>
그래서 agent가 있으면 agent도 관리해야하고 귀찮음<br/>
그런데 ansible은 ssh를 사용하기땜에 서버만 있으면 됨<br/>
테라폼도 restful 사용하니깐 관리 대상에 agent 설치가 필요없음

마스터 - IaC 도구를 가지고 있는 서버

Ansible이 인기 있었던 이유
1. 코드가 쉬움
2. YAML(문서 형태 포맷)을 사용하므로 특정 랭귀지를 습득할 필요가 없음