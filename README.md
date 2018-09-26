# aws-terraform-rds

This module creates an RDS instance.  It currently supports master, replica, and cross region replica RDS instances.

## Basic Usage

```
module "rds" {
 source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds//?ref=v0.0.1"

 subnets           = "${module.vpc.private_subnets}" #  Required
 security_groups   = ["${module.vpc.default_sg}"]    #  Required
 name              = "sample-mysql-rds"              #  Required
 engine            = "mysql"                         #  Required
 instance_class    = "db.t2.large"                   #  Required
 storage_encrypted = true                            #  Parameter defaults to false, but enabled for Cross Region Replication example
 password = "${data.aws_kms_secrets.rds_credentials.plaintext["password"]}" #  Required
}
```

Full working references are available at [examples](examples)
## Limitations

- Terraform does not support joining a Microsoft SQL RDS instance to a Directory Service at this time.  This has been requested in https://github.com/terraform-providers/terraform-provider-aws/pull/5378 and can be added once that functionality is present.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alarm_cpu_limit | CloudWatch CPUUtilization Threshold | string | `60` | no |
| alarm_free_space_limit | CloudWatch Free Storage Space Limit Threshold (Bytes) | string | `1024000000` | no |
| alarm_read_iops_limit | CloudWatch Read IOPSLimit Threshold | string | `100` | no |
| alarm_write_iops_limit | CloudWatch Write IOPSLimit Threshold | string | `100` | no |
| apply_immediately | Should database modifications be applied immediately? | string | `false` | no |
| auto_minor_version_upgrade | Boolean value that indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | string | `true` | no |
| backup_retention_period | The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups. Compass best practice is 30 or more days. | string | `35` | no |
| backup_window | The daily time range during which automated backups are created if automated backups are enabled. | string | `05:00-06:00` | no |
| character_set_name | (Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information. | string | `` | no |
| copy_tags_to_snapshot | Indicates whether to copy all of the user-defined tags from the DB instance to snapshots of the DB instance. | string | `true` | no |
| create_option_group | A boolean variable noting if a new option group should be created. | string | `true` | no |
| create_parameter_group | A boolean variable noting if a new parameter group should be created. | string | `true` | no |
| create_subnet_group | A boolean variable noting if a new DB subnet group should be created. | string | `true` | no |
| db_instance_create_timeout | Timeout in minutes for creating instances, replicas, and restoring from Snapshots | string | - | yes |
| db_instance_delete_timeout | Timeout in minutes for destroying databases. This includes the time required to take snapshots | string | - | yes |
| db_instance_update_timeout | Timeout in minutes for datbabse modifications | string | - | yes |
| db_snapshot_id | The name of a DB snapshot (optional). | string | `` | no |
| dbname | The DB name to create. If omitted, no database is created initially | string | `` | no |
| engine | Database Engine Type.  Allowed values: mariadb, mysql, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, sqlserver-web | string | - | yes |
| engine_version | Database Engine Minor Version http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html | string | `` | no |
| environment | Application environment for which this network is being created. one of: ('Development', 'Integration', 'PreProduction', 'Production', 'QA', 'Staging', 'Test') | string | `Development` | no |
| event_categories | A list of RDS event categories.  Submissions will be made to the provided NotificationTopic for each matching event. Acceptable values can be found with the CLI command 'aws rds describe-event-categories' (OPTIONAL) | list | `<list>` | no |
| existing_monitoring_role | ARN of an existing enhanced monitoring role to use for this instance. (OPTIONAL) | string | `` | no |
| existing_option_group_name | The existing option group to use for this instance. (OPTIONAL) | string | `` | no |
| existing_parameter_group_name | The existing parameter group to use for this instance. (OPTIONAL) | string | `` | no |
| existing_subnet_group | The existing DB subnet group to use for this instance (OPTIONAL) | string | `` | no |
| family | Parameter Group Family Name (ex. mysql5.7,sqlserver-se-12.0,postgres9.5,oracle-se-12.1,mariadb10.1) | string | `` | no |
| iam_authentication_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | string | `false` | no |
| instance_class | The database instance type. | string | - | yes |
| internal_record_name | Record Name for the new Resource Record in the Internal Hosted Zone. i.e. alb.aws.com | string | `` | no |
| internal_zone_name | TLD for Internal Hosted Zone. i.e. mycompany.local | string | `` | no |
| kms_key_id | KMS Key Arn to use for storage encryption. (OPTIONAL) | string | `` | no |
| license_model | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | string | `` | no |
| maintenance_window | The daily time range during which automated backups are created if automated backups are enabled. | string | `Sun:07:00-Sun:08:00` | no |
| monitoring_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60. | string | `0` | no |
| multi_az | Create a multi-AZ RDS database instance | string | `true` | no |
| name | The name prefix to use for the resources created in this module. | string | - | yes |
| notification_topic | SNS Topic ARN to use for customer notifications from CloudWatch alarms. (OPTIONAL) | string | `` | no |
| options | List of custom options to apply to the option group. | list | `<list>` | no |
| parameters | List of custom parameters to apply to the parameter group. | list | `<list>` | no |
| password | Password for the local administrator account. | string | - | yes |
| port | The port on which the DB accepts connections | string | `` | no |
| publicly_accessible | Boolean value that indicates whether the database instance is an Internet-facing instance. | string | `false` | no |
| rackspace_alarms_enabled | Specifies whether non-emergency rackspace alarms will create a ticket. | string | `false` | no |
| rackspace_managed | Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents. | string | `true` | no |
| read_replica | Specifies whether this RDS instance is a read replica. | string | `false` | no |
| security_groups | A list of EC2 security groups to assign to this resource | list | - | yes |
| skip_final_snapshot | Boolean value to control if the DB instance will take a final snapshot when destroyed.  This value should be set to false if a final snapshot is desired. | string | `false` | no |
| source_db | The ID of the source DB instance.  For cross region replicas, the full ARN should be provided | string | `` | no |
| storage_encrypted | Specifies whether the DB instance is encrypted | string | `false` | no |
| storage_iops | The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' | string | `0` | no |
| storage_size | Select RDS Volume Size in GB. | string | `` | no |
| storage_type | Select RDS Volume Type. | string | `gp2` | no |
| subnets | Subnets for RDS Instances | list | - | yes |
| tags | Custom tags to apply to all resources. | map | `<map>` | no |
| timezone | The server time zone | string | `` | no |
| username | The name of master user for the client DB instance. | string | `dbadmin` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_endpoint | Database endpoint |
| db_endpoint_address | Address of database endpoint |
| db_endpoint_port | Port of database endpoint |
| db_instance | The DB instance identifier |
| db_instance_arn | The DB instance ARN |
| jdbc_connection_string | JDBC connection string for database |
| monitoring_role | The IAM role used for Enhanced Monitoring |
| option_group | The Option Group used by the DB Instance |
| parameter_group | The Parameter Group used by the DB Instance |
| subnet_group | The DB Subnet Group used by the DB Instance |


## Troubleshooting / FAQs

- `* aws_db_option_group.db_option_group: Error Deleting DB Option Group: OptionGroupNotFoundFault: Specified OptionGroupName: rds-2018081717273838300000000f not found.` When attempting to update an RDS instance requiring a rebuild, the creation of a new db_option_group may be required. If this occurs, the `terraform apply` will likely fail, as the option_group has dependencies (RDS final snapshot) and thus cannot be removed. In order to resolve this, apply the following steps:
  - Update RDS module with `create_option_group = "false"`
  - Run `terraform state list` and remove the option group (`terraform state rm module.rds.aws_db_option_group.db_option_group`)
  - Run `terraform apply`
  - Log into AWS Account and manually remove the option group. The dependent snapshot will also need to be removed
  - Remove `create_option_group = "false"`, allowing for the option group to be created
  - Run `terraform apply`
