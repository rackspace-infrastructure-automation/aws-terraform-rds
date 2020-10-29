terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 3.0"
  region  = "us-west-2"
}

provider "aws" {
  alias   = "ohio"
  region  = "us-east-2"
  version = "~> 3.0"
}

provider "random" {
  version = "~> 2.0"
}

resource "random_string" "identifier" {
  length  = 6
  lower   = true
  number  = false
  special = false
  upper   = false
}

resource "random_string" "password" {
  length      = 16
  min_numeric = 1
  min_lower   = 1
  min_upper   = 1
  special     = false
}

resource "random_string" "mssql_name" {
  length  = 15
  lower   = true
  number  = false
  special = false
  upper   = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.1"

  name = "${random_string.identifier.result}VPC-1"
}

module "vpc_dr" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.1"

  name = "${random_string.identifier.result}VPC-2"

  providers = {
    aws = aws.ohio
  }
}

########################
#         MySQL        #
########################
module "rds_mysql_latest" {
  source = "../../module"

  create_option_group = false
  engine              = "mysql"
  instance_class      = "db.t3.large"
  name                = "mysql-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  storage_encrypted   = true
  subnets             = module.vpc.private_subnets
}

########################
#       Replica        #
########################
module "rds_replica_latest" {
  source = "../../module"

  create_option_group    = false
  create_parameter_group = false
  create_subnet_group    = false
  engine                 = "mysql"
  instance_class         = "db.t3.large"
  name                   = "mysql-${random_string.identifier.result}-rr"
  password               = ""
  read_replica           = true
  security_groups        = [module.vpc.default_sg]
  source_db              = module.rds_mysql_latest.db_instance
  storage_encrypted      = true
  subnets                = module.vpc.private_subnets
}

########################
# Cross Region Replica #
########################

data "aws_kms_alias" "rds_crr" {
  provider = aws.ohio
  name     = "alias/aws/rds"
}

module "rds_cross_region_replica_latest" {
  source = "../../module"

  engine            = "mysql"
  instance_class    = "db.t3.large"
  kms_key_id        = data.aws_kms_alias.rds_crr.target_key_arn
  name              = "mysql-${random_string.identifier.result}-crr"
  password          = ""
  read_replica      = true
  security_groups   = [module.vpc_dr.default_sg]
  source_db         = module.rds_mysql_latest.db_instance_arn
  storage_encrypted = true
  subnets           = module.vpc_dr.private_subnets

  providers = {
    aws = aws.ohio
  }
}

########################
#       MariaDB        #
########################
module "rds_mariadb_latest" {
  source = "../../module"

  create_option_group = false
  engine              = "mariadb"
  instance_class      = "db.t3.large"
  name                = "mariadb-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  storage_encrypted   = true
  subnets             = module.vpc.private_subnets
}

########################
#        MS SQL        #
########################
module "rds_mssql_latest" {
  source = "../../module"

  create_option_group = false
  engine              = "sqlserver-se"
  instance_class      = "db.m5.large"
  name                = "mssql-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  subnets             = module.vpc.private_subnets
}

########################
#        Oracle        #
########################

# oracle 18
module "rds_oracle_18" {
  source = "../../module"

  create_option_group = false
  engine              = "oracle-se2"
  engine_version      = "18.0.0.0.ru-2019-07.rur-2019-07.r1"
  instance_class      = "db.t3.large"
  name                = "oracle18-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  subnets             = module.vpc.private_subnets
}

# defaults to oracle 19
module "rds_oracle_19" {
  source = "../../module"

  create_option_group = false
  engine              = "oracle-se2"
  instance_class      = "db.t3.large"
  name                = "oracle19-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  subnets             = module.vpc.private_subnets
}

########################
#       Postgres       #
########################
module "rds_postgres_latest" {
  source = "../../module"

  create_option_group = false
  engine              = "postgres"
  instance_class      = "db.t3.large"
  max_storage_size    = 200
  name                = "postgres-${random_string.identifier.result}"
  password            = random_string.password.result
  security_groups     = [module.vpc.default_sg]
  skip_final_snapshot = true
  storage_encrypted   = true
  storage_size        = 100
  subnets             = module.vpc.private_subnets
}
