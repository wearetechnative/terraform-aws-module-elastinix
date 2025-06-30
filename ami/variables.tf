variable "bootstrap_img_path" {
  description = "local path to ami image"
  type = string
}
variable "name" {
  description = "name of the ami"
  type = string
}

variable "infra_environment" {
  description = "infra enviroment"
  type = string
}

variable "aws_account_id" {
  description = "aws account id"
  type = string
}
