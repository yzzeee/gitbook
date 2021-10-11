resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  tags = local.common_tags
}


resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance.id
}
