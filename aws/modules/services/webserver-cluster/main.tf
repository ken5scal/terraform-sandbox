# Specifies how to configure each EC2 instance in the ASG.
resource "aws_launch_configuration" "ex-launch-config" {
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  security_groups = [
    "${aws_security_group.example-sg.id}"]
  key_name = "${aws_key_pair.terraform-key.key_name}"

  # user_data = <<-EOF
  #   #!/bin/bash
  #   echo "Hellom, World" > index.html
  #   echo "${data.terraform_remote_state.db.address}" >> index.html
  #   echo "${data.terraform_remote_state.db.port}" >> index.html
  #   nohup busybox httpd -f -p "${var.server_port}" &
  #   EOF
  user_data = "${element(
    concat(data.template_file.user_data.*.rendered,
    data.template_file.user_data_new.*.rendered),
    0)}"

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
  availability_zones = [
    "${data.aws_availability_zones.all.names}"]
  load_balancers = [
    "${aws_elb.ex-elb.name}"]
  health_check_type = "ELB"
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }
}

# ELB (Classic)
resource "aws_elb" "ex-elb" {
  name = "${var.cluster_name}-elb-example"
  availability_zones = [
    "${data.aws_availability_zones.all.names}"]
  security_groups = [
    "${aws_security_group.sg-elb.id}"]

  listener {
    instance_port = "${var.server_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:${var.server_port}/"
    interval = 30
  }
}

resource "aws_key_pair" "terraform-key" {
  key_name = "terraform-key"
  public_key = "${file("${local.public_key_filename}")}"
}

resource "aws_security_group" "example-sg" {
  name = "${var.cluster_name}-instance-sg"

  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port = "-1"
    to_port = "-1"
    protocol = "icmp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "sg-elb" {
  name = "${var.cluster_name}-sg-elb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = "${aws_security_group.sg-elb.id}"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = "${aws_security_group.sg-elb.id}"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = "${var.enable_autoscaling}"
  // if set to 0 / false, then the resource is not created at all.

  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"
  autoscaling_group_name = "${aws_autoscaling_group.ex-asg.name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = "${var.enable_autoscaling}"
  // if set to 0 / false, then the resource is not created at all.

  scheduled_action_name = "scale-in-at-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"
  autoscaling_group_name = "${aws_autoscaling_group.ex-asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name = "${var.cluster_name}-high-cpu-utilization"
  namespace = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ex-asg.name}"
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  period = 300
  statistic = "Average"
  threshold = 90
  unit = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  count = "${format("%.1s", var.instance_type) == "t" ? 1:0}"

  alarm_name = "${var.cluster_name}-low-cpu-utilization"
  namespace = "AWS/EC2"
  metric_name = "CPUCreditBalance"
  // Only apply to tXXXX instances (e.g., t2micro)

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.ex-asg.name}"
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  period = 300
  statistic = "Minimum"
  threshold = 10
  unit = "Count"
}

resource "aws_iam_user" "example" {
  count = "${length(var.user_names)}"
  name = "${element(var.user_names, count.index)}"
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  "statement" {
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"]
    resources = [
      "*"]
  }
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name = "cloudwatch-read-only"
  policy = "${data.aws_iam_policy_document.cloudwatch_read_only.json}"
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = "${var.give_neo_cloudwatch_full-access}"
  policy_arn = "${aws_iam_policy.cloudwatch_full_access.arn}"
  user = "${aws_iam_user.example.0.name}"
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  "statement" {
    effect = "Allow"
    actions = [
      "cloudwatch:*"]
    resources = [
      "*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name = "cloudwatch-full-access"
  policy = "${data.aws_iam_policy_document.cloudwatch_full_access.json}"
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = "${1 - var.give_neo_cloudwatch_full-access}"
  //if-else statement
  policy_arn = "${aws_iam_policy.cloudwatch_full_access.arn}"
  user = "${aws_iam_user.example.0.name}"
}