############################
# 공통
############################
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (poc / dev / prod)"
  type        = string
}

variable "common_tags" {
  description = "공통 태그 (root에서 주입)"
  type        = map(string)
}

############################
# 네트워크 입력
############################
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_a_id" {
  description = "Public Subnet AZ-a ID"
  type        = string
}

variable "public_subnet_c_id" {
  description = "Public Subnet AZ-c ID"
  type        = string
}

variable "app_subnet_a_id" {
  description = "App Subnet AZ-a ID"
  type        = string
}

variable "app_subnet_c_id" {
  description = "App Subnet AZ-c ID"
  type        = string
}

variable "jenkins_subnet_id" {
  description = "Jenkins Subnet ID"
  type        = string
}

############################
# 보안 그룹 입력
############################
variable "bastion_sg_id" {
  description = "Bastion Security Group ID"
  type        = string
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

# app_sg_id → springboot_sg_id
variable "springboot_sg_id" {
  description = "SpringBoot Security Group ID"
  type        = string
}

# 신규 추가
variable "haproxy_sg_id" {
  description = "HAProxy Security Group ID"
  type        = string
}

variable "jenkins_sg_id" {
  description = "Jenkins Security Group ID"
  type        = string
}

############################
# 키페어 / AMI
############################
variable "key_name" {
  description = "EC2 Key Pair 이름"
  type        = string
}

# app_ami_id → springboot_ami_id
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

variable "haproxy_ami_id" {
  description = "HAProxy AMI ID"
  type        = string
}

variable "bastion_ami_id" {
  description = "Bastion용 AMI ID"
  type        = string
}

variable "bastion_instance_type" {
  description = "Bastion EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "jenkins_ami_id" {
  description = "Jenkins용 AMI ID"
  type        = string
}

variable "jenkins_instance_type" {
  description = "Jenkins EC2 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

############################
# ASG 설정
############################
variable "asg_desired_capacity" {
  description = "ASG 목표 인스턴스 수"
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "ASG 최소 인스턴스 수"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG 최대 인스턴스 수"
  type        = number
  default     = 4
}

############################
# 신규 추가: DR 모드
############################
variable "dr_mode" {
  description = "DR 활성화 여부 (true = DR Active, false = Pilot Light)"
  type        = bool
  default     = false
}

variable "haproxy_subnet_id" {
  description = "HAProxy Subnet ID"
  type        = string
}

variable "tailscale_auth_key" {
  description = "Tailscale Auth Key"
  type        = string
  sensitive   = true
}

variable "db_ec2_ami_id" {
  description = "DB EC2 AMI ID"
  type        = string
}

variable "db_ec2_subnet_id" {
  description = "DB EC2 Subnet ID"
  type        = string
}

variable "db_ec2_sg_id" {
  description = "DB EC2 Security Group ID"
  type        = string
}
