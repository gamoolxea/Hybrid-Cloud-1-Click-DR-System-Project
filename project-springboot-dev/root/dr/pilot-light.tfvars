# ==============================
# Pilot Light 상태 (평상시)
# AWS 대기 상태 - SpringBoot EC2 없음, HAProxy만 대기
# 실행: terraform apply -var-file="terraform.tfvars" -var-file="pilot-light.tfvars"
# ==============================

# 신규 추가
dr_mode        = false

# app_ami_id → springboot_ami_id
springboot_ami_id        = "ami-0ecd90ec6999929bf"
springboot_instance_type = "t3.micro"

# ASG 0으로 설정 (SpringBoot EC2 없음)
asg_min_size         = 0
asg_desired_capacity = 0
asg_max_size         = 4
