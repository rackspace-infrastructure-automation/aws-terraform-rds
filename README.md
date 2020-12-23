# aws-terraform-rds

This module creates an RDS instance.  It currently supports master, replica, and cross region replica RDS instances.

## Basic Usage

```HCL
module "rds" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.8"

  engine            = "mysql"                         #  Required
  instance_class    = "db.t2.large"                   #  Required
  name              = "sample-mysql-rds"              #  Required
  password          = "${data.aws_kms_secrets.rds_credentials.plaintext["password"]}" #  Required
  security_groups   = ["${module.vpc.default_sg}"]    #  Required
  storage_encrypted = true                            #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets           = "${module.vpc.private_subnets}" #  Required
}
```

Full working references are available at [examples](examples)

## Terraform 0.12 upgrade

There should be no changes required to move from previous versions of this module to version 0.12.0 or higher.

## Other TF Modules Used  
Using [aws-terraform-cloudwatch\_alarm](https://github.com/rackspace-infrastructure-automation/aws-terraform-cloudwatch_alarm) to create the following CloudWatch Alarms:
	- free\_storage\_space\_alarm\_ticket
	- replica\_lag\_alarm\_ticket
	- free\_storage\_space\_alarm\_email
	- write\_iops\_high\_alarm\_email
	- read\_iops\_high\_alarm\_email
	- cpu\_high\_alarm\_email
	- replica\_lag\_alarm\_email

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| alarm\_cpu\_limit | CloudWatch CPUUtilization Threshold | `number` | `60` | no |
| alarm\_free\_space\_limit | CloudWatch Free Storage Space Limit Threshold (Bytes) | `number` | `1024000000` | no |
| alarm\_read\_iops\_limit | CloudWatch Read IOPSLimit Threshold | `number` | `100` | no |
| alarm\_write\_iops\_limit | CloudWatch Write IOPSLimit Threshold | `number` | `100` | no |
| apply\_immediately | Should database modifications be applied immediately? | `bool` | `false` | no |
| auto\_minor\_version\_upgrade | Boolean value that indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | `bool` | `true` | no |
| backup\_retention\_period | The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups. Compass best practice is 30 or more days. | `number` | `35` | no |
| backup\_window | The daily time range during which automated backups are created if automated backups are enabled. | `string` | `"05:00-06:00"` | no |
| character\_set\_name | (Optional) The character set name to use for DB encoding in Oracle instances. This can't be changed. See Oracle Character Sets Supported in Amazon RDS for more information. | `string` | `""` | no |
| cloudwatch\_exports\_logs\_list | list of log exports to be enabled | `list(string)` | `[]` | no |
| copy\_tags\_to\_snapshot | Indicates whether to copy all of the user-defined tags from the DB instance to snapshots of the DB instance. | `bool` | `true` | no |
| create\_option\_group | A boolean variable noting if a new option group should be created. | `bool` | `true` | no |
| create\_parameter\_group | A boolean variable noting if a new parameter group should be created. | `bool` | `true` | no |
| create\_subnet\_group | A boolean variable noting if a new DB subnet group should be created. | `bool` | `true` | no |
| db\_instance\_create\_timeout | Timeout for creating instances, replicas, and restoring from Snapshots | `string` | `"60m"` | no |
| db\_instance\_delete\_timeout | Timeout for destroying databases. This includes the time required to take snapshots | `string` | `"60m"` | no |
| db\_instance\_update\_timeout | Timeout for datbabse modifications | `string` | `"80m"` | no |
| db\_snapshot\_id | The name of a DB snapshot (optional). | `string` | `""` | no |
| dbname | The DB name to create. If omitted, no database is created initially | `string` | `""` | no |
| directory\_id | The ID of the Directory Service Active Directory domain.  Only applicable for Microsoft SQL engines. | `string` | `""` | no |
| enable\_deletion\_protection | If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false. | `bool` | `false` | no |
| enable\_domain\_join | Enable joining an Microsoft SQL Server RDS instance to an AD Directory Service. If enabled, a value must be provided for the `directory_id` variable. | `bool` | `false` | no |
| engine | Database Engine Type.  Allowed values: mariadb, mysql, oracle-ee, oracle-se, oracle-se1, oracle-se2, postgres, sqlserver-ee, sqlserver-ex, sqlserver-se, sqlserver-web | `string` | n/a | yes |
| engine\_version | Database Engine Minor Version http://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html | `string` | `""` | no |
| environment | Application environment for which this network is being created. one of: ('Development', 'Integration', 'PreProduction', 'Production', 'QA', 'Staging', 'Test') | `string` | `"Development"` | no |
| event\_categories | A list of RDS event categories.  Submissions will be made to the provided NotificationTopic for each matching event. Acceptable values can be found with the CLI command 'aws rds describe-event-categories' (OPTIONAL) | `list(string)` | `[]` | no |
| existing\_monitoring\_role | ARN of an existing enhanced monitoring role to use for this instance. (OPTIONAL) | `string` | `""` | no |
| existing\_option\_group\_name | The existing option group to use for this instance. (OPTIONAL) | `string` | `""` | no |
| existing\_parameter\_group\_name | The existing parameter group to use for this instance. (OPTIONAL) | `string` | `""` | no |
| existing\_subnet\_group | The existing DB subnet group to use for this instance (OPTIONAL) | `string` | `""` | no |
| family | Parameter Group Family Name (ex. mysql5.7, sqlserver-se-12.0, postgres9.5, postgres10, postgres11, postgres12, oracle-se-12.1, mariadb10.1) | `string` | `""` | no |
| final\_snapshot\_suffix | string appended to the final snapshot name with a `-` delimiter | `string` | `""` | no |
| iam\_authentication\_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | `bool` | `false` | no |
| instance\_class | The database instance type. | `string` | n/a | yes |
| internal\_record\_name | Record Name for the new Resource Record in the Internal Hosted Zone | `string` | `""` | no |
| internal\_zone\_id | The Route53 Internal Hosted Zone ID | `string` | `""` | no |
| internal\_zone\_name | TLD for Internal Hosted Zone | `string` | `""` | no |
| kms\_key\_id | KMS Key Arn to use for storage encryption. (OPTIONAL) | `string` | `""` | no |
| license\_model | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | `string` | `""` | no |
| maintenance\_window | The daily time range during which automated backups are created if automated backups are enabled. | `string` | `"Sun:07:00-Sun:08:00"` | no |
| max\_storage\_size | Select Max RDS Volume Size in GB. Value other than 0 will enable storage autoscaling | `number` | `0` | no |
| monitoring\_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60. | `number` | `0` | no |
| multi\_az | Create a multi-AZ RDS database instance | `bool` | `true` | no |
| name | The name prefix to use for the resources created in this module. | `string` | n/a | yes |
| notification\_topic | SNS Topic ARN to use for customer notifications from CloudWatch alarms. (OPTIONAL) | `string` | `""` | no |
| options | List of custom options to apply to the option group. | `list` | `[]` | no |
| parameters | List of custom parameters to apply to the parameter group. | `list(map(string))` | `[]` | no |
| password | Password for the local administrator account. | `string` | n/a | yes |
| performance\_insights\_kms\_key\_id | KMS Key ID for performance insights (if retention specified). | `string` | `""` | no |
| performance\_insights\_retention\_period | Retention duration for performance insights. Can be enabled with one of the two AWS allowed values of 7 or 731.  See https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.Enabling.html for further details. | `number` | `0` | no |
| port | The port on which the DB accepts connections | `string` | `""` | no |
| publicly\_accessible | Boolean value that indicates whether the database instance is an Internet-facing instance. | `bool` | `false` | no |
| rackspace\_alarms\_enabled | Specifies whether non-emergency rackspace alarms will create a ticket. | `bool` | `false` | no |
| rackspace\_managed | Boolean parameter controlling if instance will be fully managed by Rackspace support teams, created CloudWatch alarms that generate tickets, and utilize Rackspace managed SSM documents. | `bool` | `true` | no |
| read\_replica | Specifies whether this RDS instance is a read replica. | `string` | `false` | no |
| security\_groups | A list of EC2 security groups to assign to this resource | `list(string)` | n/a | yes |
| skip\_final\_snapshot | Boolean value to control if the DB instance will take a final snapshot when destroyed.  This value should be set to false if a final snapshot is desired. | `bool` | `false` | no |
| source\_db | The ID of the source DB instance.  For cross region replicas, the full ARN should be provided | `string` | `""` | no |
| storage\_encrypted | Specifies whether the DB instance is encrypted | `bool` | `false` | no |
| storage\_iops | The amount of provisioned IOPS. Setting this implies a storage\_type of 'io1' | `number` | `0` | no |
| storage\_size | Select RDS Volume Size in GB. | `string` | `""` | no |
| storage\_type | Select RDS Volume Type. | `string` | `"gp2"` | no |
| subnets | Subnets for RDS Instances | `list(string)` | n/a | yes |
| tags | Custom tags to apply to all resources. | `map(string)` | `{}` | no |
| timezone | The server time zone | `string` | `""` | no |
| username | The name of master user for the client DB instance. | `string` | `"dbadmin"` | no |

## Outputs

| Name | Description |
|------|-------------|
| db\_endpoint | Database endpoint |
| db\_endpoint\_address | Address of database endpoint |
| db\_endpoint\_port | Port of database endpoint |
| db\_instance | The DB instance identifier |
| db\_instance\_arn | The DB instance ARN |
| jdbc\_connection\_string | JDBC connection string for database |
| monitoring\_role | The IAM role used for Enhanced Monitoring |
| option\_group | The Option Group used by the DB Instance |
| parameter\_group | The Parameter Group used by the DB Instance |
| subnet\_group | The DB Subnet Group used by the DB Instance |

