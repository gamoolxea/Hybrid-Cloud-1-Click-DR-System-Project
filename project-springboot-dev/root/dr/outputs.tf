############################
# DR 운영용 Outputs (총 12개)
# Jenkins가 `terraform output -raw <name>` 으로 꺼내 AWS CLI/mysql에 주입
############################

############################
# DB EC2
############################
output "db_ec2_instance_id" {
  description = "DB EC2 인스턴스 ID (describe/모니터링용)"
  value       = module.compute.db_ec2_instance_id
}

output "db_ec2_private_ip" {
  description = "DB EC2 프라이빗 IP (Option B 격리 mysql 접속용)"
  value       = module.compute.db_ec2_private_ip
}

############################
# RDS
############################
output "rds_endpoint" {
  description = "RDS 엔드포인트 (mysql -h, Replication 제어)"
  value       = module.database.rds_endpoint
}

output "rds_identifier" {
  description = "RDS 식별자 (describe-db-instances, modify-db-instance)"
  value       = module.database.rds_identifier
}

############################
# ALB / Target Groups
############################
output "alb_dns_name" {
  description = "ALB DNS (curl 검증, Route53 alias 대상)"
  value       = module.compute.alb_dns_name
}

output "alb_listener_arn" {
  description = "ALB Listener ARN (현재 forward 대상 TG 확인)"
  value       = module.compute.alb_listener_arn
}

output "springboot_tg_arn" {
  description = "SpringBoot TG ARN (DR 모드 트래픽 대상, Health 체크)"
  value       = module.compute.springboot_tg_arn
}

output "haproxy_tg_arn" {
  description = "HAProxy TG ARN (평상시 트래픽 대상, Health 체크)"
  value       = module.compute.haproxy_tg_arn
}

############################
# ASG / Launch Template
############################
output "springboot_asg_name" {
  description = "SpringBoot ASG 이름 (Instance Refresh, desired_capacity 변경)"
  value       = module.compute.springboot_asg_name
}

output "launch_template_id" {
  description = "Launch Template ID (Rollback 시 default version 변경)"
  value       = module.compute.launch_template_id
}

output "launch_template_latest_version" {
  description = "Launch Template 최신 버전 (Rollback 계산: current-1)"
  value       = module.compute.launch_template_latest_version
}

############################
# 기타
############################
output "bastion_public_ip" {
  description = "Bastion 퍼블릭 IP (Private EC2 SSH 점프)"
  value       = module.compute.bastion_public_ip
}
