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
