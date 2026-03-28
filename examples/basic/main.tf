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
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  route_table_ids      = ["rtb-xxxxxxxxxxxxxxxxx"]

  project_name  = "my-project"
  environment   = "dev"
  owner_name    = "Your Name"
  instance_type = "t3.micro"
}
