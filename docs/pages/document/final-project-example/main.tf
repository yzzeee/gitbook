module "wp_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = local.common_tags
}

resource "aws_instance" "wp_instance" {
  ami                    = data.aws_ami.ubuntu.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.wp_sg_web.id]
  key_name               = aws_key_pair.wp_sshkey.key_name
  subnet_id              = module.wp_vpc.public_subnets[0]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./wp_sshkey")
    host        = self.public_ip
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y python3",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOF
      echo "${self.public_ip} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=wp_sshkey ansible_python_interpreter=/usr/bin/python3 ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > inventory.ini
    EOF
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini main.yaml"
  }

  tags = local.common_tags
}

resource "aws_key_pair" "wp_sshkey" {
  key_name   = "wp_sshkey"
  public_key = file("./wp_sshkey.pub")
}

resource "aws_eip" "wp_eip" {
  vpc      = true
  instance = aws_instance.wp_instance.id
}
