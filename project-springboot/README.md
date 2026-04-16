# 🌐 Hybrid Cloud 1-Click DR 자동화 구축 (Spring Boot)

> Terraform + Tailscale을 활용한 온프렘-AWS 무중단 장애 전환 아키텍처

## 📌 프로젝트 개요

온프레미스(VMware Rocky Linux 9) 장애 발생 시 AWS로 서비스를 자동 전환하고 복구 후 다시 온프레미스로 복귀하는 하이브리드 클라우드 DR 구조를 구현했습니다.

## 🏗️ 전체 아키텍처

### 평상시 (Pilot Light)
    클라이언트
        ↓
    Route53 (llddww1004.store)
        ↓
    AWS ALB
        ↓ dr_mode = false
    AWS HAProxy EC2 (Tailscale 연결)
        ↓ Tailscale 터널
    온프렘 HAProxy (100.79.94.82)
        ↓
    온프렘 Nginx (192.168.20.12:80)

### DR 발동 시
    terraform apply -var-file=dr-active.tfvars
        ↓
    클라이언트 → Route53 → AWS ALB
        ↓ dr_mode = true
    AWS Spring Boot 서버 (ASG)
        ↓
    AWS RDS (MySQL)

## 🗂️ 프로젝트 구조

    project-springboot/
    ├── modules/
    │   ├── compute/       # ALB, ASG, HAProxy, Bastion, Jenkins
    │   ├── networking/    # VPC, Subnet, NAT, SG, Route Table
    │   └── database/      # RDS MySQL
    └── root/
        └── dr/
            ├── main.tf
            ├── variables.tf
            ├── outputs.tf
            ├── backend.tf
            ├── pilot-light.tfvars
            └── dr-active.tfvars

## 🔧 핵심 기술 스택

| 분류 | 기술 |
|------|------|
| IaC | Terraform >= 1.5.0 |
| Cloud | AWS (ap-northeast-2) |
| VPN | Tailscale (WireGuard 기반) |
| Load Balancer | AWS ALB + HAProxy |
| OS (온프렘) | Rocky Linux 9 |
| OS (AWS) | Amazon Linux 2023 |
| App 서버 | Spring Boot (8080) |
| Database | RDS MySQL 8.0 |
| State 관리 | S3 + DynamoDB |

## 🌐 AWS 인프라 구성

| 서브넷 | CIDR | 역할 |
|--------|------|------|
| Public | 10.0.1.0/24, 10.0.2.0/24 | ALB, Bastion, NAT |
| App | 10.0.11.0/24, 10.0.12.0/24 | Spring Boot 서버 (ASG) |
| DB | 10.0.31.0/24, 10.0.32.0/24 | RDS MySQL |
| Jenkins | 10.0.41.0/24 | Jenkins CI/CD |
| HAProxy | 10.0.51.0/24 | HAProxy + Tailscale |

## 📊 project-app vs project-springboot 비교

| 항목 | project-app | project-springboot |
|------|-------------|-------------------|
| 앱 서버 | Nginx + Tomcat | Spring Boot |
| 포트 | 80 | 8080 |
| 헬스체크 | / | /actuator/health |
| HAProxy | ✅ | ✅ |
| Tailscale | ✅ | ✅ |
| DR 전환 | ✅ | ✅ |

## 🚀 실행 방법

    # terraform.tfvars 생성 (직접 작성 필요)
    key_name           = "your-key-name"
    my_ip_cidr         = "your-ip/32"
    db_password        = "your-db-password"
    springboot_ami_id  = "your-ami-id"
    haproxy_ami_id     = "your-ami-id"
    tailscale_auth_key = "your-tailscale-auth-key"

    # 초기화
    terraform init

    # 평상시 (온프렘 서비스)
    terraform apply -var-file=terraform.tfvars -var-file=pilot-light.tfvars

    # DR 발동 (AWS 서비스)
    terraform apply -var-file=terraform.tfvars -var-file=dr-active.tfvars

    # 복구 후 온프렘 복귀
    terraform apply -var-file=terraform.tfvars -var-file=pilot-light.tfvars

## 🔁 DR 전환 원리

    default_action {
      target_group_arn = var.dr_mode ?
        aws_lb_target_group.springboot.arn :   # DR 시 → AWS Spring Boot 서버
        aws_lb_target_group.haproxy.arn        # 평상시 → 온프렘 연결
    }

## 🛠️ 트러블슈팅 주요 사례

| 문제 | 원인 | 해결 |
|------|------|------|
| State 충돌 | apply 중단으로 State 불일치 | terraform import |
| DynamoDB Lock | 비정상 종료로 Lock 잔재 | dynamodb delete-item |
| Route53 중복 | 기존 레코드 존재 | terraform import |
| RDS 프리티어 오류 | backup_retention, multi_az 제한 | 값 수정 |
| HAProxy NAT 없음 | app 서브넷 NAT 미설치 | HAProxy 전용 서브넷 + NAT 생성 |
| user_data 실패 | Heredoc 중첩 오류 | base64encode 방식으로 변경 |

## 📅 향후 계획

    완료:
    - AWS 3티어 인프라 구축
    - HAProxy + Tailscale 하이브리드 연결
    - DR 전환 자동화 (dr_mode 변수 기반)
    - Remote State 관리 (S3 + DynamoDB)

    진행 예정:
    - Jenkins CI/CD 파이프라인 연결
    - MySQL Replication (온프렘 → RDS 동기화)
    - CloudWatch 모니터링 + SNS 알림
    - HAProxy 골든 AMI 생성
    - Failback 자동화
