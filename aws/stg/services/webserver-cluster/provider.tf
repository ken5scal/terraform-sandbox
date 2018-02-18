provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-ken5scal"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# https://www.terraform.io/docs/backends/types/s3.html
terraform {
  backend "s3" {
    bucket = "terraform-state-ken5scal"                         # backend config cannot use interpolation
    key    = "stg/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
