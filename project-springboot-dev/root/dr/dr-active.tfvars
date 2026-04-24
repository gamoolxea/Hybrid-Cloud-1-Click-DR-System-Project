# ==============================
# DR Active 상태 (장애 발생 시)
# AWS 운영 상태 - SpringBoot EC2 풀 가동
# 실행: terraform apply -var-file="terraform.tfvars" -var-file="dr-active.tfvars"
# ==============================

# 신규 추가
dr_mode        = true

# app_ami_id → springboot_ami_id
springboot_ami_id        = "ami-0c8697730316c257b"
springboot_instance_type = "t3.micro"

# ASG 풀 가동
asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4
