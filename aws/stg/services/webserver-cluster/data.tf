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

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "terraform-state-ken5scal"                # backend config cannot use interpolation
    key    = "stg/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.address}"
    db_port     = "${data.terraform_remote_state.db.port}"
  }
}
