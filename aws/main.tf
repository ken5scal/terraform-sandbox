provider "aws" {
  region = "ap-northeast-1"
}

data "aws_ami" "amazon_linxu2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "exampel" {
  ami           = "${data.aws_ami.amazon_linxu2.image_id}"
  instance_type = "t2.micro"
}
