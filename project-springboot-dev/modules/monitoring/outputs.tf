############################
# Monitoring 모듈 outputs
############################

output "sns_topic_arn" {
  description = "DR alert SNS topic ARN — SNS publish 테스트 / Slack 추가 subscription 용"
  value       = aws_sns_topic.dr_alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL (발표 시연용)"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.hybrid_dr.dashboard_name}"
}

output "alarms_console_url" {
  description = "CloudWatch Alarms 콘솔 URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:"
}

output "alarm_names" {
  description = "생성된 알람 이름 리스트 (온프렘 3개 + AWS 5개 = 총 8개)"
  value = [
    # 온프렘 (CRITICAL)
    aws_cloudwatch_metric_alarm.webwas_heartbeat_loss.alarm_name,
    aws_cloudwatch_metric_alarm.webwas_springboot_down.alarm_name,
    aws_cloudwatch_metric_alarm.db_heartbeat_loss.alarm_name,
    # AWS (DISASTER + WARNING)
    aws_cloudwatch_metric_alarm.alb_haproxy_unhealthy.alarm_name,
    aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_storage_low.alarm_name,
  ]
}
