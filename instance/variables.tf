variable "live_config_path" {
  description = "Path to NixOS configuration (set by Nix"
}

variable "ingress_ports" {
  type        = list(number)
  default     = []
  description = "list of ports to allow incoming, (set by Nix)"
}

variable "ingress_ports_udp" {
  type        = list(number)
  default     = []
  description = "list of UDP ports to allow incoming, (set by Nix)"
}

variable "ingress_from_to_ports" {
  type = list(object({
    from = number
    to   = number
  }))
  default     = []
  description = "List of port ranges to allow incoming traffic (set by Nix)."
}

variable "ebs_volume_id" {
  type        = string
  default     = ""
  description = "When ebs_volume_id is given the ec2 will have this ebs attached."
}

variable "ssh_id_file" {
  description = "Local (user) path to the ssh private key"
  type        = string
}

variable "hibernation" {
  description = "Enable hibernation (true). Instance type needs to support this functionality"
  type        = bool
  default     = false
}

#variable "ssh_privkey" {
#  description = "Generated private key"
#}

variable "root_initial_size" {
  description = "Initial size of the root filesystem in GB's"
  type        = number
  default     = 8
}

variable "volume_type" {
  description = "Type of volume defaults to gp3"
  type        = string
  default     = "gp3"
}

variable "subnet_id" {}
variable "vpc_id" {}

#variable "aws_ssm_profile" {
#  type        = string
#  default     = ""
#  description = "If EC2 not public this should is AWS_PROFILE with a direct ref. to the real AWS account."
#}

variable "iam_instance_profile" {}
variable "instance_type" {}
variable "name" {}
variable "availability_zone" {}

variable "ec2nix_ami_id" {}

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "infra_environment" {
  description = "infra enviroment"
  type        = string
}

variable "aws_account_id" {
  description = "aws account id"
  type        = string
}
