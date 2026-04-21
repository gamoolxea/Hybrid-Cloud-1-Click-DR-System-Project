############################
# ALB Outputs
############################
output "alb_dns_name" {
  description = "ALB DNS 주소 (서비스 접속 URL)"
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

output "springboot_target_group_arn" {
  description = "SpringBoot Target Group ARN"
  value       = aws_lb_target_group.springboot.arn
}

output "haproxy_target_group_arn" {
  description = "HAProxy Target Group ARN"
  value       = aws_lb_target_group.haproxy.arn
}

############################
# ASG / Launch Template Outputs
############################
output "launch_template_id" {
  description = "SpringBoot Launch Template ID"
  value       = aws_launch_template.springboot.id
}

output "autoscaling_group_name" {
  description = "SpringBoot Auto Scaling Group 이름"
  value       = aws_autoscaling_group.springboot.name
}

############################
# 관리 서버 Outputs
############################
# 신규 추가
output "haproxy_private_ip" {
  description = "HAProxy EC2 프라이빗 IP"
  value       = aws_instance.haproxy.private_ip
}

output "bastion_public_ip" {
  description = "Bastion Host 퍼블릭 IP (SSH 접속용)"
  value       = aws_instance.bastion.public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins 서버 프라이빗 IP (Bastion 경유 접속)"
  value       = aws_instance.jenkins.private_ip
}

output "db_ec2_private_ip" {
  description = "DB EC2 프라이빗 IP"
  value       = aws_instance.db_ec2.private_ip
}

output "db_ec2_instance_id" {
  description = "DB EC2 인스턴스 ID (Jenkins Stop/Start 참조용)"
  value       = aws_instance.db_ec2.id
}
