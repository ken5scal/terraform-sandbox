output "elb_dns_name" {
  value = "${aws_elb.ex-elb.dns_name}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform_state.arn}"
}
