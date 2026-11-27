# The static website: one S3 bucket that serves its files as web pages, exactly as they are stored.
#
# Build order. Terraform works it out from the references between resources (and one depends_on):
#   1. the bucket
#   2. its public access settings
#   3. a bucket policy that lets anyone read the objects (waits for 2)
#   4. the website configuration: which object is the home page and which is the error page
#   5. the two pages from site/, uploaded as objects
# Steps 2, 4 and 5 need only the bucket, so Terraform runs them in parallel once it exists.
# The site's address is the output website_url, in outputs.tf.

# 1. The bucket. On real AWS its name must be unique across every AWS account: see variables.tf.
resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  # Lets terraform destroy delete the bucket even if it still holds files, including ones you uploaded
  # by hand. Handy in a lab; on real data it deletes every object, with no way back.
  force_destroy = true
}

# 2. Block Public Access: four settings that stop a bucket being made public.
# On real AWS all four are on for a new bucket. A website must be publicly readable, so this lab turns off
# the two that concern bucket policies and keeps on the two that concern ACLs (access control lists, an
# older per-object way to grant access that this lab never uses).
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# 3. The bucket policy: everyone ("*") may read (s3:GetObject) every object in the bucket ("/*").
# It allows reading only: nobody else can upload, change or delete anything.
# jsonencode() turns the HCL value below into the JSON text that S3 expects.
# depends_on: on real AWS, S3 rejects a public policy while block_public_policy is still on, so the policy
# must wait until step 2 is applied. Nothing in the policy refers to the public access block, so without
# this line Terraform would not know to wait.
# Note: LocalStack 4.14.0 does not check this policy when it serves the website. Real AWS does, and
# answers 403 Access Denied for objects nobody may read.
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# 4. Website hosting. The index document is served for the site's root address (and for any address
# ending in /); the error document is served, with status 404, for a page that does not exist.
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# 5. The pages. Each file in site/ becomes one object; its key is the name in the URL.
# path.module is the folder that holds this .tf file.
# content_type is stored with the object and sent as the Content-Type header, so the browser shows the
# page as HTML.
# etag = filemd5(...) is the MD5 hash of the file on your disk, a fingerprint of its content. Terraform
# only sees the path in source, not the bytes, so this hash is how it notices an edit: change the file,
# and the next plan updates this object, and only this one.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/site/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/site/index.html")
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "${path.module}/site/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/site/error.html")
}
