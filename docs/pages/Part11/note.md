# 11. AWX(**A**nsibleWor**ks**)

Ansible 위에 구축된 웹 기반 사용자 인터페이스<br/>
REST API 및 작업 엔진 제공<br/>
만들어진 플레이북을 실행하고 모니터링 하는 용도, 맹글진 못함

## 11.1 AWX 소개

17버전 이상부터는 쿠버네티스에만 슬치됨<br/>
17버전은 도커에 설치할 수 있는 마지막 버전
### 1) AWX 배포 플랫폼
* OpenShift
* Kubernetes
* Docker

### 2) 시스템 요구사항
* 최소 4GB 메모리
* 최소 2CPU 코어
* 최소 20GB 여유 공간
* Docker, OpenShift, Kubernetes 플랫폼
* PostgresSQL 10+ 데이터베이스 외부/내부 선택

### 3) 사전 요구사항
* Ansible 2.8+
* Docker 최신버전
* docker-compose Python3

### 4) Docker CE 설치
```shell
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

도커 레포지토리 제대로 작성 안되면 아래 참고
```shell
$ cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu   hirsute stable
```

일반 유저도 docker 실행되게 하려면
```shell
sudo usermod -aG docker $USER
sudo init 6 # 아니면 로그아웃 했다가 로그인
```
단 docker push 하고 할떄는 sudo 권한 필요함

https://docs.docker.com/engine/install/ubuntu/

* Docker Compose 라이브러리 및 바이너리 설치
```shell
sudo apt install -y python3-pip
sudo apt install -y docker-compose
```

## 11.2 AWX 설치
* awx Git 저장소 클론
```shell

git clone -b 17.1.0 https://github.com/ansible/awx.git
```
* 인벤토리 변수 설정
```shell
cd awx/installer
vi ~/awx/installer/inventory
admin_password=password
project_data_dir=/var/lib/awx/projects
```


* AWX 설치 플레이북 실행

```shell
ansible-playbook -i inventory install.yml -b
```

* 설치된 컨테이너 확인
```shell
$ docker ps
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS          PORTS                                   NAMES
62a61122bf76   ansible/awx:17.1.0   "/usr/bin/tini -- /u…"   10 minutes ago   Up 10 minutes   8052/tcp                                awx_task
257047fb4be4   ansible/awx:17.1.0   "/usr/bin/tini -- /b…"   12 minutes ago   Up 10 minutes   0.0.0.0:80->8052/tcp, :::80->8052/tcp   awx_web
9eeb1c1b81b5   postgres:12          "docker-entrypoint.s…"   12 minutes ago   Up 10 minutes   5432/tcp                                awx_postgres
45976ea9d46b   redis                "docker-entrypoint.s…"   12 minutes ago   Up 10 minutes   6379/tcp                                awx_redis
```

* 프로젝트의 플레이북 디렉토리 생성
```shell
sudo mkdir -p /var/lib/awx/projects/myplaybook
```

* 테스트용 플레이북 생성
```shell
sudo vi /var/lib/awx/projects/myplaybook.yml/ping.yaml
```
```yaml
- hosts: all
  tasks:
    - name: Ping test
      ping:
```

## 11.3 AWX 사용
