* Part6 까지의 실습 복습
```yaml
---
- name: Simple Web Deploy
  hosts: 192.168.200.101
  vars:
    contents_file: index.php # 플레이에만 유효한 변수
    apache_port: "8080"

  tasks:
    - name: Install Pacakge for Ubuntu
      apt:
        name: apache2, libapache2-mod-php
        update_cache: true # apt update에 해당
        state: present
      when: ansible_distribution == "Ubuntu" # 우분투인 시스템에만 적용

    - name: Install Package for CentOS
      yum:
        name: httpd, mod-php # 패키지명은 명확하지 않으나 작동하지 않으므로 skip
        state: present
      when: ansible_distribution == "CentOS"

    - name: Copy PHP Contents
      copy:
        src: '{{ contents_file }}'
        dest: '/var/www/html/{{ contents_file }}'
        backup: true

    - name: Configure Apache Port
      template:
        src: ports.conf.j2
        dest: '/etc/apache2/ports.conf'
      notify:
        - Restart Service

    - name: Start Service
      service:
        name: apache2
        state: started
        enabled: true

    - name: Checking
      uri:
        url: "http://192.168.200.101:{{ apache_port }}/{{ contents_file }}"
      ignore_errors: true
      delegate_to: 192.168.200.102
      # 새로운 플레이를 작성해도 되나 변수의 유효범위를 고려하면<br/>
      # 하나의 플레이에 작성하는 것이 유리

  handlers:
    - name: Restart Service
      service:
        name: apache2
        state: restarted
```

contents_file, apache_port 당 는 해당 플레이에서만 유효하다.<br/>
아래 또 다른 플레이를 작성할 경우 변수 참조 안됨.

# 7. 작업 제어 - 고급

## 7.1 작업 오류 처리
Ansible의 대다수 모듈의 성공여부를 처리하는 방법은 return code가 0이냐?를 판별<br/>


### 1) 실패한 명령 무시
```yaml
- name: Do not this as a failure
  command: /bin/false
  ignore_errors: yes
```
- 리턴 코드가 0이 아닌 경우만 작동
- 기본값은 당연히 no!
- 본래대로 라면 상황에 대한 조치를 취해 주어야 하므로<br/>
  중요한 작업이 아닌 경우에만 사용하길 바람.


### 2) 연결할 수 없는 호스트 무시
* 작업 수준에서 연결할 수 없는 호스트 무시
```yaml
- name: This executes, files, and the failure is ignored
  command: /bin/true
  ignore_unreachable: yes

- name: This executes, fails, and ends the play for this host
  command: /bin/true
```
- 관리 노드에 네트워크 연결이 불가한 경우 무시
- 중간에 sleep 을 넣어서 일정시간 기다린 후에 확인하는 방법도 있음.
- 잘 사용안함. 그냥 이런게 있더라~ 라고 아셈.

* 플레이 수준에서 연결할 수 없는 호스트 무시
```yaml
- hosts: all
  ignore_unreachable: yes
  tasks:
    - name: This executes, fails, and the failure is ignored
      command: /bin/true
    - name: This executes, fails, and ends the play for this host
      command: /bin/true
      ignore_unreachable: no
```

### 3) 핸들러의 실패
* ansible.cfg
`force_handlers = True`

* Play
`force_handlers: True`

* 명령줄 옵션
`ansible-playbook --force-handlers`

핸들러는 알림이 있을 때만 발동이 되는데 해당 옵션을 주면 반드시 핸들러를 동작하게 할 수 있다.

### 4) 실패 재정의
Ansible에서 when이 들어가면 조건문!

* 명령 모듈의 출력에서 특정 단어나 구를 검색하여 실패 여부를 재정의
```yaml
- name: Fail task when the command error output prints FAILED
  command: /usr/bin/example-command -x -y -z
  register: command_result
  failed_when: "'FAILED' in command_result.stderr"
```
항상 register를 함께 사용함

* 뭐지? 갑자기 이거 실습..
```yaml
- hosts: 192.168.200.101
  tasks:
  - command: ls -l
    register: comm_result

  - debug:
      var: comm_result
```

* 반환 코드 기반으로 실패 여부를 재정의
```yaml
- name: Fail task when both files are identical
  raw: diff foo/file1 bar/file2
  register: result
  failed_when:
    - result.rc == 0
    - '"No such" not in result.stdout'
```
* 여러 조건을 결합
```yaml
- name: Check
  command: 
```
등등등...

### 5) 변경 재정의
특정 상태를 변경 상태로 정의함 (일부러!) <br/>
특정 조건에서 핸들러를 트리거 해야하는 경우 ! <br/>

### 6) command 및 shell 모듈 작업의 성공 보장
```yaml
tasks:
  - name: Run this command and ignore the result
    shell: /usr/bin/somecommand || /bin/false
```
이런 작업의 경우 대부분 command 모듈에 해당한다.

### 7) 모든 호스트 작업 중단

#### (1) 첫 번째 오류에서 중단
`any_errors_fatal` 키워트 사용 시 작업 실패 시 모든 호스트의 작업이 중단<br/>

#### (2) 최대 실패율 설정
일정 이상의 실패를 하게되면 중단 `max_fail_percentage` <br/>
그렇게 많이 사용하는 기능은 아니지만 알아두면 나중에 참고할 수 있겠죠?

## 7.2 전략 및 롤링 업데이트
### 1) 전략의 종류
* 전략 종류 확인
`ansible-doc -t strategy -l`
#### (1) 선형 전략
기본값
특정 호스트의 작업을 완료하여야 다음으로 넘아감
#### (2) 자유 전략
플레이가 끝나면 다음 플레이로 진행
#### (3) 호스트 핀 전략
플레이 내에서의 작업은 자유전략과 동일하게 다음 작업을 실행<br/>
플레이 단위로 끊어지며 다른 호스트를 기다림
#### (4) 디버그 전략
디버깅을 위해서 사용하는 전략

### 2) 전략 변경
* 플레이북에서 전략 변경
```yaml
- hosts: all
  strategy: free
  tasks:
  ...
```

* ansible.cfg에서 전략 변경
```yaml
[defaults]
strategy = free
```
### 3) 포크
* 실습
```shell
mkdir ~/strategy
cd strategy
```
* inventory.ini
```yaml
[local]
127.0.0.[1:9] ansible_connection=local
```
* ansible.cfg
```yaml
[defaults]
inventory=inventory.ini
deprecation_warnings=False
```
* strategy.yaml
```yaml
- hosts: local
  gather_facts: no
  tasks:
  - name: T1
    command: sleep 5
  - name: T2
    command: sleep 5
  - name: T3
    command: sleep 5
```

```shell
absible-playbook strategy.yaml
```

```shell
ansible-playbook strategy.yaml -f 2 # 동시에 작업할 호스트의 수를 2로 설정
```
-f : fork 옵션 동시에 작업을 몇개 실행할지 (기본값: 5)

* ansible.cfg
```cfg
[default]
forks = 30
```
배치전략 - serial: 1 (1대의 노드에만 배치를 시켜라)
플래이에만 설정 가능 왜냐규? 배치를 플래이 단위로 하기 때문에.

### 4) 배치 크기 설정
```shell
<pre><font color="#4E9A06"><b>azwell@azwell-KVM</b></font>:<font color="#3465A4"><b>~/strategy</b></font>$ ansible-playbook strategy.yaml

PLAY [local] **********************************************************************

TASK [T1] *************************************************************************
<font color="#C4A000">changed: [127.0.0.2]</font>
<font color="#C4A000">changed: [127.0.0.3]</font>
<font color="#C4A000">changed: [127.0.0.1]</font>

TASK [T2] *************************************************************************
<font color="#C4A000">changed: [127.0.0.2]</font>
<font color="#C4A000">changed: [127.0.0.1]</font>
<font color="#C4A000">changed: [127.0.0.3]</font>

TASK [T3] *************************************************************************
<font color="#C4A000">changed: [127.0.0.2]</font>
<font color="#C4A000">changed: [127.0.0.1]</font>
<font color="#C4A000">changed: [127.0.0.3]</font>

PLAY [local] **********************************************************************

TASK [T1] *************************************************************************
<font color="#C4A000">changed: [127.0.0.6]</font>
<font color="#C4A000">changed: [127.0.0.4]</font>
<font color="#C4A000">changed: [127.0.0.5]</font>

TASK [T2] *************************************************************************
<font color="#C4A000">changed: [127.0.0.6]</font>
<font color="#C4A000">changed: [127.0.0.4]</font>
<font color="#C4A000">changed: [127.0.0.5]</font>

TASK [T3] *************************************************************************
<font color="#C4A000">changed: [127.0.0.5]</font>
<font color="#C4A000">changed: [127.0.0.6]</font>
<font color="#C4A000">changed: [127.0.0.4]</font>

PLAY [local] **********************************************************************

TASK [T1] *************************************************************************
<font color="#C4A000">changed: [127.0.0.9]</font>
<font color="#C4A000">changed: [127.0.0.7]</font>
<font color="#C4A000">changed: [127.0.0.8]</font>

TASK [T2] *************************************************************************
<font color="#C4A000">changed: [127.0.0.7]</font>
<font color="#C4A000">changed: [127.0.0.9]</font>
<font color="#C4A000">changed: [127.0.0.8]</font>

TASK [T3] *************************************************************************
<font color="#C4A000">changed: [127.0.0.7]</font>
<font color="#C4A000">changed: [127.0.0.8]</font>
<font color="#C4A000">changed: [127.0.0.9]</font>

PLAY RECAP ************************************************************************
<font color="#C4A000">127.0.0.1</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.2</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.3</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.4</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.5</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.6</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.7</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.8</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
<font color="#C4A000">127.0.0.9</font>                  : <font color="#4E9A06">ok=3   </font> <font color="#C4A000">changed=3   </font> unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

</pre>
```
... html 태그는 신경쓰지 말 것.

배치 할 노드 대수를 점점 늘릴수 있다.
```yaml
serial:
  - 1
  - 5
  - 10
```

### 5) 작업 실행 제한
throttle 키워드로 정의할 수 있으며<br/>
특정 작업 및 블록 수준에서 정의 할 수 있음.

당연하게도 serial이나 fork보다 작아야함

```yaml
task:
- command: /path/to/cpu_intensive_comand
  throttle: 1
```

## 7.3 비동기
Ansible은 기본적을 작업을 동기식으로 함<br/>
비동기식으로 할 수도 있는데 task 를 백그라운드로 돌리고자 할때 사용.
오래 걸리는 작업에 사용.
ex) 파일 다운로드를 걸어놓고 다른 작업을 수행하고자 할경우

우분투는 ssh 세션 타임아웃이 없어서 괜춘한데<br/>
레드햇 계열은 300초인가 그래요.

node 2대가 있을때 선형전략에 의해서
node1 작업이 끝나야 node2 작업이 실행됨.
이떄 SSH 세션이 끊어 질 수 있는데
물론 Ansible 이 세션을 다시 연결하긴함.
근데 세션을 끊고 맺음은 성능 저하를 야기시킴.

따라서 세션이 끊어 지는것을 방지하려면 다음과 같이 설정함.

```shell
/etc/ssh/sshd/config
ClientAliveInterval: 클라이언트에서 데이터가 전소오디지 않는 시간 (기본값: 0)
ClientAliveClientMax: ClientAliveInterval 최대 허용 개수 (기본값: 3)
SSH Session Timeout = ClientAliveInterval * ClientAliveClientMax
```

### 1) 비동기 Ad-hoc 명령
`ansible web1 -B 600 -P -0 -a "sleep 1M"`
* -B --background: 비동기로 실행할 작업의 타임아웃 시간(단위: 초)
* -P, --poll : 비동기 작업을 폴링할 간격 (기본: 15초)
```shell
ansible 192.168.200.101 -B 100 -P 2 -a 'sleep 1m'
```
-P를 0으로 해야 실질적으로 비동기가 되는 것임

```shell
$ ansible 192.168.200.101 -B 100 -P 0 -a 'sleep 10m'
192.168.200.101 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "ansible_job_id": "851144312989.40358",
    "changed": true,
    "finished": 0,
    "results_file": "/home/vagrant/.ansible_async/851144312989.40358",
    "started": 1
}

```
백그라운드에 10분동안 작업을 하게 됨

작업 확인
```shell
$ ansible 192.168.200.101 -m async_status -a 'jid=851144312989.40358'
192.168.200.101 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "ansible_job_id": "851144312989.40358",
    "changed": false,
    "finished": 0,
    "started": 1
}
```

또는 watch 사용
```shell
$ watch -n1 ansible 192.168.200.101 -m async_status -a 'jid=851144312989.40358'
$ watch -d ansible 192.168.200.101 -m async_status -a 'jid=851144312989.40358'
```



### 2) 비동기 플레이북 작업

#### (2) 비동기 작업(poll=0)
async: 45
poll: 0
이것이 -B 옵션의 역할
```yaml
ansible.cfg
  [defaults]
  inventory=inventory.ini
  deprecation_warnings=False
```


```yaml
  - hosts: 192.168.200.101
    tasks:
      - name: T1
        ping:

      - name: T2 - async
        command: sleep 1m
        async: 200
        poll: 0
        register: async_result

      - name: T3
        ping:

      - name: T4
        ping:

      - name: T5 - sync
        async_status:
          jid: "{{ async_result.ansible_job_id }}"
        register: job_result
        until: job_result.finished
        retries: 100
        delay: 10

      - name: T6
        ping:
```

## 7.4 태그

모든 작업은 all 이라는 태그가 붙는다.

### 1) 플래이북에 태그 추가

#### (1) 작업에 태그 추가
#### (2) 블록에 태그 추가

### 2) 태그 사용
`--tags [tag1, tag2]`: tag1 및 tag2 태그가 있는 작업 만 실행<br/>
`--skip-tags [tag3, tag4]`:  <br/>
`--tags tagged`: 태그 설정된 작업만 실행<br/>
`--tags untagged`: 태그 없는 작업만 실행
```yaml
---
- hosts: 192.168.200.101
  tasks:
  - name: task1
    ping:
    tags:
    - prod
  - name: task2
    ping:
    tags:
    - prod
    - stage
  - name: task3
    ping:
    tags:
    - stage
  - name: task4
    ping:
```

* 플레이북의 태그 확인
`ansible-playbook <yaml 명> --list-tasks`

* 태그 관련 작업 목록 확인
`ansible-playbook <yaml 명> --tags "configuration,packages` --list-tasks

### 3) 특수 태그
## 7.5 작업 시작 및 단계

### 1) 작업 시작
실패한 특정 작업 부터 시작 할 수 있다.
`ansible-playbook <YAML 파일명> --start-at-task="install packages"`

### 2) 작업 단계
`ansible-playbook <YAML 파일명> --step`

* 책에 없는데 선생님이 알려주시고 싶은거!
* .ansible.cfg의 [defaults]에다가 해당 옵션
`retry_files_enabled = true`
어떤 호스트에서 작업이 실패하였는지 .retry 파일을 생성한다.

`ansible-playbook <YAML 파일명> --limit @web.retry`
실패한 호스트들에만 재시도!! 대규모 작업 시 해당 경로파일에 적힌 호스트만 재작업을 할 수 있다.