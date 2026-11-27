# 03-terraform-with-localstack: Terraform against an emulated AWS

Used by lesson 17 of Cloud Fundamentals, **Run Terraform Locally with LocalStack, Hands-On**.

You start LocalStack, point the Terraform AWS provider at it, create an S3 bucket and an SQS queue, and check
them with the AWS CLI. Every call goes to `http://localhost:4566` on your own machine: no AWS account, no credit
card, no bill. The workflow is the one from `02-terraform-basics` (`init`, `plan`, `apply`, `destroy`); what is new
is the provider and where its calls go.

## What is in this folder

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Starts LocalStack, an emulator of AWS APIs, pinned to `localstack/localstack:4.14.0` (the same settings as `01-iac-concepts`) |
| `provider.tf` | The `terraform` block (Terraform 1.5 or newer, `hashicorp/aws` pinned to 6.34.0) and the `provider "aws"` block that sends every call to LocalStack: dummy credentials, `s3_use_path_style`, three `skip_` settings and the `endpoints` block |
| `main.tf` | Two resources: the S3 bucket `course-labs-demo-bucket` and the SQS queue `course-labs-demo-queue`. Nothing in it mentions LocalStack |
| `outputs.tf` | The outputs `bucket_name` and `queue_url`, which Terraform prints after `apply` |
| `.gitignore` | Keeps Terraform's working files (`.terraform/`, `terraform.tfstate`) out of Git |

## What you need

- Docker with Compose v2 (`docker compose version`) and curl.
- Terraform 1.5 or newer (`terraform version`), and internet access the first time you run `terraform init`, which
  downloads the AWS provider from the Terraform Registry. It is a much bigger download than the local provider of
  the last lab, so give it a minute.
- The AWS CLI v2 (`aws --version` prints `aws-cli/2.x`) to check the results. No AWS CLI? See "Without the AWS CLI"
  below.
- A bash shell (on Windows, WSL 2).

## Port

LocalStack listens on port **4566**, published on 127.0.0.1 only, so only your own machine can reach it. Every
emulated service (S3, SQS and the rest) answers on that one port. `01-iac-concepts` uses the same port: if it is
still running, run `docker compose down -v` in that folder first.

## Why these versions

- **LocalStack 4.14.0.** Since March 2026, newer LocalStack images (`latest` and the `2026.x` versions) need a
  LocalStack account and an auth token to start. Version 4.14.0 is the last release that starts without one. It no
  longer gets updates, which is one more reason its port listens on 127.0.0.1 only. Keep the tag as it is.
- **AWS provider 6.34.0.** It was released on 25 February 2026, the day before LocalStack 4.14.0. Because
  LocalStack 4.14.0 no longer changes, a provider of the same age is the safest match. Keep the pin as it is.

## Start it

```sh
cd course-labs/cloud-fundamentals/03-terraform-with-localstack
docker compose up -d
```

The first run downloads the LocalStack image, which can take a few minutes. Later starts are quick.

## Check that it works

```sh
docker compose ps
curl http://localhost:4566/_localstack/health
```

You should see the `localstack` service with a status that ends with `(healthy)`, for example
`Up 30 seconds (healthy)`. For the first few seconds it says `(health: starting)`; wait and run it again. `curl`
prints a JSON document whose `"services"` part lists every emulated service and its state. You should see `"s3"` and
`"sqs"` marked `"available"` (or `"running"` once something has used them).

## Create the bucket and the queue

```sh
terraform init
terraform apply -auto-approve
```

`terraform init` should end with `- Installed hashicorp/aws v6.34.0 (signed by HashiCorp)` and
`Terraform has been successfully initialized!`.

During `apply` you should see `aws_s3_bucket.lab: Creation complete` within a few seconds. The queue takes longer,
about half a minute, with `aws_sqs_queue.lab: Still creating...` lines in between: after creating it, the provider
re-reads the queue's settings until they come back the same six times in a row, at least five seconds apart, even
on LocalStack. Then you should see:

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "course-labs-demo-bucket"
queue_url = "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/course-labs-demo-queue"
```

`000000000000` is LocalStack's default account ID, and `localhost.localstack.cloud` is a host name that points back
at your own machine.

## Check with the AWS CLI

Give the AWS CLI the same dummy credentials and region, in the terminal you will use, and turn off its pager (by
default the CLI v2 shows JSON output in `less`):

```sh
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 sqs list-queues
```

You should see one line for the bucket, a creation date and time followed by its name, for example (illustrative)
`2026-11-27 10:20:05 course-labs-demo-bucket`, and then:

```json
{
    "QueueUrls": [
        "http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/course-labs-demo-queue"
    ]
}
```

Every `aws` command needs `--endpoint-url=http://localhost:4566`. Without it, the CLI sends the call to real AWS,
which rejects the dummy keys.

### Without the AWS CLI

The LocalStack container has an AWS CLI of its own. Run it from this folder:

```sh
docker compose exec -T -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  localstack aws --endpoint-url=http://localhost:4566 s3 ls
```

You should see the same bucket line. Replace `s3 ls` with `sqs list-queues` to see the queue.

## Stop it and clean up

Destroy first, while LocalStack is still running, then stop LocalStack:

```sh
terraform destroy -auto-approve
docker compose down -v
```

You should see `Destroy complete! Resources: 2 destroyed.`, then Compose removing the container. The lab does not
turn on LocalStack's persistence, so `docker compose down -v` (or any restart) empties LocalStack.

If you stopped LocalStack before `terraform destroy`, the state file still lists a bucket and a queue that are now
gone. That is fine: start LocalStack again and run `terraform apply -auto-approve`. The refresh finds both missing,
so the plan creates them again. To start completely fresh instead, delete `.terraform/`, `.terraform.lock.hcl` and the
`terraform.tfstate` files, then run `terraform init` again.

## Troubleshooting

- **`docker compose up` fails with "port is already allocated":** another lab or program uses port 4566. Run
  `docker compose down -v` in the other lab folder, or stop the other program, then try again.
- **"Cannot connect to the Docker daemon":** Docker is not running. Start Docker Desktop (or the Docker service on
  Linux) and wait until `docker info` works.
- **`curl` says "Connection refused" or "Empty reply from server":** LocalStack is not up yet, or not started in this
  folder. Run `docker compose ps`, and wait for `(healthy)`.
- **`terraform apply` fails, or sits at `Creating...` for a long time, with `connection refused` in the error:**
  LocalStack is not running. Start it, wait for `(healthy)`, then apply again.
- **`terraform apply` fails with an error about the security token or access key:** a call went to real AWS. Check
  that `provider.tf` is unchanged and that every service you use has a line in the `endpoints` block.
- **"Unable to locate credentials" from the AWS CLI:** the `export` line was not run in this terminal. Run it again.
- **The AWS CLI answers about an invalid access key:** you left out `--endpoint-url=http://localhost:4566`.
- **`aws s3 ls` prints nothing:** LocalStack was restarted since the last `apply` and started empty. Run
  `terraform apply -auto-approve` again: the refresh notices the bucket and the queue are gone and creates them.
- **LocalStack exits right after it starts, and `docker compose logs localstack` mentions credentials or an auth
  token:** the image tag in `docker-compose.yml` was changed to a newer version. Put back `localstack/localstack:4.14.0`.
