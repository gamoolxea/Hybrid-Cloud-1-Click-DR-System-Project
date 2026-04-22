############################
# VPC
############################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

############################
# Internet Gateway
############################
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

############################
# Public Subnets (ALB, NAT, Bastion)
############################
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-a"
    Tier = "public"
  })
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_c_cidr
  availability_zone       = var.az_c
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-c"
    Tier = "public"
  })
}

############################
# Private App Subnets (EC2)
############################
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-a"
    Tier = "app"
  })
}

resource "aws_subnet" "app_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_c_cidr
  availability_zone = var.az_c

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-c"
    Tier = "app"
  })
}

############################
# Private DB Subnets (RDS MySQL)
############################
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_a_cidr
  availability_zone = var.az_a

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-a"
    Tier = "db"
  })
}

resource "aws_subnet" "db_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_c_cidr
  availability_zone = var.az_c

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-c"
    Tier = "db"
  })
}

############################
# Private Jenkins Subnet (NAT 있음)
############################
resource "aws_subnet" "jenkins" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.jenkins_subnet_cidr
  availability_zone = var.az_a

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-jenkins"
    Tier = "jenkins"
  })
}

############################
# NAT Gateway (Jenkins 전용)
############################
resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat"
  })
}

############################
# Public Route Table
############################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

############################
# App Route Table (인터넷 경로 없음)
############################
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-app-rt"
  })
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table_association" "app_c" {
  subnet_id      = aws_subnet.app_c.id
  route_table_id = aws_route_table.app.id
}

############################
# DB Route Table (인터넷 경로 없음)
############################
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-rt"
  })
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_c" {
  subnet_id      = aws_subnet.db_c.id
  route_table_id = aws_route_table.db.id
}

############################
# Jenkins Route Table (NAT 경유)
############################
resource "aws_route_table" "jenkins" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-jenkins-rt"
  })
}

resource "aws_route_table_association" "jenkins" {
  subnet_id      = aws_subnet.jenkins.id
  route_table_id = aws_route_table.jenkins.id
}

############################
# Bastion SG
############################
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion Host Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "bastion-sg" })
}

############################
# ALB SG
############################
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Application Load Balancer Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "alb-sg" })
}

############################
# ① SpringBoot SG (app → springboot, 80 → 8080)
############################
resource "aws_security_group" "springboot" {
  name        = "${var.project_name}-springboot-sg"
  description = "Spring Boot Server Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Spring Boot from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "springboot-sg" })
}

############################
# ③ HAProxy SG (신규 추가)
############################
resource "aws_security_group" "haproxy" {
  name        = "${var.project_name}-haproxy-sg"
  description = "HAProxy + Tailscale Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "Tailscale UDP"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "haproxy-sg" })
}

############################
# ② RDS SG (app.id → springboot.id)
############################
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS MySQL Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from springboot"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.springboot.id]
  }

  ingress {
    description     = "MySQL from db_ec2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.db_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "rds-sg" })
}

############################
# Jenkins SG
############################
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Jenkins CI/CD Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Jenkins UI from bastion"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "jenkins-sg" })
}

############################
# HAProxy 전용 서브넷
############################
resource "aws_subnet" "haproxy" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.haproxy_subnet_cidr
  availability_zone = var.az_a

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-haproxy"
    Tier = "haproxy"
  })
}

############################
# HAProxy 전용 NAT Gateway EIP
############################
resource "aws_eip" "haproxy_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-haproxy-nat-eip"
  })
}

############################
# HAProxy 전용 NAT Gateway
############################
resource "aws_nat_gateway" "haproxy" {
  allocation_id = aws_eip.haproxy_nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-haproxy-nat"
  })
}

############################
# HAProxy Route Table
############################
resource "aws_route_table" "haproxy" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.haproxy.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-haproxy-rt"
  })
}

resource "aws_route_table_association" "haproxy" {
  subnet_id      = aws_subnet.haproxy.id
  route_table_id = aws_route_table.haproxy.id
}

############################
# DB EC2 전용 서브넷
############################
resource "aws_subnet" "db_ec2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_ec2_subnet_cidr
  availability_zone = var.az_a

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-ec2"
    Tier = "db-ec2"
  })
}

############################
# DB EC2 전용 NAT EIP
############################
resource "aws_eip" "db_ec2_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-ec2-nat-eip"
  })
}

############################
# DB EC2 전용 NAT Gateway
############################
resource "aws_nat_gateway" "db_ec2" {
  allocation_id = aws_eip.db_ec2_nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-ec2-nat"
  })
}

############################
# DB EC2 Route Table
############################
resource "aws_route_table" "db_ec2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.db_ec2.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-ec2-rt"
  })
}

resource "aws_route_table_association" "db_ec2" {
  subnet_id      = aws_subnet.db_ec2.id
  route_table_id = aws_route_table.db_ec2.id
}

############################
# DB EC2 보안그룹
############################
resource "aws_security_group" "db_ec2" {
  name        = "${var.project_name}-db-ec2-sg"
  description = "DB EC2 Security Group (MySQL + Tailscale)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description = "MySQL from DB subnet"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.31.0/24", "10.0.32.0/24"]
  }

  ingress {
    description = "Tailscale UDP"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, { Name = "db-ec2-sg" })
}
