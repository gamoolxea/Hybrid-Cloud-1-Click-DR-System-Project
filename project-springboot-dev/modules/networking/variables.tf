variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "az_a" {
  type = string
}

variable "az_c" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_a_cidr" {
  type = string
}

variable "public_subnet_c_cidr" {
  type = string
}

variable "app_subnet_a_cidr" {
  type = string
}

variable "app_subnet_c_cidr" {
  type = string
}

variable "db_subnet_a_cidr" {
  type = string
}

variable "db_subnet_c_cidr" {
  type = string
}

variable "jenkins_subnet_cidr" {
  type = string
}

variable "my_ip_cidr" {
  type = string
}

variable "haproxy_subnet_cidr" {
  description = "HAProxy Subnet CIDR"
  type        = string
  default     = "10.0.51.0/24"
}

variable "db_ec2_subnet_cidr" {
  description = "DB EC2 Subnet CIDR"
  type        = string
  default     = "10.0.61.0/24"
}
