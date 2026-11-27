# The one input of this lab: the bucket's name.
# LocalStack accepts any valid bucket name. On real AWS a bucket name must be unique across every AWS
# account, so pass one of your own, for example:
#   terraform apply -var bucket_name=static-site-yourname-20261127
variable "bucket_name" {
  description = "Name of the S3 bucket that holds the website"
  type        = string
  default     = "course-labs-static-site"
}
