# Two AWS resources, created in LocalStack through the settings in provider.tf.
# Nothing in this file mentions LocalStack: the same code would work against a real AWS account.

# An S3 bucket: object storage, from lesson 6.
resource "aws_s3_bucket" "lab" {
  bucket = "course-labs-demo-bucket"

  # Lets terraform destroy delete the bucket even if you uploaded files into it.
  # Handy in a lab; on real data it deletes every object, with no way back.
  force_destroy = true
}

# An SQS queue: it holds messages until a worker takes them, from lesson 9.
resource "aws_sqs_queue" "lab" {
  name = "course-labs-demo-queue"
}
