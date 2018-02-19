provider "aws" {
  region = "ap-northeast-1"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "terraform-state-ken5scal"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  max_size = "10"
  min_size = "2"
  instance_type = "m4.large"
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"
  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  autoscaling_group_name = "scale-in-at-night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"
  scheduled_action_name = "${module.webserver_cluster.asg_name}"
}