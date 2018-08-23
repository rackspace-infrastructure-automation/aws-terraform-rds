/**
 * # aws-terraform-rds
 *
 *This module creates an RDS instance.  It currently supports master, replica, and cross region replica RDS instances.
 *
 *## Basic Usage
 *
 *```
 *module "rds" {
 *  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds//?ref=v0.0.1"
 *
 *  subnets           = "${module.vpc.private_subnets}" #  Required
 *  security_groups   = ["${module.vpc.default_sg}"]    #  Required
 *  name              = "sample-mysql-rds"              #  Required
 *  engine            = "mysql"                         #  Required
 *  instance_class    = "db.t2.large"                   #  Required
 *  storage_encrypted = true                            #  Parameter defaults to false, but enabled for Cross Region Replication example
 *  password = "${data.aws_kms_secrets.rds_credentials.plaintext["password"]}" #  Required
 *}
 *```
 *
 * Full working references are available at [examples](examples)
 * ## Limitations
 *
 * - Terraform does not support joining a Microsoft SQL RDS instance to a Directory Service at this time.  This has been requested in https://github.com/terraform-providers/terraform-provider-aws/pull/5378 and can be added once that functionality is present.
 */

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  engine_class = "${element(split("-",var.engine), 0)}"
  is_mssql     = "${local.engine_class == "sqlserver"}" # To allow setting MSSQL specific settings
  is_oracle    = "${local.engine_class == "oracle"}"    # To allow setting Oracle specific settings
  is_postgres  = "${local.engine_class == "postgres"}"  # To allow setting postgresql specific settings

  # This map contains default values for several properties if they are explicitly defined.
  # Should be occasionally updated as newer engine versions are released
  engine_defaults = {
    mariadb = {
      version = "10.2.12"
    }

    mysql = {
      version = "5.7.21"
    }

    oracle = {
      port         = "1521"
      version      = "12.1.0.2.v12"
      storage_size = "100"
      license      = "license-included"
      jdbc_proto   = "oracle:thin"
    }

    postgres = {
      port       = "5432"
      version    = "10.3"
      jdbc_proto = "postgresql"
    }

    sqlserver = {
      port         = "1433"
      version      = "14.00.3015.40.v1"
      storage_size = "200"
      license      = "license-included"
      jdbc_proto   = "sqlserver"
    }
  }

  # This section grabs the explicitly provided variable, then the default for the engine from the above
  # map, and finally a module default where appropriate.
  jdbc_proto = "${lookup(local.engine_defaults[local.engine_class], "jdbc_proto", "mysql")}"

  port = "${coalesce(var.port, lookup(local.engine_defaults[local.engine_class], "port", "3306"))}"

  storage_size   = "${coalesce(var.storage_size, lookup(local.engine_defaults[local.engine_class], "storage_size", 10))}"
  engine_version = "${coalesce(var.engine_version, lookup(local.engine_defaults[local.engine_class], "version"))}"
  license_model  = "${coalesce(var.license_model, lookup(local.engine_defaults[local.engine_class], "license", ""))}"

  tags {
    Name            = "${var.name}"
    ServiceProvider = "Rackspace"
    Environment     = "${var.environment}"
  }

  # If we are not setting a timezone, or we are using MSSQL, we will use "none" for the parameter list.
  parameter_lookup = "${var.timezone == "" || local.is_mssql ? "none":"timezone"}"

  parameters {
    "none" = []

    "timezone" = [{
      name  = "time_zone"
      value = "${var.timezone}"
    }]
  }

  options = []

  same_region_replica = "${var.read_replica && length(split(":", var.source_db)) == 1}"

  # Break up the engine version in to chunks to get the major version part.  This is a single number for postgresql (ex: 10)
  # and two numbers for all other engines (ex: 5.7).
  version_chunk = "${chunklist(split(".", local.engine_version), local.is_postgres ? 1 : 2)}"

  major_version = "${join(".", local.version_chunk[0])}"

  # We will use a '-' to join engine and major version for Oracle and MSSQL, and an empty string for other engines.
  family_separator = "${local.is_mssql || local.is_oracle ? "-" : ""}"

  # MSSQL Family name only uses a single digit on the minor version number when setting the family (ex: sqlserver-se-14.0 , not sqlserver-se-14.00)
  major_version_substring = "${local.is_mssql ? substr(local.major_version, 0, length(local.major_version) - 1) : local.major_version}"
  family                  = "${coalesce(var.family, join(local.family_separator, list(var.engine, local.major_version_substring)))}"

  customer_alarm_topic = "${ list( list(), list(var.notification_topic) ) }"

  # Only create 5th alarm for replica lag when the instance has a source DB
  customer_alarm_count = "${var.read_replica ? 5 : 4}"
  notification_set     = "${ var.customer_notifications_enabled ? 1 : 0 }"

  customer_alarms = [
    {
      alarm_name         = "free-storage-space"
      evaluation_periods = 30
      description        = "Free storage space has fallen below threshold, sending email notification."
      operator           = "LessThanOrEqualToThreshold"
      threshold          = 3072000000
      metric             = "FreeStorageSpace"
    },
    {
      alarm_name         = "write-iops-high"
      evaluation_periods = 5
      description        = "Alarm if WriteIOPs > ${var.alarm_write_iops_limit} for 5 minutes"
      operator           = "GreaterThanThreshold"
      threshold          = "${var.alarm_write_iops_limit}"
      metric             = "WriteIOPS"
    },
    {
      alarm_name         = "read-iops-high"
      evaluation_periods = 5
      description        = "Alarm if ReadIOPs > ${var.alarm_read_iops_limit} for 5 minutes"
      operator           = "GreaterThanThreshold"
      threshold          = "${var.alarm_read_iops_limit}"
      metric             = "ReadIOPS"
    },
    {
      alarm_name         = "cpu-high"
      evaluation_periods = 15
      description        = "Alarm if CPU > ${var.alarm_cpu_limit} for 15 minutes"
      operator           = "GreaterThanThreshold"
      threshold          = "${var.alarm_cpu_limit}"
      metric             = "CPUUtilization"
    },
    {
      alarm_name         = "replica-lag"
      evaluation_periods = 3
      description        = "ReplicaLag has exceeded threshold."
      operator           = "GreaterThanOrEqualToThreshold"
      threshold          = "3600"
      metric             = "ReplicaLag"
    },
  ]

  rs_alarm_topic         = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rackspace-support-urgent"]
  alarm_sns_notification = "${compact(list(var.notification_topic))}"
  rs_alarm_option        = "${var.rackspace_managed ? "managed" : "unmanaged"}"

  rs_alarm_action = {
    managed   = "${local.rs_alarm_topic}"
    unmanaged = "${local.alarm_sns_notification}"
  }

  rs_ok_action = {
    managed   = "${local.rs_alarm_topic}"
    unmanaged = []
  }

  # Only create replica lag alarm if we have a source DB and rackspace_alarms_enabled is true
  rs_alarm_count = "${var.read_replica && var.rackspace_alarms_enabled ? 2 : 1}"

  rs_alarms = [
    {
      alarm_name         = "free-storage-space"
      evaluation_periods = 30
      description        = "Free storage space has fallen below threshold, generating ticket."
      operator           = "LessThanOrEqualToThreshold"
      threshold          = "${var.alarm_free_space_limit}"
      metric             = "FreeStorageSpace"
    },
    {
      alarm_name         = "replica-lag"
      evaluation_periods = 5
      description        = "ReplicaLag has exceeded threshold, generating ticket.."
      operator           = "GreaterThanOrEqualToThreshold"
      threshold          = "3600"
      metric             = "ReplicaLag"
    },
  ]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  count = "${var.create_subnet_group ? 1 : 0}"

  name_prefix = "${var.name}-"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = ["${var.subnets}"]

  tags = "${merge(var.tags, local.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "db_parameter_group" {
  count = "${var.create_parameter_group ? 1 : 0}"

  name_prefix = "${var.name}-"
  description = "Database parameter group for ${var.name}"
  family      = "${local.family}"

  parameter = "${concat(var.parameters, local.parameters[local.parameter_lookup])}"

  tags = "${merge(var.tags, local.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "db_option_group" {
  count = "${var.create_option_group ? 1 : 0}"

  name_prefix              = "${var.name}-"
  option_group_description = "Option group for ${var.name}"
  engine_name              = "${var.engine}"
  major_engine_version     = "${local.major_version}"

  option = "${concat(var.options, local.options)}"

  tags = "${merge(var.tags, local.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring_role" {
  count = "${var.existing_monitoring_role == ""  && var.monitoring_interval > 0 ? 1 : 0}"

  name_prefix = "${var.name}-"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_policy" {
  count = "${var.existing_monitoring_role == ""  && var.monitoring_interval > 0 ? 1 : 0}"

  role       = "${aws_iam_role.enhanced_monitoring_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

locals {
  subnet_group        = "${coalesce(var.existing_subnet_group, join("", aws_db_subnet_group.db_subnet_group.*.id))}"
  parameter_group     = "${coalesce(var.existing_parameter_group_name, join("", aws_db_parameter_group.db_parameter_group.*.id))}"
  option_group        = "${coalesce(var.existing_option_group_name, join("", aws_db_option_group.db_option_group.*.id))}"
  monitoring_role_arn = "${coalesce(var.existing_monitoring_role, join("", aws_iam_role.enhanced_monitoring_role.*.arn))}"
}

resource "aws_db_instance" "db_instance" {
  identifier_prefix = "${var.name}-"

  engine         = "${var.engine}"
  engine_version = "${local.engine_version}"
  instance_class = "${var.instance_class}"
  port           = "${local.port}"

  allocated_storage = "${local.storage_size}"
  storage_type      = "${var.storage_type}"
  storage_encrypted = "${var.storage_encrypted}"
  iops              = "${var.storage_iops}"
  kms_key_id        = "${var.kms_key_id}"

  name                                = "${var.dbname}"
  username                            = "${var.username}"
  password                            = "${var.password}"
  iam_database_authentication_enabled = "${var.iam_authentication_enabled}"

  replicate_source_db = "${var.source_db}"
  snapshot_identifier = "${var.db_snapshot_id}"

  vpc_security_group_ids = ["${var.security_groups}"]
  db_subnet_group_name   = "${local.same_region_replica ? "" : local.subnet_group}"
  parameter_group_name   = "${local.same_region_replica ? "" : local.parameter_group}"
  option_group_name      = "${local.same_region_replica ? "" : local.option_group}"
  multi_az               = "${var.read_replica ? false : var.multi_az}"
  publicly_accessible    = "${var.publicly_accessible}"

  monitoring_interval = "${var.monitoring_interval}"
  monitoring_role_arn = "${local.monitoring_role_arn}"

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = "${var.auto_minor_version_upgrade}"
  maintenance_window          = "${var.maintenance_window}"
  skip_final_snapshot         = "${var.read_replica || var.skip_final_snapshot}"
  copy_tags_to_snapshot       = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier   = "${var.name}-final-snapshot"
  backup_retention_period     = "${var.read_replica ? 0 : var.backup_retention_period}"
  backup_window               = "${var.backup_window}"
  apply_immediately           = "${var.apply_immediately}"

  license_model      = "${local.license_model}"
  character_set_name = "${local.is_oracle ? var.character_set_name : ""}"
  timezone           = "${local.is_mssql ? var.timezone : ""}"

  tags = "${merge(var.tags, local.tags)}"

  # Option Group, Parameter Group, and Subnet Group added as the coalesce to use any existing groups seems to throw off
  # dependancies while destroying resources
  depends_on = [
    "aws_iam_role_policy_attachment.enhanced_monitoring_policy",
    "aws_db_option_group.db_option_group",
    "aws_db_parameter_group.db_parameter_group",
    "aws_db_subnet_group.db_subnet_group",
  ]
}

resource "aws_cloudwatch_metric_alarm" "rackspace_alarms" {
  count = "${local.rs_alarm_count}"

  alarm_name          = "${var.name}-${lookup(local.rs_alarms[count.index], "alarm_name")}-ticket"
  comparison_operator = "${lookup(local.rs_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(local.rs_alarms[count.index], "evaluation_periods")}"
  metric_name         = "${lookup(local.rs_alarms[count.index], "metric")}"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${lookup(local.rs_alarms[count.index], "threshold")}"
  alarm_description   = "${lookup(local.rs_alarms[count.index], "description")}"
  alarm_actions       = ["${local.rs_alarm_action[local.rs_alarm_option]}"]
  ok_actions          = ["${local.rs_ok_action[local.rs_alarm_option]}"]

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.db_instance.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "customer_alarms" {
  count = "${local.notification_set * local.customer_alarm_count}"

  alarm_name          = "${var.name}-${lookup(local.customer_alarms[count.index], "alarm_name")}"
  comparison_operator = "${lookup(local.customer_alarms[count.index], "operator")}"
  evaluation_periods  = "${lookup(local.customer_alarms[count.index], "evaluation_periods")}"
  metric_name         = "${lookup(local.customer_alarms[count.index], "metric")}"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${lookup(local.customer_alarms[count.index], "threshold")}"
  alarm_description   = "${lookup(local.customer_alarms[count.index], "description")}"
  alarm_actions       = ["${local.customer_alarm_topic[local.notification_set]}"]

  dimensions {
    DBInstanceIdentifier = "${aws_db_instance.db_instance.id}"
  }
}

resource "aws_db_event_subscription" "default" {
  count = "${length(var.event_categories) > 0 ? 1 : 0}"

  name_prefix      = "${var.name}-"
  event_categories = "${var.event_categories}"
  sns_topic        = "${element(local.customer_alarm_topic[local.notification_set], 0)}"
  source_type      = "db-instance"
  source_ids       = ["${aws_db_instance.db_instance.id}"]
}

data "aws_route53_zone" "hosted_zone" {
  count = "${var.internal_record_name != "" ? 1 : 0}"

  name         = "${var.internal_zone_name}"
  private_zone = true
}

resource "aws_route53_record" "zone_record_alias" {
  count = "${var.internal_record_name != "" ? 1 : 0}"

  name    = "${var.internal_record_name}.${data.aws_route53_zone.hosted_zone.name}"
  ttl     = "300"
  type    = "CNAME"
  zone_id = "${data.aws_route53_zone.hosted_zone.zone_id}"
  records = ["${aws_db_instance.db_instance.address}"]
}
