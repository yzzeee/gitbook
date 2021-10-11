terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.61"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-2"
}

resource "aws_instance" "my_instance" {
  ami           = "ami-013b765873d42324a" # Ubuntu 18.04 amd64 ami
  instance_type = "t3.micro"

  tags = {
    Name = "MyInstance"
  }
}