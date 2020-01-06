output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.db_instance.endpoint
}

output "db_endpoint_address" {
  description = "Address of database endpoint"
  value       = aws_db_instance.db_instance.address
}

output "db_endpoint_port" {
  description = "Port of database endpoint"
  value       = aws_db_instance.db_instance.port
}

output "db_instance" {
  description = "The DB instance identifier"
  value       = aws_db_instance.db_instance.id
}

output "db_instance_arn" {
  description = "The DB instance ARN"
  value       = aws_db_instance.db_instance.arn
}

output "jdbc_connection_string" {
  description = "JDBC connection string for database"
  value       = "jdbc:${local.jdbc_proto}://${aws_db_instance.db_instance.endpoint}/${aws_db_instance.db_instance.name}"
}

output "monitoring_role" {
  description = "The IAM role used for Enhanced Monitoring"
  value       = local.monitoring_role_arn
}

output "option_group" {
  description = "The Option Group used by the DB Instance"
  value       = local.option_group
}

output "parameter_group" {
  description = "The Parameter Group used by the DB Instance"
  value       = local.parameter_group
}

output "subnet_group" {
  description = "The DB Subnet Group used by the DB Instance"
  value       = local.subnet_group
}

