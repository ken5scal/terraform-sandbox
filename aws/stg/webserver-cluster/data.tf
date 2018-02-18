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

# each AWS account has access to a slightly diff set of AZs
# so fetch the AZs specific to the AWS account
data "aws_availability_zones" "all" {}
