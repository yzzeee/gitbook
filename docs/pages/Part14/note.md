# 14. 구성파일 작성

## 14.1 구성 파일 및 디렉토리
테라폼은 현재 디렉토리에 있는 모든 .tf or tf.json 파일 다 읽어 들임.

UTF8 인코딩을 사용하며 Windows 의 CRLF 도 허용한다.
다만, 가능하면 LF 타입을 쓰자.

## 14.2 구성 파일 기본
구성 파일에는 프로바이더, 프로바이더 요구사항, 리소스 등을 정의함.
다만 프로바이더는 꼭 안들어 가도 됨.

프로바이더는 블록으로 정의함.
블록 하나가 프로바이더 하나를 정의함.

들여쓰기에 민감하지 않음.

### 3) 프로바이더

* 프로바이더 예시
```tf
terraform {
  required_providers {
    aws = {
      source = "hashicopr/aws"
      version = "~> 3.34"
    }
  }
}
```
~/.aws/config 폴더에 있음
```shell
 cat .aws/config
[default]
region = ap-northeast-2
```
* aws 설정 목록 보기
```shell
$ aws configure list
      Name                    Value             Type    Location
      ----                    -----             ----    --------
   profile                <not set>             None    None
access_key     ****************AXUH shared-credentials-file    
secret_key     ****************EESP shared-credentials-file    
    region           ap-northeast-2      config-file    ~/.aws/config
```

https://registry.terraform.io/browse/providers

* 리소스 블록 정의 형식
```tf
resource "<RESOURCE_TYPE>" "<NAME>" {
  <IDENTIFIER> = <EXPRESSION> #ARGUMENT
}
```

## 14.3 

## 14.3 구성 파일 작성

* aws ami(amazon machine image) 우분투 인스턴스 이미지 찾기
  https://cloud-images.ubuntu.com/locator/ec2/

```tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.34"
    }
  }
}

provider "aws" {
  profile = "default"
  region = "ap-northeast-2"
}

resource "aws_instance" "my_instance" {
  ami = "ami-05784cd9865e31efd" # Ubuntu 18.04 amd64 ami
  instance_type = "t3.micro"

  tags = {
    Name = "MyInstance"
  }
}
```