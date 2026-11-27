# Points the Terraform AWS provider at LocalStack instead of real AWS, as in 03-terraform-with-localstack.
# The root module's provider settings are passed down to the child modules it calls, so the bucket module
# in modules/bucket/ has no provider block of its own.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0" # pinned: released on 25 Feb 2026, the day before LocalStack 4.14.0, which this lab runs
    }
  }

  # No backend block: Terraform uses the default local backend and writes its state to
  # terraform.tfstate in this folder. Lesson 18 shows what a shared S3 backend looks like.
}

provider "aws" {
  # Dummy credentials. LocalStack accepts any values, so these never leave your laptop.
  # Never put a real access key in this folder.
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Path-style S3 addresses: http://localhost:4566/BUCKET instead of http://BUCKET.localhost:4566.
  s3_use_path_style = true

  # Skip three start-up checks that only real AWS can answer.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Send S3 calls to LocalStack's single port. This lab uses only S3.
  endpoints {
    s3 = "http://localhost:4566"
  }
}
