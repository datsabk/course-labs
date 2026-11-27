# The bucket Terraform created.
output "bucket_name" {
  description = "Name of the website bucket"
  value       = aws_s3_bucket.site.bucket
}

# The site's address on LocalStack. LocalStack serves a bucket's website at
#   http://BUCKET.s3-website.localhost.localstack.cloud:4566
# Every name under localhost.localstack.cloud points at LocalStack on your own machine, and the bucket name
# at the front tells LocalStack which bucket's website you want.
# The provider's own website_endpoint attribute names the real AWS host instead
# (BUCKET.s3-website-us-east-1.amazonaws.com), which holds nothing of yours, so the URL is built here.
# On real AWS, use this value instead:
#   "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
output "website_url" {
  description = "Open this address in a browser or with curl"
  value       = "http://${aws_s3_bucket_website_configuration.site.bucket}.s3-website.localhost.localstack.cloud:4566"
}
