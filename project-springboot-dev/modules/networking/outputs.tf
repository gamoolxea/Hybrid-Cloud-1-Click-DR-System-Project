############################
# VPC / Subnet Outputs
############################
output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "Public Subnet AZ-a ID"
  value       = aws_subnet.public_a.id
}

output "public_subnet_c_id" {
  description = "Public Subnet AZ-c ID"
  value       = aws_subnet.public_c.id
}

output "app_subnet_a_id" {
  description = "App Subnet AZ-a ID"
  value       = aws_subnet.app_a.id
}

output "app_subnet_c_id" {
  description = "App Subnet AZ-c ID"
  value       = aws_subnet.app_c.id
}

output "db_subnet_a_id" {
  description = "DB Subnet AZ-a ID"
  value       = aws_subnet.db_a.id
}

output "db_subnet_c_id" {
  description = "DB Subnet AZ-c ID"
  value       = aws_subnet.db_c.id
}

output "jenkins_subnet_id" {
  description = "Jenkins Subnet ID"
  value       = aws_subnet.jenkins.id
}

output "nat_eip_public_ip" {
  description = "NAT Gateway 퍼블릭 IP"
  value       = aws_eip.nat.public_ip
}

############################
# Security Group Outputs
############################
output "bastion_sg_id" {
  description = "Bastion Security Group ID"
  value       = aws_security_group.bastion.id
}

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

# app_sg_id → springboot_sg_id 로 변경
output "springboot_sg_id" {
  description = "Spring Boot Security Group ID"
  value       = aws_security_group.springboot.id
}

# 신규 추가
output "haproxy_sg_id" {
  description = "HAProxy Security Group ID"
  value       = aws_security_group.haproxy.id
}

output "rds_sg_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "jenkins_sg_id" {
  description = "Jenkins Security Group ID"
  value       = aws_security_group.jenkins.id
}

output "haproxy_subnet_id" {
  description = "HAProxy Subnet ID"
  value       = aws_subnet.haproxy.id
}

output "db_ec2_subnet_id" {
  description = "DB EC2 Subnet ID"
  value       = aws_subnet.db_ec2.id
}

output "db_ec2_sg_id" {
  description = "DB EC2 Security Group ID"
  value       = aws_security_group.db_ec2.id
}
