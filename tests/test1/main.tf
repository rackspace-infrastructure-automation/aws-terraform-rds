provider "aws" {
  version = "~> 1.2"
  region  = "us-west-2"
}

provider "aws" {
  region = "us-east-2"
  alias  = "ohio"
}

provider "random" {
  version = "~> 1.0"
}

resource "random_string" "password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "random_string" "mssql_name" {
  length  = 15
  special = false
  number  = false
  lower   = true
  upper   = false
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//"

  vpc_name = "Test1VPC"
}

module "vpc_dr" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.0.1"

  providers = {
    aws = "aws.ohio"
  }

  vpc_name = "Test2VPC"
}

########################
#         MySQL        #
########################
module "rds_mysql" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "test-mysql-rds"
  engine              = "mysql"
  instance_class      = "db.t2.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#       Replica        #
########################
module "rds_replica" {
  source = "../../module"

  subnets                = "${module.vpc.private_subnets}"
  security_groups        = ["${module.vpc.default_sg}"]
  create_subnet_group    = false
  name                   = "test-mysql-rds-rr"
  engine                 = "mysql"
  instance_class         = "db.t2.large"
  storage_encrypted      = true
  create_parameter_group = false
  create_option_group    = false
  read_replica           = true
  source_db              = "${module.rds_mysql.db_instance}"
  password               = ""
}

########################
# Cross Region Replica #
########################

data "aws_kms_alias" "rds_crr" {
  provider = "aws.ohio"
  name     = "alias/aws/rds"
}

module "rds_cross_region_replica" {
  source = "../../module"

  providers = {
    aws = "aws.ohio"
  }

  subnets           = "${module.vpc_dr.private_subnets}"
  security_groups   = ["${module.vpc_dr.default_sg}"]
  name              = "test-mysql-rds-crr"
  engine            = "mysql"
  instance_class    = "db.t2.large"
  storage_encrypted = true
  kms_key_id        = "${data.aws_kms_alias.rds_crr.target_key_arn}"
  password          = ""
  read_replica      = true
  source_db         = "${module.rds_mysql.db_instance_arn}"
}

########################
#       MariaDB        #
########################
module "rds_mariadb" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "test-mariadb-rds"
  engine              = "mariadb"
  instance_class      = "db.t2.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#        MS SQL        #
########################
module "rds_mssql" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "${random_string.mssql_name.result}"
  engine              = "sqlserver-se"
  instance_class      = "db.m4.large"
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#        Oracle        #
########################
module "rds_oracle" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "test-oracle-rds"
  engine              = "oracle-se2"
  instance_class      = "db.t2.large"
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#       Postgres       #
########################
module "rds_postgres" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "test-postgres-rds"
  engine              = "postgres"
  instance_class      = "db.t2.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}
