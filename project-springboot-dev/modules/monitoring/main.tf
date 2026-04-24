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
# CloudWatch Alarm 4: ALB HAProxy Target Unhealthy
############################
# Pilot-light 모드에서 ALB → haproxy-tg 로 라우팅 중 target 이 unhealthy 되면
# 서비스 실질 장애. (Phase 3 실패 증상과도 일치 — 방금 디버깅했던 바로 그 경우)
resource "aws_cloudwatch_metric_alarm" "alb_haproxy_unhealthy" {
  alarm_name          = "${var.project_name}-alb-haproxy-unhealthy"
  alarm_description   = "[DISASTER] ALB haproxy target 1분 이상 unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.haproxy_tg_arn_suffix
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "critical"
    Layer    = "aws"
  })
}

############################
# CloudWatch Alarm 5: ALB 5xx 에러 급증
############################
# 앱 내부 에러 (500, 502, 503, 504). Target 은 healthy 한데 응답이 5xx 면
# 코드 버그 또는 backend 간헐 장애.
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  alarm_description   = "[WARNING] ALB target 5xx 에러 1분 내 ${var.alb_5xx_threshold} 건 초과"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = var.alb_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
  ok_actions    = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "warning"
    Layer    = "aws"
  })
}

############################
# CloudWatch Alarm 6: RDS CPU High
############################
# RDS 폭주 — 쿼리 최적화 필요 또는 인스턴스 스케일업 필요 신호.
# 5분 지속 조건 = 순간 피크 무시.
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  alarm_description   = "[WARNING] RDS CPU 5분 이상 ${var.rds_cpu_threshold}% 초과"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = var.rds_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "warning"
    Layer    = "aws"
  })
}

############################
# CloudWatch Alarm 7: RDS Connection Pool 고갈 위험
############################
# 앱의 Connection pool 설정 (HikariCP 기본 10 per instance) × instance 수 보다
# 큰 값이 임계값. 고갈되면 신규 요청 큐잉되다 타임아웃.
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  alarm_description   = "[WARNING] RDS 동시 연결 수 ${var.rds_connections_threshold} 초과 — 커넥션 풀 고갈 조짐"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = var.rds_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "warning"
    Layer    = "aws"
  })
}

############################
# CloudWatch Alarm 8: RDS Storage Low
############################
# 디스크 용량 부족. ALARM 발화 시점에 자동 storage autoscaling 또는 수동 증설 필요.
# 발화 후 대응 시간 확보를 위해 5분 집계 + 1 period 기준 (너무 빠르면 ephemeral 변동에 민감).
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.project_name}-rds-storage-low"
  alarm_description   = "[WARNING] RDS 남은 스토리지 ${var.rds_storage_low_bytes / 1073741824} GB 미만 — 용량 확장 필요"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = var.rds_storage_low_bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]

  tags = merge(var.common_tags, {
    Severity = "warning"
    Layer    = "aws"
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
      # ===== Row 3: ALB 메트릭 =====
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          title   = "ALB Request Count (1min)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          title   = "ALB Healthy / UnHealthy Host Count (haproxy-tg)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.haproxy_tg_arn_suffix],
            [".", "UnHealthyHostCount", ".", ".", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          title   = "ALB 5xx Error Count (1min)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { stat = "Sum" }]
          ]
        }
      },
      # ===== Row 4: RDS 메트릭 =====
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 8
        height = 6
        properties = {
          title   = "RDS CPU %"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier]
          ]
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 18
        width  = 8
        height = 6
        properties = {
          title   = "RDS Database Connections"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 18
        width  = 8
        height = 6
        properties = {
          title   = "RDS Free Storage (GB)"
          view    = "timeSeries"
          region  = var.aws_region
          stacked = false
          metrics = [
            [{ expression = "m1 / 1073741824", label = "FreeStorage GB", id = "e1" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_identifier, { id = "m1", visible = false }]
          ]
        }
      },
      # ===== Row 5: Alarm state 요약 (8개 전체) =====
      {
        type   = "alarm"
        x      = 0
        y      = 24
        width  = 24
        height = 4
        properties = {
          title = "All Alarms (Onprem + AWS)"
          alarms = [
            aws_cloudwatch_metric_alarm.webwas_heartbeat_loss.arn,
            aws_cloudwatch_metric_alarm.webwas_springboot_down.arn,
            aws_cloudwatch_metric_alarm.db_heartbeat_loss.arn,
            aws_cloudwatch_metric_alarm.alb_haproxy_unhealthy.arn,
            aws_cloudwatch_metric_alarm.alb_5xx_errors.arn,
            aws_cloudwatch_metric_alarm.rds_cpu_high.arn,
            aws_cloudwatch_metric_alarm.rds_connections_high.arn,
            aws_cloudwatch_metric_alarm.rds_storage_low.arn
          ]
        }
      }
    ]
  })
}
