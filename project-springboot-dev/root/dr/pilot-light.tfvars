# ==============================
# Pilot Light ?íƒœ (?‰ìƒ??
# AWS ?€ê¸??íƒœ - SpringBoot EC2 ?†ìŒ, HAProxyë§??€ê¸?# ?¤í–‰: terraform apply -var-file="terraform.tfvars" -var-file="pilot-light.tfvars"
# ==============================

# ? ê·œ ì¶”ê?
dr_mode        = false

# app_ami_id ??springboot_ami_id
springboot_ami_id        = "ami-016e4607515173ff6"
springboot_instance_type = "t3.micro"

# ASG 0?¼ë¡œ ?¤ì • (SpringBoot EC2 ?†ìŒ)
asg_min_size         = 0
asg_desired_capacity = 0
asg_max_size         = 4
