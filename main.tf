terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

#TF code for importing IAM Role
module "iam" {
  source ="git@github.com:satishkumarkrishnan/Terraform_IAM.git?ref=main"
}

module "vpc" {
  source ="git@github.com:satishkumarkrishnan/terraform-aws-vpc.git?ref=main"
  }

module "asg" {
  source="git@github.com:satishkumarkrishnan/terraform-aws-asg.git?ref=main" 
  depends_on = [module.vpc ]
}

module "kms" {
  source ="git@github.com:satishkumarkrishnan/Terraform-KMS.git?ref=main"
  depends_on = [module.asg]
}

# TF code MSK cluster
resource "aws_msk_cluster" "tokyo_msk_cluster" {
  cluster_name           = "tokyo_msk_cluster"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    client_subnets = [
	  module.vpc.vpc_fe_subnet,
	  module.vpc.vpc_be_subnet,      
    ]
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [module.vpc.vpc_fe_sg]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = module.kms.kms_arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = module.cw.cw_log_group
      }
#      firehose {
#        enabled         = true
#        delivery_stream = aws_kinesis_firehose_delivery_stream.test_stream.name
#      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.kms_encrypted.id
        prefix  = "logs/msk-"
      }
    }
  }

  tags = {
    foo = "bar"
  }
}




