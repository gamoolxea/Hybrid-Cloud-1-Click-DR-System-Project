output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_identifier" {
  description = "RDS DB 식별자 (describe-db-instances, modify-db-instance 용)"
  value       = aws_db_instance.main.identifier
}
