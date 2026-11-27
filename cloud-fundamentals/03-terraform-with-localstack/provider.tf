# Points the Terraform AWS provider at LocalStack instead of real AWS (lesson 17 of Cloud Fundamentals).
# Everything AWS-specific about "where do the calls go" lives in this one file. main.tf, with the
# resources, would look the same for a real AWS account.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0" # pinned: released on 25 Feb 2026, the day before LocalStack 4.14.0, which this lab runs
    }
  }
}

provider "aws" {
  # Dummy credentials. LocalStack accepts any values, so these never leave your laptop.
  # Never put a real access key in this folder.
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Path-style S3 addresses: http://localhost:4566/BUCKET instead of http://BUCKET.localhost:4566,
  # so the bucket name never has to be looked up as a host name.
  s3_use_path_style = true

  # Skip three start-up checks that only real AWS can answer:
  skip_credentials_validation = true # do not check the keys with the STS API
  skip_metadata_api_check     = true # do not look for credentials on an EC2 metadata service
  skip_requesting_account_id  = true # do not ask AWS for the account ID

  # Send each service's API calls to LocalStack's single port.
  # A service you use but leave out of this list would be sent to real AWS,
  # which rejects the dummy keys.
  endpoints {
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
  }
}
