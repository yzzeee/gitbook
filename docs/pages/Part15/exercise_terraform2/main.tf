
resource "aws_instance" "my_instance_a" {
  ami           = "ami-013b765873d42324a" # Ubuntu 18.04 amd64 ami
  instance_type = "t3.micro"

  tags = {
    Name = "MyInstanceA"
  }
}


resource "aws_instance" "my_instance_b" {
  ami           = "ami-013b765873d42324a" # Ubuntu 18.04 amd64 ami
  instance_type = "t3.micro"

  tags = {
    Name = "MyInstanceB"
  }

  depends_on = [aws_s3_bucket.my_bucket]
}


resource "aws_eip" "my_eip" {
  vpc      = true
  instance = aws_instance.my_instance_a.id

  tags = {
    Name = "MyInstanceA"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  acl = "private"
}
