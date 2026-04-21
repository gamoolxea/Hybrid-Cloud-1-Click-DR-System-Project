############################
# 신규 추가: DR 모드 설정
############################
variable "dr_mode" {
  description = "DR 활성화 여부 (true = DR Active, false = Pilot Light)"
  type        = bool
  default     = false
}

############################
# 공통 설정
############################
variable "aws_region" {
  description = "AWS 배포 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 네이밍에 사용)"
  type        = string
  default     = "project"
}

variable "environment" {
  description = "배포 환경 (poc / dev / prod)"
  type        = string
  default     = "poc"
}

############################
# 접근 제어
############################
variable "my_ip_cidr" {
  description = "Bastion SSH 허용할 내 공인 IP (예: 1.2.3.4/32)"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair 이름"
  type        = string
}

############################
# 가용영역
############################
variable "az_a" {
  description = "가용영역 A"
  type        = string
  default     = "ap-northeast-2a"
}

variable "az_c" {
  description = "가용영역 C"
  type        = string
  default     = "ap-northeast-2c"
}

############################
# 네트워크 CIDR
############################
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_c_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "app_subnet_a_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

variable "app_subnet_c_cidr" {
  type    = string
  default = "10.0.12.0/24"
}

variable "db_subnet_a_cidr" {
  type    = string
  default = "10.0.31.0/24"
}

variable "db_subnet_c_cidr" {
  type    = string
  default = "10.0.32.0/24"
}

variable "jenkins_subnet_cidr" {
  type    = string
  default = "10.0.41.0/24"
}

############################
# app_ami_id → springboot_ami_id
############################
variable "springboot_ami_id" {
  description = "SpringBoot 골든 AMI ID"
  type        = string
}

# app_instance_type → springboot_instance_type
variable "springboot_instance_type" {
  description = "SpringBoot EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 4
}

############################
# Bastion / Jenkins EC2
############################
variable "bastion_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "jenkins_instance_type" {
  type    = string
  default = "t3.micro"
}

############################
# RDS MySQL
############################
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "haproxy_subnet_cidr" {
  description = "HAProxy Subnet CIDR"
  type        = string
  default     = "10.0.51.0/24"
}

variable "tailscale_auth_key" {
  description = "Tailscale Auth Key"
  type        = string
  sensitive   = true
}

variable "db_ec2_subnet_cidr" {
  description = "DB EC2 Subnet CIDR"
  type        = string
  default     = "10.0.61.0/24"
}

variable "onprem_db_ip" {
  description = "온프렘 DB Tailscale IP"
  type        = string
}

variable "db_ec2_private_ip" {
  description = "DB EC2 고정 프라이빗 IP"
  type        = string
}

