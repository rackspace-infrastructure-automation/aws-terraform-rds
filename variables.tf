variable "alarm_cpu_limit" {
  description = "CloudWatch CPUUtilization Threshold"
  type        = number
  default     = 60
}

variable "alarm_free_space_limit" {
  description = "CloudWatch Free Storage Space Limit Threshold (Bytes)"
  type        = number
  default     = 1024000000
}

variable "alarm_read_iops_limit" {
  description = "CloudWatch Read IOPSLimit Threshold"
  type        = number
  default     = 100
}

variable "alarm_write_iops_limit" {
  description = "CloudWatch Write IOPSLimit Threshold"
  type        = number
  default     = 100
}

variable "apply_immediately" {
  description = "Should database modifications be applied immediately?"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Boolean value that indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups. Compass best practice is 30 or more days."
  type        = number
  default     = 35
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled."
  type        = string
  default     = "05:00-06:00"
}

variable "character_set_name" {
  description = "(Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information."
  type        = string
  default     = ""
}

variable "copy_tags_to_snapshot" {
  description = "Indicates whether to copy all of the user-defined tags from the DB instance to snapshots of the DB instance."
  type        = bool
  default     = true
}

variable "create_option_group" {
  description = "A boolean variable noting if a new option group should be created."
  type        = bool
  default     = true
}

variable "create_parameter_group" {
  description = "A boolean variable noting if a new parameter group should be created."
  type        = bool
  default     = true
}

variable "create_subnet_group" {
  description = "A boolean variable noting if a new DB subnet group should be created."
  type        = bool
  default     = true
}

variable "db_instance_create_timeout" {
  description = "Timeout for creating instances, replicas, and restoring from Snapshots"
  type        = string
  default     = "60m"
}

variable "db_instance_delete_timeout" {
  description = "Timeout for destroying databases. This includes the time required to take snapshots"
  type        = string
  default     = "60m"
}

variable "db_instance_update_timeout" {
  description = "Timeout for datbabse modifications"
  type        = string
  default     = "80m"
}

variable "db_snapshot_id" {
  description = "The name of a DB snapshot (optional)."
  type        = string
  default     = ""
}

variable "dbname" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  type        = bool
  default     = false
}

variable "engine" {
  description = "Database Engine Type.  Allowed values: mariadb, mysql, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, sqlserver-web"
  type        = string
}

variable "engine_version" {
  description = "Database Engine Minor Version http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Application environment for which this network is being created. one of: ('Development', 'Integration', 'PreProduction', 'Production', 'QA', 'Staging', 'Test')"
  type        = string
  default     = "Development"
}

variable "event_categories" {
  description = "A list of RDS event categories.  Submissions will be made to the provided NotificationTopic for each matching event. Acceptable values can be found with the CLI command 'aws rds describe-event-categories' (OPTIONAL)"
  type        = list(string)
  default     = []
}

variable "existing_monitoring_role" {
  description = "ARN of an existing enhanced monitoring role to use for this instance. (OPTIONAL)"
  type        = string
  default     = ""
}

variable "existing_option_group_name" {
  description = "The existing option group to use for this instance. (OPTIONAL)"
  type        = string
  default     = ""
}

variable "existing_parameter_group_name" {
  description = "The existing parameter group to use for this instance. (OPTIONAL)"
  type        = string
  default     = ""
}

variable "existing_subnet_group" {
  description = "The existing DB subnet group to use for this instance (OPTIONAL)"
  type        = string
  default     = ""
}

variable "family" {
  description = "Parameter Group Family Name (ex. mysql5.7, sqlserver-se-12.0, postgres9.5, postgres10, postgres11, postgres12, oracle-se-12.1, mariadb10.1)"
  type        = string
  default     = ""
}

variable "final_snapshot_suffix" {
  description = "string appended to the final snapshot name with a `-` delimiter"
  type        = string
  default     = ""
}

variable "iam_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}
variable "instance_class" {
  description = "The database instance type."
  type        = string
}

variable "internal_record_name" {
  description = "Record Name for the new Resource Record in the Internal Hosted Zone"
  type        = string
  default     = ""
}

variable "internal_zone_id" {
  description = "The Route53 Internal Hosted Zone ID"
  type        = string
  default     = ""
}

variable "internal_zone_name" {
  description = "TLD for Internal Hosted Zone"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS Key Arn to use for storage encryption. (OPTIONAL)"
  type        = string
  default     = ""
}

variable "license_model" {
  description = "License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1"
  type        = string
  default     = ""
}

variable "maintenance_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled."
  type        = string
  default     = "Sun:07:00-Sun:08:00"
}

variable "max_storage_size" {
  description = "Select Max RDS Volume Size in GB. Value other than 0 will enable storage autoscaling"
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}


variable "multi_az" {
  description = "Create a multi-AZ RDS database instance"
  type        = bool
  default     = true
}

variable "name" {
  description = "The name prefix to use for the resources created in this module."
  type        = string
}

variable "notification_topic" {
  description = "SNS Topic ARN to use for customer notifications from CloudWatch alarms. (OPTIONAL)"
  type        = string
  default     = ""
}

variable "options" {
  description = "List of custom options to apply to the option group."
  type        = list(map(string))
  default     = []
}

variable "parameters" {
  description = "List of custom parameters to apply to the parameter group."
  type        = list(map(string))
  default     = []
}

variable "password" {
  description = "Password for the local administrator account."
  type        = string
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = string
  default     = ""
}

variable "publicly_accessible" {
  description = "Boolean value that indicates whether the database instance is an Internet-facing instance."
  type        = bool
  default     = false
}

variable "rackspace_alarms_enabled" {
  description = "Specifies whether non-emergency rackspace alarms will create a ticket."
  type        = bool
  default     = false
}

variable "rackspace_managed" {
  description = "Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents."
  type        = bool
  default     = true
}

variable "read_replica" {
  description = "Specifies whether this RDS instance is a read replica."
  type        = string
  default     = false
}

variable "security_groups" {
  description = "A list of EC2 security groups to assign to this resource"
  type        = list(string)
}

variable "skip_final_snapshot" {
  description = "Boolean value to control if the DB instance will take a final snapshot when destroyed.  This value should be set to false if a final snapshot is desired."
  type        = bool
  default     = false
}

variable "source_db" {
  description = "The ID of the source DB instance.  For cross region replicas, the full ARN should be provided"
  default     = ""
  type        = string
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = false
}

variable "storage_iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'"
  type        = number
  default     = 0
}

variable "storage_size" {
  description = "Select RDS Volume Size in GB."
  type        = string
  default     = ""
}

variable "storage_type" {
  description = "Select RDS Volume Type."
  type        = string
  default     = "gp2"
}


variable "subnets" {
  description = "Subnets for RDS Instances"
  type        = list(string)
}

variable "tags" {
  description = "Custom tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "timezone" {
  description = "The server time zone"
  type        = string
  default     = ""
}

variable "username" {
  description = "The name of master user for the client DB instance."
  type        = string
  default     = "dbadmin"
}
