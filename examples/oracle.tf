module "rds_oracle" {
  # This needs to be updated once a permanent home is found
  source = "c:\\cftemplates\\aws-terraform-internal\\aviator\\rds"

  ##################
  # VPC Configuration
  ##################

  subnets         = "${local.subnets}"         #  Required
  security_groups = "${local.security_groups}" #  Required

  # existing_subnet_group = "some-subnet-group-name"


  ##################
  # Backups and Maintenance
  ##################


  # maintenance_window      = "Sun:07:00-Sun:08:00"
  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"


  ##################
  # Basic RDS
  ##################

  name           = "sample-oracle-rds" #  Required
  engine         = "oracle-se2"        #  Required
  instance_class = "db.t2.large"       #  Required

  # dbname                = "mydb"
  # engine_version        = "12.1.0.2.v12"
  # port                  = "1521"
  # copy_tags_to_snapshot = true
  # timezone              = "US/Central"
  # storage_type          = "gp2"
  # storage_size          = 100
  # storage_iops          = 0


  ##################
  # RDS Advanced
  ##################


  # publicly_accessible           = false
  # auto_minor_version_upgrade    = true
  # family                        = "oracle-se2-12.1"
  # multi_az                      = false
  # storage_encrypted             = false
  # kms_key_id                    = "some-kms-key-id"
  # parameters                    = []
  # existing_parameter_group_name = "some-parameter-group-name"
  # options                       = []
  # existing_option_group_name    = "some-option-group-name"


  ##################
  # RDS Monitoring
  ##################


  # notification_topic           = "arn:aws:sns:<region>:<account>:some-topic"
  # alarm_write_iops_limit       = 100
  # alarm_read_iops_limit        = 100
  # alarm_free_space_limit       = 1024000000
  # alarm_cpu_limit              = 60
  # monitoring_interval          = 0
  # existing_monitoring_role_arn = ""


  ##################
  # Authentication information
  ##################

  password = "${local.password}" #  Required

  # username = "dbadmin"

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }
}
