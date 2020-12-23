terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.7"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "oregon"
  region  = "us-west-2"
  version = "~> 2.7"
}

# this is for example purposes, please use best practice for secret storage in a production environment
resource "random_string" "password" {
  length      = 16
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.1"

  vpc_name = "Test1VPC"
}

module "vpc_dr" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.1"

  providers = {
    aws = aws.oregon
  }

  name = "Test2VPC"
}

####################################################################################################
# Postgres Master                                                                                   #
####################################################################################################

module "rds_master" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.8"

  ##################
  # Required Configuration
  ##################

  engine            = "postgres"                    #  Required
  instance_class    = "db.t2.large"                 #  Required
  name              = "sample-postgres-rds"         #  Required
  password          = random_string.password.result #  Required - see usage warning at top of file
  security_groups   = [module.vpc.default_sg]       #  Required
  storage_encrypted = true                          #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets           = module.vpc.private_subnets    #  Required
  timezone          = "US/Central"
  username          = "dbadmin" # Parameter defaults to "dbadmin"


  ##################
  # VPC Configuration
  ##################

  # create_subnet_group   = true
  # existing_subnet_group = "some-subnet-group-name"

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "11.5"
  # port                  = "5432"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade    = true
  # create_parameter_group        = true
  # create_option_group           = true
  # existing_option_group_name    = "some-option-group-name"
  # existing_parameter_group_name = "some-parameter-group-name"
  # family                        = "postgres11"
  # kms_key_id                    = "some-kms-key-id"
  # multi_az                      = false
  # options                       = []
  # parameters                    = []
  # publicly_accessible           = false
  # storage_encrypted             = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_cpu_limit          = 60
  # alarm_free_space_limit   = 1024000000
  # alarm_read_iops_limit    = 100
  # alarm_write_iops_limit   = 100
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }
}

####################################################################################################
# Postgres Same Region Replica                                                                     #
####################################################################################################

module "rds_replica" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.8"

  ##################
  # Required Configuration
  ##################

  create_option_group           = false
  create_parameter_group        = false
  create_subnet_group           = false
  engine                        = "postgres" #  Required
  existing_option_group_name    = module.rds_master.option_group
  existing_parameter_group_name = module.rds_master.parameter_group
  existing_subnet_group         = module.rds_master.subnet_group
  instance_class                = "db.t2.large"            #  Required
  name                          = "sample-postgres-rds-rr" #  Required
  password                      = ""                       #  Retrieved from source DB
  read_replica                  = true
  security_groups               = [module.vpc.default_sg] #  Required
  storage_encrypted             = true                    #  Parameter defaults to false, but enabled for Cross Region Replication example
  source_db                     = module.rds_master.db_instance
  subnets                       = module.vpc.private_subnets #  Required
  timezone                      = "US/Central"

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "11.5"
  # port                  = "5432"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade = true
  # family                     = "postgres11"
  # kms_key_id                 = "some-kms-key-id"
  # multi_az                   = false
  # options                    = []
  # parameters                 = []
  # publicly_accessible        = false
  # storage_encrypted          = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_cpu_limit          = 60
  # alarm_free_space_limit   = 1024000000
  # alarm_read_iops_limit    = 100
  # alarm_write_iops_limit   = 100
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"
  # rackspace_alarms_enabled = true

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }
}

####################################################################################################
# Postgres Cross Region Replica                                                                    #
####################################################################################################

data "aws_kms_alias" "rds_crr" {
  provider = aws.oregon
  name     = "alias/aws/rds"
}

module "rds_cross_region_replica" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.8"
  #######################
  # Required parameters #
  #######################

  engine            = "postgres"                                #  Required
  instance_class    = "db.t2.large"                             #  Required
  kms_key_id        = data.aws_kms_alias.rds_crr.target_key_arn # Parameter needed since we are replicating an db instance with encrypted storage.
  name              = "sample-postgres-rds-crr"                 #  Required
  password          = ""                                        #  Retrieved from source DB
  read_replica      = true
  security_groups   = [module.vpc_dr.default_sg] #  Required
  source_db         = module.rds_master.db_instance_arn
  storage_encrypted = true                          #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets           = module.vpc_dr.private_subnets #  Required

  ##################
  # VPC Configuration
  ##################

  # create_subnet_group   = true
  # existing_subnet_group = "some-subnet-group-name"

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "11.5"
  # port                  = "5432"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"
  # timezone              = "US/Central"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade    = true
  # create_option_group           = true
  # create_parameter_group        = true
  # existing_option_group_name    = "some-option-group-name"
  # existing_parameter_group_name = "some-parameter-group-name"
  # family                        = "postgres11"
  # kms_key_id                    = "some-kms-key-id"
  # multi_az                      = false
  # options                       = []
  # parameters                    = []
  # publicly_accessible           = false
  # storage_encrypted             = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_write_iops_limit   = 100
  # alarm_read_iops_limit    = 100
  # alarm_free_space_limit   = 1024000000
  # alarm_cpu_limit          = 60
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"
  # rackspace_alarms_enabled = true

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }

  providers = {
    aws = aws.oregon
  }
}
