// Configure the AWS Provider
provider "aws" {
  region = var.aws_region_location

   # Make it faster by skipping something
   # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  # skip_requesting_account_id  = true
}

// Validate right Terraform Version
terraform {
  # Specifying a Required Terraform Version # > terraform version # https://developer.hashicorp.com/terraform/tutorials/configuration-language/versions
  required_version = ">= 1.10.0"

  # Specifying Provider Requirements
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81" # https://registry.terraform.io/providers/hashicorp/aws/latest
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.18.0" # https://registry.terraform.io/providers/gavinbunney/kubectl/latest
    }
  }

  # Stores the Terraform state files in a AWS S3 bucket
  # More info read here :: https://developer.hashicorp.com/terraform/language/settings/backends/s3
  # Manualy create this S3 bucket

  # !!! Note !!! A backend block cannot refer to named values (like input variables, locals, or data source attributes). 
  # https://stackoverflow.com/questions/65838989/variables-may-not-be-used-here-during-terraform-init
  # https://brendanthompson.com/posts/2021/10/dynamic-terraform-backend-configuration
  backend "s3" {
    bucket = "terraform-state-warabej793-stg"
    key    = "environment-warabej793-stg/terraform.tfstate"
    region = "us-west-2"
  }
}


