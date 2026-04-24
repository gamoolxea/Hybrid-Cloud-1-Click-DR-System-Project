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
  description = "생성된 알람 이름 리스트"
  value = [
    aws_cloudwatch_metric_alarm.webwas_heartbeat_loss.alarm_name,
    aws_cloudwatch_metric_alarm.webwas_springboot_down.alarm_name,
    aws_cloudwatch_metric_alarm.db_heartbeat_loss.alarm_name,
  ]
}
