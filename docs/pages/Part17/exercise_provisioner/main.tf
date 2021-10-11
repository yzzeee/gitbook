resource "aws_instance" "my_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.my_sg_web.id]
  key_name = aws_key_pair.my_sshkey.key_name

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("./my_sshkey")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "web_deploy.sh"
    destination = "/tmp/web_deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web_deploy.sh",
      "/tmp/web_deploy.sh"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ipaddr.txt"
  }

  tags = local.common_tags
}

resource "aws_key_pair" "my_sshkey" {
  key_name   = "my_sshkey"
  public_key = file("./my_sshkey.pub")
}

resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance.id
}