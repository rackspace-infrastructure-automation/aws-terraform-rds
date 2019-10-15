provider "aws" {
  version = "~> 2.0"
  region  = "us-west-2"
}

provider "aws" {
  region = "us-east-2"
  alias  = "ohio"
}

provider "random" {
  version = "~> 1.0"
}

resource "random_string" "identifier" {
  length  = 6
  special = false
  lower   = true
  upper   = false
  number  = false
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
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"

  vpc_name = "${random_string.identifier.result}VPC-1"
}

module "vpc_dr" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"

  providers = {
    aws = "aws.ohio"
  }

  vpc_name = "${random_string.identifier.result}VPC-2"
}

########################
#         MySQL        #
########################
module "rds_mysql_latest" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "mysql-${random_string.identifier.result}"
  engine              = "mysql"
  instance_class      = "db.t3.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#       Replica        #
########################
module "rds_replica_latest" {
  source = "../../module"

  subnets                = "${module.vpc.private_subnets}"
  security_groups        = ["${module.vpc.default_sg}"]
  create_subnet_group    = false
  name                   = "mysql-${random_string.identifier.result}-rr"
  engine                 = "mysql"
  instance_class         = "db.t3.large"
  storage_encrypted      = true
  create_parameter_group = false
  create_option_group    = false
  read_replica           = true
  source_db              = "${module.rds_mysql_latest.db_instance}"
  password               = ""
}

########################
# Cross Region Replica #
########################

data "aws_kms_alias" "rds_crr" {
  provider = "aws.ohio"
  name     = "alias/aws/rds"
}

module "rds_cross_region_replica_latest" {
  source = "../../module"

  providers = {
    aws = "aws.ohio"
  }

  subnets           = "${module.vpc_dr.private_subnets}"
  security_groups   = ["${module.vpc_dr.default_sg}"]
  name              = "mysql-${random_string.identifier.result}-crr"
  engine            = "mysql"
  instance_class    = "db.t3.large"
  storage_encrypted = true
  kms_key_id        = "${data.aws_kms_alias.rds_crr.target_key_arn}"
  password          = ""
  read_replica      = true
  source_db         = "${module.rds_mysql_latest.db_instance_arn}"
}

########################
#       MariaDB        #
########################
module "rds_mariadb_latest" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "mariadb-${random_string.identifier.result}"
  engine              = "mariadb"
  instance_class      = "db.t3.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#        MS SQL        #
########################
module "rds_mssql_latest" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "mssql-${random_string.identifier.result}"
  engine              = "sqlserver-se"
  instance_class      = "db.m5.large"
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#        Oracle        #
########################
module "rds_oracle_latest" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "oracle-${random_string.identifier.result}"
  engine              = "oracle-se2"
  instance_class      = "db.t3.large"
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
}

########################
#       Postgres       #
########################
module "rds_postgres_latest" {
  source = "../../module"

  subnets             = "${module.vpc.private_subnets}"
  security_groups     = ["${module.vpc.default_sg}"]
  name                = "postgres-${random_string.identifier.result}"
  engine              = "postgres"
  instance_class      = "db.t3.large"
  storage_encrypted   = true
  password            = "${random_string.password.result}"
  create_option_group = false
  skip_final_snapshot = true
  storage_size        = 100
  max_storage_size    = 200
}
