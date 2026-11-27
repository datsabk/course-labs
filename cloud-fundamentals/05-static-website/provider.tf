# Points the Terraform AWS provider at LocalStack instead of real AWS, as in 03-terraform-with-localstack
# and 04-state-and-modules. This lab uses only S3.
#
# Taking the site to real AWS? Delete access_key, secret_key, the three skip_ lines, s3_use_path_style and
# the endpoints block, and give Terraform real credentials from your AWS CLI configuration or environment
# variables, never in this file. Lesson 19 explains the other changes.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0" # pinned: released on 25 Feb 2026, the day before LocalStack 4.14.0, which this lab runs
    }
  }

  # No backend block: state stays in terraform.tfstate in this folder (see 04-state-and-modules).
}

provider "aws" {
  # Dummy credentials. LocalStack accepts any values, so these never leave your laptop.
  # Never put a real access key in this folder.
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Path-style S3 addresses for the API calls: http://localhost:4566/BUCKET instead of http://BUCKET.localhost:4566.
  # This affects only how Terraform talks to the S3 API, not the website address in outputs.tf.
  s3_use_path_style = true

  # Skip three start-up checks that only real AWS can answer.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Send S3 calls to LocalStack's single port.
  endpoints {
    s3 = "http://localhost:4566"
  }
}
