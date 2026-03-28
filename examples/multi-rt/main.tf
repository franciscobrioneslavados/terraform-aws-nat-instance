terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "nat_instance" {
  source = "../../"

  vpc_id               = "vpc-xxxxxxxxxxxxxxxxx"
  public_subnet_ids    = ["subnet-xxxxxxxxxxxxxxxxx"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]

  # Multiple Route Tables (e.g., app-tier and database-tier)
  route_table_ids = [
    "rtb-xxxxxxxxxxxxxxxxx", # app-tier
    "rtb-yyyyyyyyyyyyyyyyyy" # database-tier
  ]

  project_name  = "my-project"
  environment   = "prod"
  owner_name    = "Your Name"
  instance_type = "t3.micro"

  ssh_allowed_cidrs = ["your-ip/32"]
}
