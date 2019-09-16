# VPC Configuration parameters
variable "create_subnet_group" {
  description = "A boolean variable noting if a new DB subnet group should be created."
  type        = "string"
  default     = true
}

variable "existing_subnet_group" {
  description = "The existing DB subnet group to use for this instance (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "security_groups" {
  description = "A list of EC2 security groups to assign to this resource"
  type        = "list"
}

variable "subnets" {
  description = "Subnets for RDS Instances"
  type        = "list"
}

# Backups and Maintenance
variable "backup_retention_period" {
  description = "The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups. Compass best practice is 30 or more days."
  type        = "string"
  default     = 35
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled."
  type        = "string"
  default     = "05:00-06:00"
}

variable "db_snapshot_id" {
  description = "The name of a DB snapshot (optional)."
  type        = "string"
  default     = ""
}

variable "maintenance_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled."
  type        = "string"
  default     = "Sun:07:00-Sun:08:00"
}

# Basic RDS

variable "copy_tags_to_snapshot" {
  description = "Indicates whether to copy all of the user-defined tags from the DB instance to snapshots of the DB instance."
  type        = "string"
  default     = true
}

variable "dbname" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = "string"
  default     = ""
}

variable "db_instance_create_timeout" {
  description = "Timeout for creating instances, replicas, and restoring from Snapshots"
  type        = "string"
  default     = "60m"
}

variable "db_instance_update_timeout" {
  description = "Timeout for datbabse modifications"
  type        = "string"
  default     = "80m"
}

variable "db_instance_delete_timeout" {
  description = "Timeout for destroying databases. This includes the time required to take snapshots"
  type        = "string"
  default     = "60m"
}

variable "enable_deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  type        = "string"
  default     = false
}

variable "engine" {
  description = "Database Engine Type.  Allowed values: mariadb, mysql, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, sqlserver-web"
  type        = "string"
}

variable "engine_version" {
  description = "Database Engine Minor Version http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html"
  type        = "string"
  default     = ""
}

variable "instance_class" {
  description = "The database instance type."
  type        = "string"
}

variable "name" {
  description = "The name prefix to use for the resources created in this module."
  type        = "string"
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = "string"
  default     = ""
}

variable "storage_iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'"
  type        = "string"
  default     = 0
}

variable "storage_size" {
  description = "Select RDS Volume Size in GB."
  type        = "string"
  default     = ""
}

variable "max_storage_size" {
  description = "Select Max RDS Volume Size in GB. Value other than 0 will enable storage autoscaling"
  type        = "string"
  default     = "0"
}

variable "storage_type" {
  description = "Select RDS Volume Type."
  type        = "string"
  default     = "gp2"
}

variable "timezone" {
  description = "The server time zone"
  type        = "string"
  default     = ""
}

# Advance RDS

variable "auto_minor_version_upgrade" {
  description = "Boolean value that indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = "string"
  default     = true
}

variable "create_option_group" {
  description = "A boolean variable noting if a new option group should be created."
  type        = "string"
  default     = true
}

variable "create_parameter_group" {
  description = "A boolean variable noting if a new parameter group should be created."
  type        = "string"
  default     = true
}

variable "existing_option_group_name" {
  description = "The existing option group to use for this instance. (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "existing_parameter_group_name" {
  description = "The existing parameter group to use for this instance. (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "family" {
  description = "Parameter Group Family Name (ex. mysql5.7,sqlserver-se-12.0,postgres9.5,oracle-se-12.1,mariadb10.1)"
  type        = "string"
  default     = ""
}

variable "kms_key_id" {
  description = "KMS Key Arn to use for storage encryption. (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "multi_az" {
  description = "Create a multi-AZ RDS database instance"
  type        = "string"
  default     = true
}

variable "options" {
  description = "List of custom options to apply to the option group."
  type        = "list"
  default     = []
}

variable "parameters" {
  description = "List of custom parameters to apply to the parameter group."
  type        = "list"
  default     = []
}

variable "publicly_accessible" {
  description = "Boolean value that indicates whether the database instance is an Internet-facing instance."
  type        = "string"
  default     = false
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = "string"
  default     = false
}

# Monitoring

variable "alarm_cpu_limit" {
  description = "CloudWatch CPUUtilization Threshold"
  type        = "string"
  default     = 60
}

variable "alarm_free_space_limit" {
  description = "CloudWatch Free Storage Space Limit Threshold (Bytes)"
  type        = "string"
  default     = 1024000000
}

variable "alarm_read_iops_limit" {
  description = "CloudWatch Read IOPSLimit Threshold"
  type        = "string"
  default     = 100
}

variable "alarm_write_iops_limit" {
  description = "CloudWatch Write IOPSLimit Threshold"
  type        = "string"
  default     = 100
}

variable "existing_monitoring_role" {
  description = "ARN of an existing enhanced monitoring role to use for this instance. (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = "string"
  default     = 0
}

variable "notification_topic" {
  description = "SNS Topic ARN to use for customer notifications from CloudWatch alarms. (OPTIONAL)"
  type        = "string"
  default     = ""
}

variable "rackspace_alarms_enabled" {
  description = "Specifies whether non-emergency rackspace alarms will create a ticket."
  type        = "string"
  default     = false
}

# Authentication

variable "password" {
  description = "Password for the local administrator account."
  type        = "string"
}

variable "username" {
  description = "The name of master user for the client DB instance."
  type        = "string"
  default     = "dbadmin"
}

# Other
variable "apply_immediately" {
  description = "Should database modifications be applied immediately?"
  default     = false
  type        = "string"
}

variable "character_set_name" {
  description = "(Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information."
  default     = ""
  type        = "string"
}

variable "environment" {
  description = "Application environment for which this network is being created. one of: ('Development', 'Integration', 'PreProduction', 'Production', 'QA', 'Staging', 'Test')"
  type        = "string"
  default     = "Development"
}

variable "event_categories" {
  description = "A list of RDS event categories.  Submissions will be made to the provided NotificationTopic for each matching event. Acceptable values can be found with the CLI command 'aws rds describe-event-categories' (OPTIONAL)"
  type        = "list"
  default     = []
}

variable "iam_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  default     = false
  type        = "string"
}

variable "internal_record_name" {
  description = "Record Name for the new Resource Record in the Internal Hosted Zone"
  type        = "string"
  default     = ""
}

variable "internal_zone_id" {
  description = "The Route53 Internal Hosted Zone ID"
  type        = "string"
  default     = ""
}

variable "internal_zone_name" {
  description = "TLD for Internal Hosted Zone"
  type        = "string"
  default     = ""
}

variable "license_model" {
  description = "License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1"
  default     = ""
  type        = "string"
}

variable "rackspace_managed" {
  description = "Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents."
  type        = "string"
  default     = true
}

variable "read_replica" {
  description = "Specifies whether this RDS instance is a read replica."
  default     = false
  type        = "string"
}

variable "final_snapshot_suffix" {
  description = "string appended to the final snapshot name with a `-` delimiter"
  type        = "string"
  default     = ""
}

variable "skip_final_snapshot" {
  description = "Boolean value to control if the DB instance will take a final snapshot when destroyed.  This value should be set to false if a final snapshot is desired."
  type        = "string"
  default     = false
}

variable "source_db" {
  description = "The ID of the source DB instance.  For cross region replicas, the full ARN should be provided"
  default     = ""
  type        = "string"
}

variable "tags" {
  description = "Custom tags to apply to all resources."
  type        = "map"
  default     = {}
}
