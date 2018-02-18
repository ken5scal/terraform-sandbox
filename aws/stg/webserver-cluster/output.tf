output "elb_dns_name" {
  value = "${aws_elb.ex-elb.dns_name}"
}
