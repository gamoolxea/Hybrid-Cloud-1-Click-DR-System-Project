############################
# DR 운영용 Outputs
############################
output "db_ec2_instance_id" {
  description = "DB EC2 인스턴스 ID (Jenkins Stop/Start 참조용)"
  value       = module.compute.db_ec2_instance_id
}

output "db_ec2_private_ip" {
  description = "DB EC2 프라이빗 IP (Failback 검증용)"
  value       = module.compute.db_ec2_private_ip
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.database.rds_endpoint
}
