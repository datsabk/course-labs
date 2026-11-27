#!/usr/bin/env bash
# create-bucket.sh: an IMPERATIVE script. It runs one step, "create a bucket", every time you run it.
# It never checks what already exists, so two runs leave you with two buckets.
# Lessons 16 to 19 of the course replace it with Terraform, where a second run changes nothing.
#
# It runs the AWS CLI that ships inside the LocalStack container, so this lab needs only Docker.
# The credentials are dummy values: LocalStack accepts any. Never put a real access key here.
set -euo pipefail
cd "$(dirname "$0")"   # docker compose looks for this folder's docker-compose.yml

# Bucket names must be unique, so the script makes up a new one on every run:
# the date and time (UTC) plus a random number, for example iac-demo-20261127-101530-4821
bucket="iac-demo-$(date -u +%Y%m%d-%H%M%S)-$RANDOM"

docker compose exec -T \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  localstack \
  aws --endpoint-url=http://localhost:4566 s3 mb "s3://$bucket"
