# The module's outputs: the only values the caller can read from inside the module,
# as module.<NAME>.name and module.<NAME>.arn.

output "name" {
  description = "The bucket's name"
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "The bucket's ARN (Amazon Resource Name), the ID that IAM policies use"
  value       = aws_s3_bucket.this.arn
}
