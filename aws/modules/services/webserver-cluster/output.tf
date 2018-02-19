output "elb_dns_name" {
  value = "${aws_elb.ex-elb.dns_name}"
}

output "asg_name" {
  value = "${aws_autoscaling_group.ex-asg.name}"
}