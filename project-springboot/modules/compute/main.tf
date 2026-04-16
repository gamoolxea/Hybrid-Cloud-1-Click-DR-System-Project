############################
# ALB (Internet-facing)
############################
resource "aws_lb" "app" {
  name               = "${var.project_name}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.public_subnet_a_id, var.public_subnet_c_id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-alb"
  })
}

############################
# ③ SpringBoot Target Group (port 80 → 8080, 헬스체크 수정)
############################
resource "aws_lb_target_group" "springboot" {
  name     = "${var.project_name}-springboot-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/actuator/health"
    port = "8080"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-springboot-tg"
  })
}

############################
# ⑤ HAProxy Target Group (신규 추가)
############################
resource "aws_lb_target_group" "haproxy" {
  name     = "${var.project_name}-haproxy-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
    port = "80"
  }
}

############################
# ④ ALB Listener (dr_mode에 따라 타겟 그룹 전환)
############################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.dr_mode ? aws_lb_target_group.springboot.arn : aws_lb_target_group.haproxy.arn
  }
}

############################
# ① SpringBoot Launch Template (app → springboot)
############################
resource "aws_launch_template" "springboot" {
  name_prefix   = "lt-${var.project_name}-springboot-"
  image_id      = var.springboot_ami_id
  instance_type = var.springboot_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.springboot_sg_id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.common_tags, {
      Name = "${var.project_name}-springboot"
      Role = "springboot-server"
    })
  }

  update_default_version = true

  tags = merge(var.common_tags, {
    Name = "lt-${var.project_name}-springboot"
  })
}

############################
# ② SpringBoot Auto Scaling Group (app → springboot)
############################
resource "aws_autoscaling_group" "springboot" {
  name                      = "asg-${var.project_name}-springboot"
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  vpc_zone_identifier       = [var.app_subnet_a_id, var.app_subnet_c_id]
  target_group_arns         = [aws_lb_target_group.springboot.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.springboot.id
    version = "$Default"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-springboot-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "hybrid-dr"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################
# HAProxy Server
############################
resource "aws_instance" "haproxy" {
  ami                    = var.haproxy_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.haproxy_subnet_id
  vpc_security_group_ids = [var.haproxy_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y haproxy
curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
tailscale up --authkey=${var.tailscale_auth_key} --accept-routes
sleep 15
cat > /etc/haproxy/haproxy.cfg <<-HAPROXY
global
    log /dev/log local0
    maxconn 4096
    daemon
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
frontend http_front
    bind *:80
    default_backend onprem_back
backend onprem_back
    balance roundrobin
    option  httpchk GET /
    server  onprem 100.79.94.82:80 check
HAPROXY
systemctl enable haproxy
systemctl restart haproxy
EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-haproxy"
    Role = "haproxy-proxy"
  })
}

resource "aws_lb_target_group_attachment" "haproxy" {
  target_group_arn = aws_lb_target_group.haproxy.arn
  target_id        = aws_instance.haproxy.id
  port             = 80
}

############################
# Bastion Host
############################
resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_a_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  })
}

############################
# Jenkins Server
############################
resource "aws_instance" "jenkins" {
  ami                         = var.jenkins_ami_id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = var.jenkins_subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.jenkins_sg_id]
  associate_public_ip_address = false

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-jenkins"
    Role = "jenkins"
  })
}

############################
# DB EC2 (MySQL + Tailscale)
############################
resource "aws_instance" "db_ec2" {
  ami                    = var.db_ec2_ami_id
  instance_type          = "t3.micro"
  subnet_id              = var.db_ec2_subnet_id
  vpc_security_group_ids = [var.db_ec2_sg_id]
  key_name               = var.key_name

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y mysql
curl -fsSL https://tailscale.com/install.sh | sh
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
tailscale up --authkey=${var.tailscale_auth_key} --accept-routes
EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-ec2"
    Role = "db-replication"
  })
}
