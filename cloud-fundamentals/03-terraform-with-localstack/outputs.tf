# Values Terraform prints at the end of apply, and again whenever you run `terraform output`.
output "bucket_name" {
  description = "The S3 bucket Terraform created in LocalStack"
  value       = aws_s3_bucket.lab.bucket
}

output "queue_url" {
  description = "The URL of the SQS queue, as LocalStack reports it"
  value       = aws_sqs_queue.lab.url
}
