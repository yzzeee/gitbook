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
