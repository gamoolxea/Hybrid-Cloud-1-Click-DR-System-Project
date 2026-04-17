############################
# Provider & Terraform 설정
############################
terraform {
  required_version = "= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

############################
# 공통 태그 (모든 모듈에 주입)
############################
locals {
  common_tags = {
    Project     = "hybrid-dr"
    Environment = var.environment
    ManagedBy   = "terraform"
    DRMode      = var.dr_mode ? "active" : "pilot-light"
  }
}

############################
# Amazon Linux 2023 최신 AMI (Bastion / Jenkins용)
############################
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Module: Networking
############################
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  common_tags          = local.common_tags
  az_a                 = var.az_a
  az_c                 = var.az_c
  vpc_cidr             = var.vpc_cidr
  public_subnet_a_cidr = var.public_subnet_a_cidr
  public_subnet_c_cidr = var.public_subnet_c_cidr
  app_subnet_a_cidr    = var.app_subnet_a_cidr
  app_subnet_c_cidr    = var.app_subnet_c_cidr
  db_subnet_a_cidr     = var.db_subnet_a_cidr
  db_subnet_c_cidr     = var.db_subnet_c_cidr
  jenkins_subnet_cidr  = var.jenkins_subnet_cidr
  my_ip_cidr           = var.my_ip_cidr
  haproxy_subnet_cidr  = var.haproxy_subnet_cidr
  db_ec2_subnet_cidr   = var.db_ec2_subnet_cidr
}

############################
# Module: Compute
############################
module "compute" {
  source = "../../modules/compute"

  project_name             = var.project_name
  environment              = var.environment
  common_tags              = local.common_tags
  vpc_id                   = module.networking.vpc_id
  public_subnet_a_id       = module.networking.public_subnet_a_id
  public_subnet_c_id       = module.networking.public_subnet_c_id
  app_subnet_a_id          = module.networking.app_subnet_a_id
  app_subnet_c_id          = module.networking.app_subnet_c_id
  jenkins_subnet_id        = module.networking.jenkins_subnet_id
  bastion_sg_id            = module.networking.bastion_sg_id
  alb_sg_id                = module.networking.alb_sg_id

  # app_sg_id → springboot_sg_id
  springboot_sg_id         = module.networking.springboot_sg_id

  # 신규 추가
  haproxy_sg_id            = module.networking.haproxy_sg_id
  haproxy_subnet_id        = module.networking.haproxy_subnet_id

  jenkins_sg_id            = module.networking.jenkins_sg_id
  key_name                 = var.key_name

  # app_ami_id → springboot_ami_id
  springboot_ami_id        = var.springboot_ami_id
  springboot_instance_type = var.springboot_instance_type

  haproxy_ami_id           = data.aws_ami.amazon_linux_2023.id
  tailscale_auth_key       = var.tailscale_auth_key

  bastion_ami_id           = data.aws_ami.amazon_linux_2023.id
  bastion_instance_type    = var.bastion_instance_type
  jenkins_ami_id           = data.aws_ami.amazon_linux_2023.id
  jenkins_instance_type    = var.jenkins_instance_type
  asg_desired_capacity     = var.asg_desired_capacity
  asg_min_size             = var.asg_min_size
  asg_max_size             = var.asg_max_size

  db_ec2_ami_id            = data.aws_ami.amazon_linux_2023.id
  db_ec2_subnet_id         = module.networking.db_ec2_subnet_id
  db_ec2_sg_id             = module.networking.db_ec2_sg_id

  # 신규 추가
  dr_mode                  = var.dr_mode
}

############################
# Module: Database
############################
module "database" {
  source = "../../modules/database"

  project_name      = var.project_name
  environment       = var.environment
  common_tags       = local.common_tags
  db_subnet_a_id    = module.networking.db_subnet_a_id
  db_subnet_c_id    = module.networking.db_subnet_c_id
  rds_sg_id         = module.networking.rds_sg_id
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
}

############################
# Route53
############################
data "aws_route53_zone" "main" {
  name         = "llddww1004.store"
  private_zone = false
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "llddww1004.store"
  type    = "A"

  alias {
    name                   = module.compute.alb_dns_name
    zone_id                = module.compute.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.llddww1004.store"
  type    = "A"

  alias {
    name                   = module.compute.alb_dns_name
    zone_id                = module.compute.alb_zone_id
    evaluate_target_health = true
  }
}
