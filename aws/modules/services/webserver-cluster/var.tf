variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = "8080"
}

variable "image_id" {
  default = "ami-48630c2e"
  //ubuntu
}

variable "instance_type" {
//  default = "t2.micro"
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
}

variable "min_size" {
  description = "The min number of EC2 Instances in the ASG"
}

variable "max_size" {
  description = "The max number of EC2 Instances in the ASG"
}

locals {
  public_key_filename = "/Users/Kengo/workspace/terraform-sandbox/aws/terraform-key.pub"
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the db's remote state"
}

variable "db_remote_state_key" {
  description = "The path for the db's remote state in S3"
}