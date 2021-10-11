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