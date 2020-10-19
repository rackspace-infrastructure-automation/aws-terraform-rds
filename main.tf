/*
 * # aws-terraform-rds
 *
 * This module creates an RDS instance.  It currently supports master, replica, and cross region replica RDS instances.
 *
 * ## Basic Usage
 *
 * ```HCL
 * module "rds" {
 *   source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.4"
 *
 *   engine            = "mysql"                         #  Required
 *   instance_class    = "db.t2.large"                   #  Required
 *   name              = "sample-mysql-rds"              #  Required
 *   password          = "${data.aws_kms_secrets.rds_credentials.plaintext["password"]}" #  Required
 *   security_groups   = ["${module.vpc.default_sg}"]    #  Required
 *   storage_encrypted = true                            #  Parameter defaults to false, but enabled for Cross Region Replication example
 *   subnets           = "${module.vpc.private_subnets}" #  Required
 * }
 * ```
 *
 * Full working references are available at [examples](examples)
 * ## Limitations
 *
 * - Terraform does not support joining a Microsoft SQL RDS instance to a Directory Service at this time.  This has been requested in https://github.com/terraform-providers/terraform-provider-aws/pull/5378 and can be added once that functionality is present.
 *
 * ## Terraform 0.12 upgrade
 *
 * There should be no changes required to move from previous versions of this module to version 0.12.0 or higher.
 *
 * ## Other TF Modules Used
 * Using [aws-terraform-cloudwatch_alarm](https://github.com/rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm) to create the following CloudWatch Alarms:
 * 	- free_storage_space_alarm_ticket
 * 	- replica_lag_alarm_ticket
 * 	- free_storage_space_alarm_email
 * 	- write_iops_high_alarm_email
 * 	- read_iops_high_alarm_email
 * 	- cpu_high_alarm_email
 * 	- replica_lag_alarm_email
 */

terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

locals {
  engine_class  = element(split("-", var.engine), 0)
  is_mssql      = local.engine_class == "sqlserver" # To allow setting MSSQL specific settings
  is_oracle     = local.engine_class == "oracle"    # To allow setting Oracle specific settings
  is_postgres   = local.engine_class == "postgres"
  is_postgres10 = local.engine_class == "postgres" && local.postgres_major_version == "10" # To allow setting postgresql specific settings
  is_postgres11 = local.engine_class == "postgres" && local.postgres_major_version == "11" # To allow setting postgresql specific settings
  is_postgres12 = local.engine_class == "postgres" && local.postgres_major_version == "12" # To allow setting postgresql specific settings
  is_oracle18   = local.engine_class == "oracle" && local.oracle_major_version == "18"     # To allow setting Oracle 18 specific settings
  is_oracle19   = local.engine_class == "oracle" && local.oracle_major_version == "19"     # To allow setting Oracle 19 specific settings

  # This map contains default values for several properties if they are explicitly defined.
  # Should be occasionally updated as newer engine versions are released
  engine_defaults = {
    mariadb = {
      version = "10.3.13"
    }
    mysql = {
      version = "5.7.26"
    }
    oracle = {
      port         = "1521"
      version      = "19.0.0.0.ru-2020-01.rur-2020-01.r1"
      storage_size = "100"
      license      = "license-included"
      jdbc_proto   = "oracle:thin"
    }
    postgres = {
      port       = "5432"
      version    = "11.5"
      jdbc_proto = "postgresql"
    }
    sqlserver = {
      port         = "1433"
      version      = "14.00.3049.1.v1"
      storage_size = "200"
      license      = "license-included"
      jdbc_proto   = "sqlserver"
    }
  }

  # This section grabs the explicitly provided variable, then the default for the engine from the above
  # map, and finally a module default where appropriate.
  jdbc_proto = lookup(local.engine_defaults[local.engine_class], "jdbc_proto", "mysql")

  port = coalesce(var.port, lookup(local.engine_defaults[local.engine_class], "port", "3306"))

  storage_size           = coalesce(var.storage_size, lookup(local.engine_defaults[local.engine_class], "storage_size", 10))
  engine_version         = coalesce(var.engine_version, local.engine_defaults[local.engine_class]["version"])
  postgres_major_version = element(split(".", local.engine_version), 0)
  oracle_major_version   = element(split(".", local.engine_version), 0)

  license_model = lookup(local.engine_defaults[local.engine_class], "license", null)

  tags = {
    Name            = var.name
    ServiceProvider = "Rackspace"
    Environment     = var.environment
  }

  # If we are not setting a timezone, or we are using MSSQL, we will use "none" for the parameter list.
  parameter_lookup = var.timezone == "" || local.is_mssql ? "none" : "timezone"

  parameters = {
    "none" = []
    "timezone" = [
      {
        name  = local.is_postgres ? "timezone" : "time_zone"
        value = var.timezone
      },
    ]
  }

  options = []

  same_region_replica = var.read_replica && length(split(":", var.source_db)) == 1

  # Break up the engine version in to chunks to get the major version part.  This is a single number for PostgreSQL10/11/12
  # and two numbers for all other engines (ex: 5.7).
  version_chunk = chunklist(split(".", local.engine_version), local.is_postgres10 || local.is_postgres11 || local.is_postgres12 || local.is_oracle18 || local.is_oracle19 ? 1 : 2)
  major_version = join(".", local.version_chunk[0])

  # We will use a '-' to join engine and major version for Oracle and MSSQL, and an empty string for other engines.
  family_separator = local.is_mssql || local.is_oracle ? "-" : ""

  # MSSQL Family name only uses a single digit on the minor version number when setting the family (ex: sqlserver-se-14.0 , not sqlserver-se-14.00)
  major_version_substring = local.is_mssql ? substr(local.major_version, 0, length(local.major_version) - 1) : local.major_version
  family                  = coalesce(var.family, join(local.family_separator, [var.engine, local.major_version_substring]))
}

resource "aws_db_subnet_group" "db_subnet_group" {
  count = var.create_subnet_group ? 1 : 0

  description = "Database subnet group for ${var.name}"
  name_prefix = "${var.name}-"
  subnet_ids  = var.subnets
  tags        = merge(var.tags, local.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "db_parameter_group" {
  count = var.create_parameter_group ? 1 : 0

  description = "Database parameter group for ${var.name}"
  name_prefix = "${var.name}-"
  family      = local.family
  tags        = merge(var.tags, local.tags)

  dynamic "parameter" {
    for_each = concat(var.parameters, local.parameters[local.parameter_lookup])
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "db_option_group" {
  count = var.create_option_group ? 1 : 0

  engine_name              = var.engine
  major_engine_version     = local.major_version
  name_prefix              = "${var.name}-"
  option_group_description = "Option group for ${var.name}"
  tags                     = merge(var.tags, local.tags)

  dynamic "option" {
    for_each = concat(var.options, local.options)
    content {
      db_security_group_memberships  = lookup(option.value, "db_security_group_memberships", null)
      option_name                    = option.value.option_name
      port                           = lookup(option.value, "port", null)
      version                        = lookup(option.value, "version", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = [lookup(option.value, "option_settings", null)]
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["monitoring.rds.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring_role" {
  count = var.existing_monitoring_role == "" && var.monitoring_interval > 0 ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name_prefix        = "${var.name}-"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_policy" {
  count = var.existing_monitoring_role == "" && var.monitoring_interval > 0 ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  role       = aws_iam_role.enhanced_monitoring_role[0].name
}

locals {
  subnet_group        = length(aws_db_subnet_group.db_subnet_group.*.id) > 0 ? aws_db_subnet_group.db_subnet_group[0].id : var.existing_subnet_group
  parameter_group     = length(aws_db_parameter_group.db_parameter_group.*.id) > 0 ? aws_db_parameter_group.db_parameter_group[0].id : var.existing_parameter_group_name
  option_group        = length(aws_db_option_group.db_option_group.*.id) > 0 ? aws_db_option_group.db_option_group[0].id : var.existing_option_group_name
  monitoring_role_arn = length(aws_iam_role.enhanced_monitoring_role.*.arn) > 0 ? aws_iam_role.enhanced_monitoring_role[0].arn : var.existing_monitoring_role
}

resource "aws_db_instance" "db_instance" {

  allocated_storage                   = local.storage_size
  allow_major_version_upgrade         = false
  apply_immediately                   = var.apply_immediately
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  backup_retention_period             = var.read_replica ? 0 : var.backup_retention_period
  backup_window                       = var.backup_window
  character_set_name                  = local.is_oracle ? var.character_set_name : null
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  db_subnet_group_name                = local.same_region_replica ? null : local.subnet_group
  deletion_protection                 = var.enable_deletion_protection
  enabled_cloudwatch_logs_exports     = var.list_of_cloudwatch_exports
  engine                              = var.engine
  engine_version                      = local.engine_version
  final_snapshot_identifier           = lower("${var.name}-final-snapshot${var.final_snapshot_suffix == "" ? "" : "-"}${var.final_snapshot_suffix}")
  iam_database_authentication_enabled = var.iam_authentication_enabled
  identifier_prefix                   = "${lower(var.name)}-"
  instance_class                      = var.instance_class
  iops                                = var.storage_iops
  kms_key_id                          = var.kms_key_id
  license_model                       = var.license_model == "" ? local.license_model : var.license_model
  maintenance_window                  = var.maintenance_window
  max_allocated_storage               = var.max_storage_size
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_arn                 = var.monitoring_interval > 0 ? local.monitoring_role_arn : null
  multi_az                            = var.read_replica ? false : var.multi_az
  name                                = var.dbname
  option_group_name                   = local.same_region_replica ? null : local.option_group
  parameter_group_name                = local.same_region_replica ? null : local.parameter_group
  password                            = var.password
  port                                = local.port
  publicly_accessible                 = var.publicly_accessible
  replicate_source_db                 = var.source_db
  skip_final_snapshot                 = var.read_replica || var.skip_final_snapshot
  snapshot_identifier                 = var.db_snapshot_id
  storage_encrypted                   = var.storage_encrypted
  storage_type                        = var.storage_type
  tags                                = merge(var.tags, local.tags)
  timezone                            = local.is_mssql ? var.timezone : null
  username                            = var.username
  vpc_security_group_ids              = var.security_groups

  timeouts {
    create = var.db_instance_create_timeout
    update = var.db_instance_update_timeout
    delete = var.db_instance_delete_timeout
  }

  # Option Group, Parameter Group, and Subnet Group added as the coalesce to use any existing groups seems to throw off
  # dependancies while destroying resources
  depends_on = [
    aws_iam_role_policy_attachment.enhanced_monitoring_policy,
    aws_db_option_group.db_option_group,
    aws_db_parameter_group.db_parameter_group,
    aws_db_subnet_group.db_subnet_group,
  ]
}

module "free_storage_space_alarm_ticket" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_description        = "Free storage space has fallen below threshold, generating ticket."
  alarm_name               = "${var.name}-free-storage-space-ticket"
  comparison_operator      = "LessThanOrEqualToThreshold"
  evaluation_periods       = 30
  metric_name              = "FreeStorageSpace"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = var.rackspace_alarms_enabled
  rackspace_managed        = var.rackspace_managed
  severity                 = "urgent"
  statistic                = "Average"
  threshold                = var.alarm_free_space_limit

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "replica_lag_alarm_ticket" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_count              = var.read_replica ? 1 : 0
  alarm_description        = "ReplicaLag has exceeded threshold, generating ticket.."
  alarm_name               = "${var.name}-replica-lag-ticket"
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  evaluation_periods       = 5
  metric_name              = "ReplicaLag"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = var.rackspace_alarms_enabled
  rackspace_managed        = var.rackspace_managed
  severity                 = "urgent"
  statistic                = "Average"
  threshold                = 3600

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "free_storage_space_alarm_email" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_description        = "Free storage space has fallen below threshold, sending email notification."
  alarm_name               = "${var.name}-free-storage-space-email"
  comparison_operator      = "LessThanOrEqualToThreshold"
  customer_alarms_enabled  = true
  evaluation_periods       = 30
  metric_name              = "FreeStorageSpace"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = false
  statistic                = "Average"
  threshold                = 3072000000

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "write_iops_high_alarm_email" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_description        = "Alarm if WriteIOPs > ${var.alarm_write_iops_limit} for 5 minutes"
  alarm_name               = "${var.name}-write-iops-high-email"
  comparison_operator      = "GreaterThanThreshold"
  customer_alarms_enabled  = true
  evaluation_periods       = 5
  metric_name              = "WriteIOPS"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = false
  statistic                = "Average"
  threshold                = var.alarm_write_iops_limit

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "read_iops_high_alarm_email" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_description        = "Alarm if ReadIOPs > ${var.alarm_read_iops_limit} for 5 minutes"
  alarm_name               = "${var.name}-read-iops-high-email"
  comparison_operator      = "GreaterThanThreshold"
  customer_alarms_enabled  = true
  evaluation_periods       = 5
  metric_name              = "ReadIOPS"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = false
  statistic                = "Average"
  threshold                = var.alarm_read_iops_limit

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "cpu_high_alarm_email" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_description        = "Alarm if CPU > ${var.alarm_cpu_limit} for 15 minutes"
  alarm_name               = "${var.name}-cpu-high-email"
  comparison_operator      = "GreaterThanThreshold"
  customer_alarms_enabled  = true
  evaluation_periods       = 15
  metric_name              = "CPUUtilization"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = false
  statistic                = "Average"
  threshold                = var.alarm_cpu_limit

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

module "replica_lag_alarm_email" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm?ref=v0.12.0"

  alarm_count              = var.read_replica ? 1 : 0
  alarm_description        = "ReplicaLag has exceeded threshold."
  alarm_name               = "${var.name}-replica-lag-email"
  comparison_operator      = "GreaterThanOrEqualToThreshold"
  customer_alarms_enabled  = true
  evaluation_periods       = 3
  metric_name              = "ReplicaLag"
  namespace                = "AWS/RDS"
  notification_topic       = [var.notification_topic]
  period                   = 60
  rackspace_alarms_enabled = false
  statistic                = "Average"
  threshold                = 3600

  dimensions = [
    {
      DBInstanceIdentifier = aws_db_instance.db_instance.id
    },
  ]
}

resource "aws_db_event_subscription" "default" {
  count = length(var.event_categories) > 0 ? 1 : 0

  event_categories = var.event_categories
  name_prefix      = "${lower(var.name)}-"
  sns_topic        = var.notification_topic
  source_type      = "db-instance"
  source_ids       = [aws_db_instance.db_instance.id]
}

resource "aws_route53_record" "zone_record_alias" {
  count = var.internal_record_name != "" ? 1 : 0

  name    = "${var.internal_record_name}.${var.internal_zone_name}"
  records = [aws_db_instance.db_instance.address]
  ttl     = "300"
  type    = "CNAME"
  zone_id = var.internal_zone_id
}
