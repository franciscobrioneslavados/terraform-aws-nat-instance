provider "aws" {
  region = var.aws_region
  alias  = "virginia"

  default_tags {
    tags = {
      "Environment" = var.environment
      "ManagedBy"   = var.managed_by
      "OwnerName"   = var.owner_name
      "ProjectName" = var.project_name
    }
  }
}

terraform {
  required_version = ">= 0.13"
  # backend "s3" {
  # bucket = ""
  # key    = ""
  # region = ""
  # dynamodb_table = "terraform-locks"
  # encrypt = false
  # use_lockfile = true # Native s3 locking
  # }
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3" #3.7.2
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5" #5.100.0
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3" #3.2.4
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4" #4.1.0
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2" #2.5.3
    }
  }
}
