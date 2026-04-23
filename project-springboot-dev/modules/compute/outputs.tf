############################
# ALB Outputs
############################
output "alb_dns_name" {
  description = "ALB DNS 주소 (서비스 접속 URL, Route53 Alias 대상)"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "ALB Hosted Zone ID (Route53 Alias 연결용)"
  value       = aws_lb.app.zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.app.arn
}

output "alb_listener_arn" {
  description = "ALB HTTP Listener ARN (현재 forward 대상 TG 확인용)"
  value       = aws_lb_listener.http.arn
}

############################
# Target Group Outputs
############################
output "springboot_tg_arn" {
  description = "SpringBoot Target Group ARN (DR 시 트래픽 TG, Health 체크)"
  value       = aws_lb_target_group.springboot.arn
}

output "haproxy_tg_arn" {
  description = "HAProxy Target Group ARN (평상시 트래픽 TG, Health 체크)"
  value       = aws_lb_target_group.haproxy.arn
}

############################
# ASG / Launch Template Outputs
############################
output "launch_template_id" {
  description = "SpringBoot Launch Template ID (Rollback 시 default version 변경용)"
  value       = aws_launch_template.springboot.id
}

output "launch_template_latest_version" {
  description = "SpringBoot Launch Template 최신 버전 번호 (Rollback 계산 current-1)"
  value       = aws_launch_template.springboot.latest_version
}

output "springboot_asg_name" {
  description = "SpringBoot Auto Scaling Group 이름 (Instance Refresh, desired_capacity 변경용)"
  value       = aws_autoscaling_group.springboot.name
}

############################
# 관리 서버 Outputs
############################
output "haproxy_private_ip" {
  description = "HAProxy EC2 프라이빗 IP"
  value       = aws_instance.haproxy.private_ip
}

output "bastion_public_ip" {
  description = "Bastion Host 퍼블릭 IP (Private EC2 SSH 점프용)"
  value       = aws_instance.bastion.public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins 서버 프라이빗 IP (Bastion 경유 접속)"
  value       = aws_instance.jenkins.private_ip
}

output "db_ec2_private_ip" {
  description = "DB EC2 프라이빗 IP (Option B 격리 시 mysql -h 접속용, Failback 검증용)"
  value       = aws_instance.db_ec2.private_ip
}

output "db_ec2_instance_id" {
  description = "DB EC2 인스턴스 ID (describe-instances, 모니터링용)"
  value       = aws_instance.db_ec2.id
}
