terraform {
    required_version = ">=1.6.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

module "s3" {
    source = "./modules/s3"
    bucket_name = var.bucket_name
    environment = var.environment
    transition_days = 30
}