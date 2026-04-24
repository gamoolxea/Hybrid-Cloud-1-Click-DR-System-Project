############################
# SNS Topic: DR Alerts
############################
# 모든 온프렘 disaster 알람이 모이는 공통 topic.
# Email + (선택) Slack 은 여기 subscribe.
resource "aws_sns_topic" "dr_alerts" {
  name = "${var.project_name}-dr-alerts"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-dr-alerts"
    Purpose = "disaster-detection"
  })
}

############################
# SNS Subscription: 관리자 이메일
############################
# AWS 에서 Subscribe 요청 → 받는 이메일로 confirmation 링크 발송됨
# (반드시 수동으로 confirmation 클릭 후 active 됨)
resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

############################
# CloudWatch Alarm 1: WEBWAS Heartbeat Loss
############################
# onprem CloudWatch Agent가 메트릭을 push 못 하면 = VM 자체 사망 또는 네트워크 단절.
# → "Disaster" 정의의 핵심 신호.
#
# 동작 원리:
#   - 2분 이내 데이터 포인트가 없으면 "missing" 상태
#   - treat_missing_data = "breaching" → missing 을 "알람 발화 조건"으로 간주
#   - datapoints_to_alarm = 2, evaluation_periods = 2 → 2분 연속 miss 시 ALARM
resource "aws_cloudwatch_metric_alarm" "webwas_heartbeat_loss" {
  alarm_name          = "${var.project_name}-webwas-heartbeat-loss"
  alarm_description   = "[DISASTER] WEBWAS 메트릭 미수신 2분 — VM 사망 또는 네트워크 단절"
  namespace           = var.metric_namespace
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = var.heartbeat_missing_minutes
  datapoints_to_alarm = var.heartbeat_missing_minutes
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    hostname = var.onprem_webwas_hostname
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "critical"
    Role     = "webwas"
  })
}

############################
# CloudWatch Alarm 2: Spring Boot 프로세스 다운
############################
# procstat pid_count = 0 → 프로세스 자체 죽음 = 앱 레벨 disaster.
# VM 은 살아있지만 앱만 죽은 경우.
resource "aws_cloudwatch_metric_alarm" "webwas_springboot_down" {
  alarm_name          = "${var.project_name}-webwas-springboot-down"
  alarm_description   = "[DISASTER] Spring Boot 프로세스 1분 이상 down — 앱 레벨 장애"
  namespace           = var.metric_namespace
  metric_name         = "procstat_lookup_pid_count"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    hostname = var.onprem_webwas_hostname
    pattern  = "logistics-system.jar"
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "critical"
    Role     = "webwas"
  })
}

############################
# CloudWatch Alarm 3: DB Heartbeat Loss
############################
# DB VM 사망 감지. Spring Boot 는 살아있어도 DB 죽으면 서비스 실패 전조.
resource "aws_cloudwatch_metric_alarm" "db_heartbeat_loss" {
  alarm_name          = "${var.project_name}-db-heartbeat-loss"
  alarm_description   = "[DISASTER] DB 메트릭 미수신 2분 — DB VM 사망"
  namespace           = var.metric_namespace
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = var.heartbeat_missing_minutes
  datapoints_to_alarm = var.heartbeat_missing_minutes
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    hostname = var.onprem_db_hostname
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "critical"
    Role     = "db"
  })
}

############################
# CloudWatch Dashboard: 풍부한 시각화
############################
# 실시간 대시보드로 CPU/Memory/Disk 를 한눈에.
# Alarm 으로 연결 안 된 메트릭도 여기서 시각적으로 볼 수 있음 (발표용).
resource "aws_cloudwatch_dashboard" "hybrid_dr" {
  dashboard_name = "${var.project_name}-hybrid-dr"

  dashboard_body = jsonencode({
    widgets = [
      # ===== Row 1: CPU =====
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Onprem VM CPU Usage (User %)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            [var.metric_namespace, "cpu_usage_user", "hostname", var.onprem_webwas_hostname, "cpu", "cpu-total"],
            [var.metric_namespace, "cpu_usage_user", "hostname", var.onprem_db_hostname, "cpu", "cpu-total"],
            [var.metric_namespace, "cpu_usage_user", "hostname", var.onprem_haproxy_hostname, "cpu", "cpu-total"]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      # ===== Row 1 right: Memory =====
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Onprem VM Memory Used %"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            [var.metric_namespace, "mem_used_percent", "hostname", var.onprem_webwas_hostname],
            [var.metric_namespace, "mem_used_percent", "hostname", var.onprem_db_hostname],
            [var.metric_namespace, "mem_used_percent", "hostname", var.onprem_haproxy_hostname]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      # ===== Row 2: Disk + Spring Boot PID =====
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Onprem VM Disk Used % (/)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            [var.metric_namespace, "disk_used_percent", "hostname", var.onprem_webwas_hostname, "path", "/"],
            [var.metric_namespace, "disk_used_percent", "hostname", var.onprem_db_hostname, "path", "/"],
            [var.metric_namespace, "disk_used_percent", "hostname", var.onprem_haproxy_hostname, "path", "/"]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "WEBWAS Spring Boot Process Count (0 = 사망)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            [var.metric_namespace, "procstat_lookup_pid_count", "hostname", var.onprem_webwas_hostname, "pattern", "logistics-system.jar"]
          ]
          yAxis = { left = { min = 0, max = 3 } }
        }
      },
      # ===== Row 3: Alarm state 요약 =====
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 4
        properties = {
          title = "Disaster Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.webwas_heartbeat_loss.arn,
            aws_cloudwatch_metric_alarm.webwas_springboot_down.arn,
            aws_cloudwatch_metric_alarm.db_heartbeat_loss.arn
          ]
        }
      }
    ]
  })
}
