# The bucket module: a reusable kit for one S3 bucket with versioning turned on.
# A module is just a folder of .tf files. This one follows the usual layout:
#   main.tf       the resources (this file)
#   variables.tf  the inputs the caller sets
#   outputs.tf    the values the caller can read back
#
# Inside a module, resources are often named "this" when the module manages one main thing.
# The full address adds the caller's module name in front, for example
#   module.site_bucket_dev.aws_s3_bucket.this

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0" # a minimum only: the root module pins the exact version
    }
  }
}

# One bucket, named from the inputs, for example course-labs-dev-site.
resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.environment}-site"

  # Lets terraform destroy delete the bucket even if it holds files (and older versions of them).
  # Handy in a lab; on real data it deletes every object, with no way back.
  force_destroy = true
}

# Versioning keeps the older copies of each object when it is overwritten or deleted.
# Putting it in the module means no environment can forget it.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
