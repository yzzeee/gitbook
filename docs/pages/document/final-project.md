# Terraform 및 Ansible을 이용한 AWS EC2에 Wordpress 배포하기

목표: Terraform으로 AWS EC2 등 리소스를 프로비저닝 하고, AWS EC2 인스턴스에 Wordpress CMS 및 MySQL 데이터베이스를 배포하는 Ansible 역할을 이용하여 애플리케이션을 자동화 배포 및 구성 관리한다.



## 1. Wordpress 및 MySQL 설치 및 구성 명령

시나리오: Wordpress와 MySQL 서버를 같은 EC2 인스턴스에 배포한다.


### 1) Wordpress 설치 및 구성

#### (1) Wordpress 설치

패키지 인덱스를 업데이트 한다.

```
sudo apt update
```

wordpress 패키지 및 관련 패키지를 설치한다.

```
sudo apt install wordpress php libapache2-mod-php php-mysql
```



#### (2) Wordpress를 위한 Apache 구성

wordpress.conf 구성 파일을 작성한다.

> /etc/apache2/sites-available/wordpress.conf

```
Alias /wp /usr/share/wordpress
<Directory /usr/share/wordpress>
    Options FollowSymLinks
    AllowOverride Limit Options FileInfo
    DirectoryIndex index.php
    Order allow,deny
    Allow from all
</Directory>
<Directory /usr/share/wordpress/wp-content>
    Options FollowSymLinks
    Order allow,deny
    Allow from all
</Directory>
```

wordpress 사이트를 활성화 한다.

```
sudo a2ensite wordpress
```

rewrite 모듈을 활성화 한다.

```
sudo a2enmod rewrite
```

apache2 서비스를 리로드 한다.

```
sudo systemctl reload apache2
```



### 2) MySQL 데이터베이스 구성

#### (1) MySQL 설치

패키지 인덱스를 업데이트 한다.

```
sudo apt update
```

mysql-server 및 mysql-client 패키지를 설치한다.

```
sudo apt install mysql-server mysql-client
```



#### (2) 데이터베이스 구성

데이터베이스에 접속한다.

```
sudo mysql -u root
```

wordpress 데이터베이스를 생성한다.

```
mysql> CREATE DATABASE wordpress;
```

wordpress 사용자를 생성하고 wordpress 데이터베이스에 모든 호스트에서 접근할 수 있는 권한을 할당한다.

```
mysql> CREATE USER 'wordpress'@'%' IDENTIFIED BY 'P@ssw0rd';
```

wordpress 사용자가 wordpress 데이터베이스에 권한을 할당한다.

```
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
```

재구성한 권한을 다시 읽는다.

```
mysql> FLUSH PRIVILEGES;
```

데이터베이스를 빠져나간다.

```
mysql> quit
```



#### (3) Wordpress 데이터베이스 구성

데이터베이스 관련 접속정보를 설정하는 구성파일을 생성한다.

> /etc/wordpress/config-default.php

```
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wordpress');
define('DB_PASSWORD', 'P@ssw0rd');
define('DB_HOST', 'localhost');
define('DB_COLLATE', 'utf8_general_ci');
define('WP_CONTENT_DIR', '/usr/share/wordpress/wp-content');
?>
```



### 3. 접속

wordpress에 접속해서 동작을 확인한다.

```
http://192.168.200.101/wp
```



## 2. Wordpress 및 MySQL 설치 및 구성 플레이북 작성

Wordpress 및 MySQL 데이터베이스를 배포하기 위한 Ansible Playbook을 역할 기반으로 작성한다.



- 요구사항
  - 역할
    - wordpress
    - mysql
  - wordpress 역할
    - 작업: 패키지 설치, 구성파일 복사, 모듈 및 사이트 활성화, 서비스 시작
    - 핸들러: 모듈 및 사이트 활성화, 서비스 재시작
    - 변수: 데이터베이스명, 데이터베이스 사용자, 데이터베이스 패스워드(암호화) 등
    - 파일: 구성파일
  - mysql 역할
    - 작업: 패키지 설치, 데이터베이스 생성, 사용자 생성, 사용자 권한 부여, 구성파일 복사(위임 또는 wordpress에서 작업 가능), 서비스 시작
    - 핸들러: 서비스 재시작
    - 변수: 데이터베이스명, 데이터베이스 사용자, 데이터베이스 패스워드(암호화) 등
    - 파일: 구성파일
  - Main 플레이북 작성

# 개인 과제

<b>yaml과 yml 중 yml 확장자만 사용</b>

### 1) wordpress 역할 생성

#### (1) wordpress 역할 빼대 생성

```shell
export WORKDIR=~/project
```

* $WORKDIR/roles/wordpress

```shell
mkdir -pv $WORKDIR/roles/wordpress/{handlers,tasks,templates,vars}
```

```shell
wordpress/
├── handlers
│   └── main.yml
├── tasks
│   ├── main.yml
│   └── ubuntu_wordpress_package.yml
├── templates
│   └── wordpress.conf.j2
└── vars
    └── main.yml
```

#### (2) 변수 관련 파일 작성

* $WORKDIR/roles/wordpress/vars/main.yml

```yaml
wordpress_config_file: wordpress.conf
apache2_wordpress_root: /wp
wordpress_installation_path: /usr/share/wordpress
```

#### (3) 구성 파일 작성

* $WORKDIR/roles/wordpress/templates/wordpress.conf.j2

```config
Alias {{ apache2_wordpress_root }} {{ wordpress_installation_path }}
 <Directory {{ wordpress_installation_path }}>
  Options FollowSymLinks
  AllowOverride Limit Options FileInfo
  DirectoryIndex index.php
  Order allow,deny
  Allow from all
</Directory>
<Directory {{ wordpress_installation_path }}/wp-content>
  Options FollowSymLinks
  Order allow,deny
  Allow from all
</Directory>
```

#### (4) 작업 작성

* $WORKDIR/roles/wordpress/tasks/main.yml

```yaml
- import_tasks: ubuntu_wordpress_package.yml
```

* $WORKDIR/roles/wordpress/tasks/ubuntu_wordpress_package.yml

```yaml
- name: Update and Install Package for wordpress
  apt:
    name: wordpress, php, libapache2-mod-php, php-mysql
    update_cache: true
    state: present

- name: Copy wordpress config
  template:
    src: 'templates/{{ wordpress_config_file }}.j2'
    dest: '/etc/apache2/sites-available/{{ wordpress_config_file }}'
    backup: true
  notify:
    - Link wordpress config
    - Link rewrite module
    - Restart Service
```

#### (5) 핸들러 작성

* $WORKDIR/roles/wordpress/handlers/main.yml

```yaml
- name: Link wordpress config
  file:
    src: '/etc/apache2/sites-available/{{ wordpress_config_file }}'
    dest: '/etc/apache2/sites-enabled/{{ wordpress_config_file }}'
    state: link

- name: Link rewrite module
  file:
    src: '/etc/apache2/mods-available/rewrite.load'
    dest: '/etc/apache2/mods-enabled/rewrite.load'
    state: link

- name: Restart Service
  service:
    name: apache2
    state: restarted
    enabled: true
```



### 2) mysql 역할 생성

#### (1) mysql 역할 빼대 생성

```shell
mkdir -pv $WORKDIR/roles/mysql/{handlers,tasks,templates,vars}
```

```shell
roles/mysql
├── handlers
│   └── main.yml
├── tasks
│   └── main.yml
├── templates
│   └── config-default.php.j2
└── vars
    └── main.yml
```

#### (2) 변수 관련 파일 작성

* $WORKDIR/roles/mysql/vars/main.yml

```yaml
---
mysql_socket: /var/run/mysqld/mysqld.sock
db_name: wordpress
db_user: wordpress
db_password: P@ssw0rd
db_priv: 'wordpress.*:ALL,GRANT'
wordpress_setting_file: config-default.php
```

#### (3) 구성 파일 작성

* $WORKDIR/roles/mysql/templates/config-default.php.j2

```php
<?php
define('DB_NAME', '{{ db_name }}');
define('DB_USER', '{{ db_user }}'); 
define('DB_PASSWORD', '{{ db_password }}'); 
define('DB_HOST', 'localhost'); 
define('DB_COLLATE', 'utf8_general_ci'); 
define('WP_CONTENT_DIR', '/usr/share/wordpress/wp-content');
?>
```

#### (4) 작업 작성

```yaml
---
# tasks file for mysql
- name: install mysql package
  apt:
   name: mysql-server, mysql-client, python3-pymysql
   state: present
   update_cache: yes

- name: Start mysql service
  service:
    name: mysql
    state: started

- name: Create wordpress database
  mysql_db:
    name: '{{ db_name }}'
    state: present
    login_unix_socket: '{{ mysql_socket }}'

- name: Create wordpress user
  mysql_user:
    name: '{{ db_user }}'
    password: '{{ db_password }}'
    state: present
    priv: '{{ db_priv }}'
    login_unix_socket: '{{ mysql_socket }}'

- name: Setting database config
  template:
    src: '{{ wordpress_setting_file }}.j2'
    dest: '/etc/wordpress/{{ wordpress_setting_file }}'
  notify:
    - Restart Service
```

#### (5) 핸들러 작성

* $WORKDIR/roles/mysql/handlers/main.yml

```yaml
- name: Restart Service
  service:
    name: mysql
    state: restarted
    enabled: true
```

### 3) main 플레이북 작성

wordpress 및 mysql 역할을 사용하는 플레이북을 작성한다.

* $WORKDIR/web.yml

```yaml
- name: Deploy Wordpress and MySQL
  hosts: 192.168.200.102
  force_handlers: true

  roles:
    - wordpress
    - mysql
```

### 4) 플레이북 검증

로컬 VM에서 wordpress 및 mysql이 적절하게 배포되고 작동하는지 검증한다.

```shell
ansible-playbook --syntax-check $WORKDIR/web.yml
ansible-playbook $WORKDIR/web.yml -b
```



## 3. AWS 리소스 배포 Terraform HCL 작성

### 1) AWS EC2 리소스 배포용 HCL 작성

#### (1) provider 작성

AWS 프로바이더, 프로바이더 요구사항, Terraform 연격 백엔드를 정의한다.

> provider.tf

```tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.34"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-2"
}
```

#### (2) 변수 정의

필요한 변수를 정의한다.

> variable.tf

```tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "ami_image" {
  description = "Ubuntu 20.04 LTS image"
  type        = map(string)
  default = {
    "ap-northeast-2" = "ami-013b765873d42324a"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

#### (3) 변수 값 설정

정의한 변수의 값을 설정한다.

<b>사용하지 않았음</b>

> terraform.tfvars

#### (4) 로컬 값 설정

리소스의 태그에 설정한 값을 정의하는 로컬 값을 설정한다.

> local.tf

```tf
locals {
  common_tags = {
    Service = "forum"
    Owner   = "Community Team"
  }
}
```

#### (5) 데이터 소스 설정

AWS AMI 이미지 ID를 가져올 수 있는 데이터 소스를 정의한다.

> data_source.tf

```tf
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

#### (6) main 리소스 작성

EC2, EIP, VPC, SSH 키 쌍 리소스 등 구성한다.

EC2 인스턴스 정의시 Ansible 플레이북을 실행할 수 있는 프로비저너를 정의한다.

> main.tf

```tf
resource "aws_instance" "wp_instance" {
  ami                    = data.aws_ami.ubuntu.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.wp_sg_web.id]

  user_data = file("./ansible-pull.sh")

  tags = local.common_tags
}

resource "aws_eip" "wp_eip" {
  vpc      = true
  instance = aws_instance.wp_instance.id
}
```

* git pull 방식 사용하여 구성tt

> ansible-pull.sh

```sh
#!/bin/bash
sudo apt update
sudo apt install ansible -y
sudo apt install git -y
sudo ansible-pull -U https://github.com/$USER/ansible-wordpress-mysql-pull.git -C master -i inventory.ini web.yml
```

#### (7) 보안그룹 리소스 작성

외부에서 접근하는 SSH 및 HTTP 포트를 연다.

> security-group.tf

```tf
resource "aws_security_group" "wp_sg_web" {
  name = "wp-allow-web"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

#### (8) 출력 값 설정

wordpress에 접근할 수 있는 EC2 인스턴스의 외부 IP 및 도메인 주소를 출력을 설정한다.

> output.tf

```tf
output "public_ip" {
  description = "Public IP of Instance"
  value       = aws_instance.wp_instance.*.public_ip
}

output "elestic_ip" {
  description = "Elastic IP of Instance"
  value       = aws_eip.wp_eip.*.public_ip
}
```



### 2) Terraform HCL 계획 및 적용

#### (1) 배포 계획

wordpress 배포를 계획하여 문제가 없는지 검증한다.

```shell
terraform plan
```

실행 결과

```shell

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_eip.wp_eip will be created
  + resource "aws_eip" "wp_eip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags_all             = (known after apply)
      + vpc                  = true
    }

  # aws_instance.wp_instance will be created
  + resource "aws_instance" "wp_instance" {
      + ami                                  = "ami-0a0ac042031ba59d1"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t3.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Owner"   = "Community Team"
          + "Service" = "forum"
        }
      + tags_all                             = {
          + "Owner"   = "Community Team"
          + "Service" = "forum"
        }
      + tenancy                              = (known after apply)
      + user_data                            = "69debbacb54a6f15746bfd42006f7aabec6107f9"
      + user_data_base64                     = (known after apply)
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification {
          + capacity_reservation_preference = (known after apply)

          + capacity_reservation_target {
              + capacity_reservation_id = (known after apply)
            }
        }

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_security_group.wp_sg_web will be created
  + resource "aws_security_group" "wp_sg_web" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "wp-allow-web"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + elestic_ip = [
      + (known after apply),
    ]
  + public_ip  = [
      + (known after apply),
    ]
```



#### (2) 배포 적용

AWS 리소스가 배포되고, Ansible 플레이북으로 Wordpress가 배포된다.

```shell
terraform apply -auto-approve
```

```shell
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_eip.wp_eip will be created
  + resource "aws_eip" "wp_eip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags_all             = (known after apply)
      + vpc                  = true
    }

  # aws_instance.wp_instance will be created
  + resource "aws_instance" "wp_instance" {
      + ami                                  = "ami-0a0ac042031ba59d1"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t3.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Owner"   = "Community Team"
          + "Service" = "forum"
        }
      + tags_all                             = {
          + "Owner"   = "Community Team"
          + "Service" = "forum"
        }
      + tenancy                              = (known after apply)
      + user_data                            = "69debbacb54a6f15746bfd42006f7aabec6107f9"
      + user_data_base64                     = (known after apply)
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification {
          + capacity_reservation_preference = (known after apply)

          + capacity_reservation_target {
              + capacity_reservation_id = (known after apply)
            }
        }

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_security_group.wp_sg_web will be created
  + resource "aws_security_group" "wp_sg_web" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "wp-allow-web"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + elestic_ip = [
      + (known after apply),
    ]
  + public_ip  = [
      + (known after apply),
    ]
aws_security_group.wp_sg_web: Creating...
aws_security_group.wp_sg_web: Creation complete after 2s [id=sg-00a6b50d9f753b422]
aws_instance.wp_instance: Creating...
aws_instance.wp_instance: Still creating... [10s elapsed]
aws_instance.wp_instance: Creation complete after 13s [id=i-085faf8192370fa88]
aws_eip.wp_eip: Creating...
aws_eip.wp_eip: Creation complete after 1s [id=eipalloc-030d329fa3424f087]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

elestic_ip = [
  "3.37.192.78",
]
public_ip = [
  "3.38.130.215",
]
```

### 3) 검증

#### (1) AWS 리소스 배포 확인 및 검증

> 스크린샷

![aws](.\aws.png)

#### (2) Wordpress 접속 확인 및 검증

> 스크린샷

![wordpress-init](.\wordpress-init.png)

![wordpress-dashboard](wordpress-dashboard.png)











