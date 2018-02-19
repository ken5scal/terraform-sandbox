provider "aws" {
  region = "ap-northeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-state-ken5scal"
  db_remote_state_key = "stg/data-stores/mysql/terraform.tfstate"
  max_size = "2"
  instance_type = "t2.micro"
  min_size = "2"
}