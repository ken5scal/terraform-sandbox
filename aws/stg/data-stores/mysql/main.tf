provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_db_instance" "ex-db" {
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "ex_db"
  username          = "admin"
  password          = "${var.db_password}"
}

# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    bucket = "terraform-state-ken5scal"                # backend config cannot use interpolation
    key    = "stg/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
