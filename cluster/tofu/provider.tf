###############################################################################
# Terraform Settings & Backend
###############################################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

###############################################################################
# AWS Provider
###############################################################################
provider "aws" {
  region = var.aws_region
}

###############################################################################
# Data Sources
###############################################################################
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
