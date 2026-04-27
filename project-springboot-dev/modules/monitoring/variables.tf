############################
# Monitoring 모듈 변수
############################

variable "project_name" {
  description = "프로젝트 이름 (리소스 접두사)"
  type        = string
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS 리전 (metric 조회 시 명시용)"
  type        = string
  default     = "ap-northeast-2"
}

############################
# SNS 구독
############################
variable "alert_email" {
  description = "Disaster 알람을 받을 관리자 이메일 주소"
  type        = string
}

############################
# CloudWatch 메트릭 namespace
# (온프렘 Agent 가 pushes 하는 namespace 와 반드시 일치해야 함)
############################
variable "metric_namespace" {
  description = "CloudWatch custom metric namespace (Ansible role 의 cloudwatch_namespace 와 일치해야 함)"
  type        = string
  default     = "HybridDR/OnPrem"
}

############################
# 온프렘 호스트명 (alarm dimension 값)
# Ansible inventory_hostname 과 동일해야 함
############################
variable "onprem_webwas_hostname" {
  description = "WEBWAS Ansible inventory hostname (alarm dimension)"
  type        = string
  default     = "on-prem-webwas"
}

variable "onprem_db_hostname" {
  description = "DB Ansible inventory hostname (alarm dimension)"
  type        = string
  default     = "on-prem-db"
}

variable "onprem_haproxy_hostname" {
  description = "HAProxy Ansible inventory hostname (alarm dimension)"
  type        = string
  default     = "on-prem-haproxy"
}

############################
# 알람 임계값
############################
variable "heartbeat_missing_minutes" {
  description = "메트릭 미수신 몇 분 후 알람 (VM 사망 감지)"
  type        = number
  default     = 2
}

variable "cpu_threshold_percent" {
  description = "CPU 사용률 경고 임계값 (%)"
  type        = number
  default     = 80
}

variable "memory_threshold_percent" {
  description = "Memory 사용률 경고 임계값 (%)"
  type        = number
  default     = 85
}

############################
# AWS 측 알람용 ARN suffix 및 식별자
############################
variable "alb_arn_suffix" {
  description = "ALB ARN suffix (CloudWatch LoadBalancer dimension 형식)"
  type        = string
}

variable "haproxy_tg_arn_suffix" {
  description = "HAProxy TG ARN suffix"
  type        = string
}

variable "springboot_tg_arn_suffix" {
  description = "SpringBoot TG ARN suffix"
  type        = string
}

variable "rds_identifier" {
  description = "RDS DB instance identifier (DBInstanceIdentifier dimension)"
  type        = string
}

############################
# AWS 측 알람 임계값
############################
variable "rds_cpu_threshold" {
  description = "RDS CPU 경고 임계값 (%)"
  type        = number
  default     = 90
}

variable "rds_connections_threshold" {
  description = "RDS 동시 연결 수 경고 임계값"
  type        = number
  default     = 150
}

variable "rds_storage_low_bytes" {
  description = "RDS 남은 스토리지 경고 임계값 (바이트, 기본 2GB)"
  type        = number
  default     = 2147483648  # 2 * 1024^3
}

variable "alb_5xx_threshold" {
  description = "ALB target 5xx 에러 1분 내 임계값 (건)"
  type        = number
  default     = 5
}

variable "rds_replica_lag_threshold" {
  description = "RDS cascade replica lag 경고 임계값 (초). cascade 가 onprem master → DB EC2 → RDS 로 흐를 때 RDS 쪽에서 본 lag."
  type        = number
  default     = 30
}
