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

resource "aws_launch_configuration" "ex-launch-config" {
  image_id        = "${var.image_id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.example-sg.id}"]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hellom, World" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    EOF

  # meta-parameter
  lifecycle {
    # If you set this to true, then set it to true on every resource
    # that this resource depends on
    create_before_destroy = true
  }
}

resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = "${file("${local.public_key_filename}")}"
}

resource "aws_instance" "example" {
  # ami                    = "${data.aws_ami.amazon_linxu2.image_id}"
  ami                    = "${var.image_id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.example-sg.id}"]
  key_name               = "${aws_key_pair.terraform-key.key_name}"

  user_data = <<-EOF
    #!/bin/bash
    echo "Hellom, World" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "example-sg" {
  name = "terraform-example-sg"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = "8080"
}

variable "image_id" {
  default = "ami-48630c2e"
}

variable "instance_type" {
  default = "t2.micro"
}

output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}

locals {
  public_key_filename = "/Users/Kengo/workspace/terraform-sandbox/aws/terraform-key.pub"
}
