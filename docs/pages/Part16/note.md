# 16.1
## 1) 입력 변수

- 목록은 항상 , 콤마가 있어야 함
- 변수 타입을 지정하지 않으면 기본으로 string 임.

- 테라폼은 변수 정의와 할당 하는 것이 별개이다!!!

- *.tfvars 에 변수를 정의함
tfvars 파일도 git에다가 잘 올리지 않음. 사용자들이 작성하게 함! 올려도 상관 없긴 한데... 잘 안올림

* provider.tf
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

* main.tf
```shell
resource "aws_instance" "my_instance" {
  ami           = var.ami_image[var.aws_region]
  instance_type = var.instance_type

  tags = {
    Name = "MyInstance"
  }
}


resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance.id
}
```

* variable.tf
```tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "ami_image" {
  description = "Ubuntu 20.04 LTS Image"
  type        = map(string)
  default = {
    "ap-northeast-1" = "ami-09ff2b6ef00accc2e"
    "ap-northeast-2" = "ami-0b329fb1f17558744"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

## 16.2 출력 값

## 16.3 로컬 값

### 1) 로컬 값 정의
```tf
locals {
  common_tags = {
    Service = local.service_name
    Owner = local.owner
  }
}
```

### 2) 로컬값의 참조
```tf
local.<NAME>
```

로컬 변수가 또 다른 로컬 변수를 참조 할 수 있다.
```tf
locals {
  common_tags = {
    Service = local.serice_name
    ...
  }
}
```

## 16.4 데이터 소스
클라우드의 데이터도 가져올 수 있다.

#### 1) 데이터 소스 정의
매번 이미지를 찾는 것은 귀찮은 작업이다.
aws_ami 라는 데이터 소스 타입을 쓰면
원하는 이미지 ami 를 가져올 수 있다.

참고 : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

#### 2) 데이터 소스 사용
```tf
data.<TYPE>.<NAME>.<ATTRIBUTE>
```

### 3) 데이터 소스를 사용한 구성 파일
* filter 를 사용한 이미지 검색
```tf
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  
  filter = {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
```

* 실습
- provider.tf
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

- variable.tf
```tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "ami_image" {
  description = "Ubuntu 20.04 LTS Image"
  type        = map(string)
  default = {
    "ap-northeast-1" = "ami-09ff2b6ef00accc2e"
    "ap-northeast-2" = "ami-0b329fb1f17558744"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

- terraform.tfvars
```tf
aws_region = "ap-northeast-2" 
```

- data_source.tf
```tf
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
```

- main.tf
```tf
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
}

resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance.id
}
```