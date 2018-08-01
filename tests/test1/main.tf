provider "aws" {
  version = "~> 1.2"
  region  = "us-west-2"
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

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//"

  vpc_name = "Test1VPC"
}

module "rds_mysql" {
  source = "../../module"

  subnets                    = "${module.vpc.private_subnets}"
  security_groups            = ["${module.vpc.default_sg}"]
  name                       = "test-mysql-rds"                   #  Required
  engine                     = "mysql"                            #  Required
  instance_class             = "db.t2.large"                      #  Required
  storage_encrypted          = true                               #  Parameter defaults to false, but enabled for Cross Region Replication example
  password                   = "${random_string.password.result}" #  Required
  existing_option_group_name = "default:mysql-5-7"
}
