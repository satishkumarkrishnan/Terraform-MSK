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