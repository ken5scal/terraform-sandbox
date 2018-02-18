# Specifies how to configure each EC2 instance in the ASG.
resource "aws_launch_configuration" "ex-launch-config" {
  image_id        = "${var.image_id}"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.example-sg.id}"]
  key_name        = "${aws_key_pair.terraform-key.key_name}"

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

# ASG itself
resource "aws_autoscaling_group" "ex-asg" {
  launch_configuration = "${aws_launch_configuration.ex-launch-config.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  load_balancers       = ["${aws_elb.ex-elb.name}"]
  health_check_type    = "ELB"
  min_size             = 2
  max_size             = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# ELB (Classic)
resource "aws_elb" "ex-elb" {
  name               = "terraform-elb-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.sg-elb.id}"]

  listener {
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:${var.server_port}/"
    interval            = 30
  }
}

resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = "${file("${local.public_key_filename}")}"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sg-elb" {
  name = "terraform-ex-elb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}