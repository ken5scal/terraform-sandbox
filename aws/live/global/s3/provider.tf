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
    bucket = "terraform-state-ken5scal"    # backend config cannot use interpolation
    key    = "global/s3/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

# After creating S3 bucket, use following to configure
# Terraform to store the sate in your S3 bucket w/ encryption
# terraform init


# IT WILL NOT SOLVE locking for the state files
# use Terraform Enterprise or Pro (or CircleCI, Terragrunt)


# IT WILL NOT SOLVE isolation problem for the state files
# place files to make it Environment base, component base...and so on
# env level(stage, prod, mgmt, global)
## mgmg -> Devops tooling (eg, bastion, jenkins)
## global -> use in all envs(S3, IAM)
# component level(vpc, services, data-storage
## vpc
## services: microservices. ci, bastion, rails frontend, scala backentd...
## data-storage: mysql, redis
# config files
## vars.tf
## main.tf
## output.tf

