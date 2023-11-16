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

module "cw" {
  source ="git@github.com:satishkumarkrishnan/Terraform-CloudWatch.git?ref=main"  
}

# TF code MSK cluster
resource "aws_msk_cluster" "tokyo-msk-cluster" {
  cluster_name           = "tokyo-msk-cluster"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    client_subnets = [
	   module.cw.vpc_fe_subnet.vpc_az[0].id,
	   module.cw.vpc_fe_subnet.vpc_az[1].id,      
    ]
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [module.cw.vpc_fe_sg]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = module.cw.kms_id
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
        bucket  = module.cw.s3_bucket
        #bucket  = aws_s3_bucket.kms_encrypted.id
        prefix  = "logs/msk-"
      }
    }
  }

  tags = {
    foo = "bar"
  }  
}