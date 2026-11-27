#!/usr/bin/env bash
# list-buckets.sh: lists every bucket in LocalStack, one line per bucket:
# its creation date and time, then its name. No output means there are no buckets.
#
# Like create-bucket.sh, it runs the AWS CLI inside the LocalStack container with dummy credentials.
set -euo pipefail
cd "$(dirname "$0")"   # docker compose looks for this folder's docker-compose.yml

docker compose exec -T \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  localstack \
  aws --endpoint-url=http://localhost:4566 s3 ls
