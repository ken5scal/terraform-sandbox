provider "aws" {
  region = "ap-northeast-1"
}

module "webserver_cluster" {
  //  source = "../../../modules/services/webserver-cluster"
  source = "git::git@github.com:ken5scal/modules.git//services/webserver-cluster?ref=v0.0.3"
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-state-ken5scal"
  db_remote_state_key = "stg/data-stores/mysql/terraform.tfstate"
  max_size = "2"
  instance_type = "t2.micro"
  min_size = "2"

  enable_autoscaling = false
}

resource "aws_security_group_rule" "allow_testing_inbound" {
  from_port = 12345
  protocol = "tcp"
  security_group_id = "${module.webserver_cluster.elb_security_group_id}"
  to_port = 12345
  type = "ingress"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-ken5scal"

  versioning {
    enabled = true
  }

  //  lifecycle {
  //    prevent_destroy = true
  //  }
}

# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    bucket = "terraform-state-ken5scal"                         # backend config cannot use interpolation
    key    = "stg/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-1"
  }
}