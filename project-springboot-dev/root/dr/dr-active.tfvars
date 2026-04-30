# ==============================
# DR Active ?íƒœ (?¥ì•  ë°œìƒ ??
# AWS ?´ì˜ ?íƒœ - SpringBoot EC2 ?€ ê°€??# ?¤í–‰: terraform apply -var-file="terraform.tfvars" -var-file="dr-active.tfvars"
# ==============================

# ? ê·œ ì¶”ê?
dr_mode        = true

# app_ami_id ??springboot_ami_id
springboot_ami_id        = "ami-016e4607515173ff6"
springboot_instance_type = "t3.micro"

# ASG ?€ ê°€??asg_min_size         = 2
asg_desired_capacity = 2
asg_max_size         = 4
