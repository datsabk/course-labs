# 04-state-and-modules: inside Terraform's state, and a reusable bucket module

Used by lesson 18 of Cloud Fundamentals, **Terraform State and Modules Explained, Hands-On**.

You create two S3 buckets in LocalStack, one for `dev` and one for `prod`, from one reusable module, then look
inside Terraform's state with `terraform state list` and `terraform state show`. Every call goes to
`http://localhost:4566` on your own machine: no AWS account, no credit card, no bill. The provider settings are the
ones from `03-terraform-with-localstack`; what is new is the module and the state commands.

## What is in this folder

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Starts LocalStack, an emulator of AWS APIs, pinned to `localstack/localstack:4.14.0` (the same settings as `03-terraform-with-localstack`) |
| `provider.tf` | The `terraform` block (Terraform 1.5 or newer, `hashicorp/aws` pinned to 6.34.0, no backend block, so state stays local) and the `provider "aws"` block that sends S3 calls to LocalStack |
| `main.tf` | The root module: two `module` blocks, `site_bucket_dev` and `site_bucket_prod`, that call the bucket module with `environment = "dev"` and `environment = "prod"` |
| `outputs.tf` | The outputs `dev_bucket_name` and `prod_bucket_name`, read from each module's `name` output |
| `modules/bucket/main.tf` | The child module's resources: `aws_s3_bucket.this`, named `<project>-<environment>-site`, and `aws_s3_bucket_versioning.this`, which turns versioning on |
| `modules/bucket/variables.tf` | The module's inputs: `environment` (required) and `project` (default `course-labs`) |
| `modules/bucket/outputs.tf` | The module's outputs: `name` and `arn` |
| `.gitignore` | Keeps `.terraform/`, `terraform.tfstate` and `terraform.tfstate.backup` out of Git, because real state files can hold secrets |

## What you need

- Docker with Compose v2 (`docker compose version`) and curl.
- Terraform 1.5 or newer (`terraform version`), and internet access the first time you run `terraform init`.
- Optional: the AWS CLI v2 (`aws --version` prints `aws-cli/2.x`) to see the buckets from outside Terraform.
- A bash shell (on Windows, WSL 2).

## Port

LocalStack listens on port **4566**, published on 127.0.0.1 only, so only your own machine can reach it.
`01-iac-concepts` and `03-terraform-with-localstack` use the same port: if one of them is still running, run
`docker compose down -v` in that folder first.

## Start it

```sh
cd course-labs/cloud-fundamentals/04-state-and-modules
docker compose up -d
docker compose ps
```

You should see the `localstack` service with a status that ends with `(healthy)`. For the first few seconds it says
`(health: starting)`; wait and run `docker compose ps` again.

## Create the buckets

```sh
terraform init
terraform apply -auto-approve
```

`terraform init` now installs the module as well as the provider. You should see these lines among its output:

```text
Initializing modules...
- site_bucket_dev in modules/bucket
- site_bucket_prod in modules/bucket
...
- Installed hashicorp/aws v6.34.0 (signed by HashiCorp)
...
Terraform has been successfully initialized!
```

Each module block gets its own line, even though both use the same folder. `apply` then creates four resources, a
bucket and its versioning setting for each environment, and you should see:

```text
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

dev_bucket_name = "course-labs-dev-site"
prod_bucket_name = "course-labs-prod-site"
```

## Check that it works: read the state

```sh
ls
terraform state list
terraform state show module.site_bucket_dev.aws_s3_bucket.this
```

`ls` should list `terraform.tfstate` next to the `.tf` files: Terraform's record of what it created. You may also
see `terraform.tfstate.backup`, the previous version of the state. `terraform state list` should print four
addresses, one per resource, each starting with the module that created it:

```text
module.site_bucket_dev.aws_s3_bucket.this
module.site_bucket_dev.aws_s3_bucket_versioning.this
module.site_bucket_prod.aws_s3_bucket.this
module.site_bucket_prod.aws_s3_bucket_versioning.this
```

`terraform state show` prints everything the state records about one resource. You should see a block that starts
with `# module.site_bucket_dev.aws_s3_bucket.this:` and includes `bucket = "course-labs-dev-site"`, `force_destroy =
true` and an `arn` of `arn:aws:s3:::course-labs-dev-site`.

To look at the raw file without changing it:

```sh
grep '"module"' terraform.tfstate
```

You should see four lines such as `"module": "module.site_bucket_dev",`, one per resource. Read the file, but never
edit it by hand: use the `terraform state` commands instead.

### Optional: check from outside Terraform

With the AWS CLI installed, in the same terminal:

```sh
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 AWS_PAGER=""
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning --bucket course-labs-dev-site
```

You should see two bucket lines, `course-labs-dev-site` and `course-labs-prod-site`, each after a creation date and
time, and then `"Status": "Enabled"` for the dev bucket's versioning. Without the AWS CLI, use the copy inside the
container, as in `03-terraform-with-localstack`:

```sh
docker compose exec -T -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  localstack aws --endpoint-url=http://localhost:4566 s3 ls
```

## Stop it and clean up

Destroy first, while LocalStack is still running, then stop LocalStack:

```sh
terraform destroy -auto-approve
docker compose down -v
```

You should see `Destroy complete! Resources: 4 destroyed.`, then Compose removing the container. After `destroy`,
`terraform state list` prints nothing: the state file is still there, but it records no resources.

If you stopped LocalStack before `terraform destroy`, the state still lists four resources that are now gone.
Start LocalStack again and run `terraform apply -auto-approve`: the refresh finds them missing and creates them
again. To start completely fresh, delete `.terraform/`, `.terraform.lock.hcl` and the `terraform.tfstate` files,
then run `terraform init` again.

## Troubleshooting

- **`docker compose up` fails with "port is already allocated":** another lab or program uses port 4566. Run
  `docker compose down -v` in the other lab folder, then try again.
- **`terraform apply` fails with "Module not installed":** you skipped `terraform init`, or ran it before a module
  block was added. Run `terraform init` again.
- **`terraform apply` fails with `connection refused`:** LocalStack is not running. Start it, wait for `(healthy)`,
  then apply again.
- **`terraform state list` says "No state file was found!":** you are in another folder, or `apply` has not
  succeeded yet. `cd` into `04-state-and-modules` and check that `apply` printed `Apply complete!`.
- **`terraform state show` says "No instance found for the given address!":** the address has a typo. Copy it
  exactly from the output of `terraform state list`.
- **`terraform apply` fails with an error about the security token or access key:** a call went to real AWS.
  Check that `provider.tf` is unchanged.
- **LocalStack exits right after it starts, and `docker compose logs localstack` mentions credentials or an auth
  token:** the image tag in `docker-compose.yml` was changed. Put back `localstack/localstack:4.14.0`.
