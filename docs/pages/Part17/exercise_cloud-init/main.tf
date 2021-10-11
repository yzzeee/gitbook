resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
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
  instance = aws_instance.my_instance.id
}