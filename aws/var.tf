variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = "8080"
}

variable "image_id" {
  default = "ami-48630c2e" //ubuntu
}

variable "instance_type" {
  default = "t2.micro"
}

locals {
  public_key_filename = "/Users/Kengo/workspace/terraform-sandbox/aws/terraform-key.pub"
}
