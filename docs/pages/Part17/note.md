# 17장 구성 관리 및 프로비저너

## 17.1 Cloud-init 구성 관리
https://cloudinit.readthedocs.io/en/latest/

대부분의 클라우드 가상화 솔루션 배포 이미지에<br/>
cloud-init 이라는 소프트웨어가 포함되어 있다.<br/>
시스템 구성 관리를 할 수 있다.

🚗🚗 234쪽 1) 실습
* data_source.tf
```tf
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
} 
```

* local.tf
```tf
locals {
  common_tags = {
    Service = "forum"
    Owner   = "Community Team"
  }
}
```

* main.tf
```tf
resource "aws_instance" "jolla_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.my_sg_web.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install -y httpd
    sudo systemctl --now enable httpd
    echo "<h1>Hello world<h1>" | sudo tee /var/www/html/index.html
  EOF

  tags = local.common_tags
}

resource "aws_eip" "my_eip" {
  vpc      = true

```

* provider.tf

* security-group.tf

* terraform.tfvars

* variable.tf

* web_deploy.sh


`terraform apply -auto-approve` 로 적용

## 17.2 Cloud-init을 사용한 구성 파일


## 17.3 프로비저너

cloud-init을 주로 사용하고 terraform의 프로비저너는 최후의 수단으로만 사용한다.<br/>
왜냐하면 ssh 접속 되므로 보안상 그렇다.

- 일반 프로비저너
  file : 파일 및 디렉토리 복사 (Ansible 의 copy와 비슷)
  local-exec : Terraform이 실행되는 로컬에서 실행
  remote-exec : 원격 인스턴스에서 실행

- 벤더 프로비저너
  chef
  habitat
  puppet
  salt-masterless
  Ansible은 없다 ㅠㅠ

### 1) 프로비저너 정의
```tf
resource "aws_instance" "web" {
...
```
self 는 자기 자신을 의미 (aws_instance.web)

(2) 테인트
테인트 되어있던 리소스는 다음번 배포 시에 교체된다.
* 테인트 해제
`terrafform untain aws instance.my_instance`





## 17.5

Ansible 풀모드!!
`ansible-pull -U https://github.com/c1t1d0s7/ansible-pull-example.git -C main -i hosts.ini playbook.yaml`

기존의 예제에서 SSH 키를 등록하고 aws 인스턴스에 ansible 을 설치하여 playbook.yaml 을 실행하도록 변경.
```tf
resource "aws_instance" "my_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.my_sg_web.id]
  key_name               = aws_key_pair.my_sshkey.key_name

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./my_sshkey")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "playbook.yaml"
    destination = "/home/ec2-user/playbook.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install ansible2 -y",
      "sudo yum install git -y",
      "ansible-pull -U https://github.com/c1t1d0s7/ansible-pull-example.git -C main -i hosts.ini playbook.yaml",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOF
      echo "${self.public_ip} ansible_ssh_user=ec2-user ansible_ssh_private_key_file=./my_sshkey" > inventory.ini
    EOF
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -t rsa ${self.public_ip} >> ~/.ssh/known_hosts"    
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini playbook.yaml"
  }
}

resource "aws_key_pair" "my_sshkey" {
  key_name   = "my_sshkey"
  public_key = file("./my_sshkey.pub")
}

resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance.id
}
```
taint 를 걸어서 기존의 인스턴스를 제거하고 다시 올리자!

* 생성한 인스턴스에 내 공개키를 등록하기
1) 생성한 인스턴스의 아이피 조회
```shell
terraform show | grep -i public_ip
```

2) 생성한 인스턴스에 접속
```shell
ssh-copy-id ec2-user@3.37.217.207
ssh -i my_sshkey.pub ec2-user@3.37.217.207
```