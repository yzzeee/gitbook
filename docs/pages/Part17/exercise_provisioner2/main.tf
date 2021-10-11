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

  provisioner "local-exec" {
    command = <<-EOF
      echo "${self.public_ip} ansible_ssh_user=ec2-user ansible_ssh_private_key_file=./my_sshkey" > inventory.ini
    EOF
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.ini playbook.yaml"
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