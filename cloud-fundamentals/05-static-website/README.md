# 05-static-website: the capstone, a static website deployed with Terraform

Used by lesson 19 of Cloud Fundamentals, **Capstone: Deploy a Static Website with Terraform**.

You deploy a small static website, two HTML pages, to an S3 bucket in LocalStack, open it with `curl` or a
browser, change a page and deploy again, then remove everything. Every call goes to port 4566 on your own
machine: no AWS account, no credit card, no bill. The provider settings are the ones from
`03-terraform-with-localstack` and `04-state-and-modules`; what is new is website hosting, a public-read bucket
policy and uploading files as objects.

## What is in this folder

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Starts LocalStack, an emulator of AWS APIs, pinned to `localstack/localstack:4.14.0` (the same settings as the earlier labs) |
| `provider.tf` | The `terraform` block (Terraform 1.5 or newer, `hashicorp/aws` pinned to 6.34.0) and the `provider "aws"` block that sends S3 calls to LocalStack |
| `main.tf` | The six resources: the bucket `aws_s3_bucket.site`, its public access settings, the public-read bucket policy, the website configuration (index and error documents) and the two pages as `aws_s3_object` resources |
| `variables.tf` | The input `bucket_name`, default `course-labs-static-site` |
| `outputs.tf` | The outputs `bucket_name` and `website_url`, the address you open |
| `site/index.html` | The home page, with the heading `Hello from LocalStack` |
| `site/error.html` | The page served for an address that does not exist, with the heading `Page not found` |
| `.gitignore` | Keeps `.terraform/` and the state files out of Git |

## What you need

- Docker with Compose v2 (`docker compose version`) and curl (`curl --version`).
- Terraform 1.5 or newer (`terraform version`), and internet access the first time you run `terraform init`.
- A bash shell (on Windows, WSL 2), and a text editor to change `site/index.html`.
- Optional: a web browser on the same machine.

## Port

LocalStack listens on port **4566**, published on 127.0.0.1 only, so only your own machine can reach it. Both
doors of the bucket use this one port: Terraform's S3 API calls go to `http://localhost:4566`, and the website
answers at `http://course-labs-static-site.s3-website.localhost.localstack.cloud:4566`. Every name under
`localhost.localstack.cloud` points at your own machine, and LocalStack reads the bucket name from the front
of the host name.

`01-iac-concepts`, `03-terraform-with-localstack` and `04-state-and-modules` use the same port: if one of them
is still running, run `docker compose down -v` in that folder first.

## Start it

```sh
cd course-labs/cloud-fundamentals/05-static-website
docker compose up -d
docker compose ps
```

You should see the `localstack` service with a status that ends with `(healthy)`. For the first few seconds it says
`(health: starting)`; wait and run `docker compose ps` again.

## Deploy the site

```sh
terraform init
terraform apply -auto-approve
```

`terraform init` downloads the AWS provider. You should see `- Installed hashicorp/aws v6.34.0 (signed by
HashiCorp)` and `Terraform has been successfully initialized!`. `apply` then creates six resources, and you
should see:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "course-labs-static-site"
website_url = "http://course-labs-static-site.s3-website.localhost.localstack.cloud:4566"
```

## Check that it works: open the site

```sh
curl $(terraform output -raw website_url)
```

`terraform output -raw website_url` prints the address without quotes, and `curl` fetches it. You should see the
HTML of `site/index.html`, exactly as it is in the file, including:

```text
  <h1>Hello from LocalStack</h1>
```

You can also paste the `website_url` value into a browser on the same machine: you should see the heading
**Hello from LocalStack**.

Now check the status code and type the website sends, and ask for a page that does not exist:

```sh
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' $(terraform output -raw website_url)
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' $(terraform output -raw website_url)/missing.html
curl $(terraform output -raw website_url)/missing.html
```

You should see `200 text/html` for the home page, `404 text/html` for the missing page, and then the HTML of
`site/error.html`, with `<h1>Page not found</h1>`. The `text/html` comes from `content_type` in `main.tf`.

LocalStack 4.14.0 does not check the bucket policy when it serves the website, so the site would load even
without it. Real AWS does check it: without the policy, the website answers `403` (Access Denied).

## Change a page and deploy again

Open `site/index.html` in a text editor, change the heading, for example to `Hello again from LocalStack`, and
save the file. Then:

```sh
terraform plan
terraform apply -auto-approve
curl $(terraform output -raw website_url)
```

The file's MD5 hash has changed, so the `etag` argument of `aws_s3_object.index` has changed. You should see the
plan say `# aws_s3_object.index will be updated in-place` and `Plan: 0 to add, 1 to change, 0 to destroy.`, then
`Apply complete! Resources: 0 added, 1 changed, 0 destroyed.`, then your new heading from `curl`. The bucket and
`error.html` are untouched. In a browser, refresh the page.

## Stop it and clean up

Destroy first, while LocalStack is still running, then stop LocalStack:

```sh
terraform destroy -auto-approve
docker compose down -v
```

You should see `Destroy complete! Resources: 6 destroyed.`, then Compose removing the container.

If you stopped LocalStack before `terraform destroy`, the state still lists six resources that are now gone. Start
LocalStack again and run `terraform apply -auto-approve`: the refresh finds them missing and creates them again.

## Taking it to real AWS

Only do this with an account you own, a budget alert in place, and a plan to destroy afterwards: storage,
requests and data sent to visitors are billed. In `provider.tf`, delete the dummy keys, the three `skip_`
lines, `s3_use_path_style` and the `endpoints` block, and give Terraform credentials from your AWS CLI
configuration or environment variables. Pass a bucket name nobody else has, with `-var bucket_name=...`, and use
the commented-out `website_endpoint` value in `outputs.tf`. Real S3 website endpoints serve HTTP only; lesson 19
explains how a CloudFront distribution adds HTTPS.

## Troubleshooting

- **`docker compose up` fails with "port is already allocated":** another lab or program uses port 4566. Run
  `docker compose down -v` in the other lab folder, then try again.
- **`terraform apply` fails with `connection refused`:** LocalStack is not running. Start it, wait for `(healthy)`,
  then apply again.
- **`curl` says `Could not resolve host`:** your network's DNS refuses names that point at 127.0.0.1 (some routers
  do this, as protection against "DNS rebinding"). Tell curl the address yourself:
  `curl --resolve course-labs-static-site.s3-website.localhost.localstack.cloud:4566:127.0.0.1 $(terraform output -raw website_url)`.
  A browser needs a different DNS server, or a line `127.0.0.1 course-labs-static-site.s3-website.localhost.localstack.cloud`
  in your hosts file.
- **`curl` shows a LocalStack page titled `404 Not Found` instead of your page:** the bucket or its website
  configuration does not exist yet, for example because `apply` failed or LocalStack was restarted. Run
  `terraform apply -auto-approve` again.
- **`terraform output` prints a warning or an error instead of an address:** you are in another folder, or
  `apply` has not succeeded yet. `cd` into `05-static-website` and check that `apply` printed `Apply complete!`.
- **After editing a page, the plan says `No changes`:** the file was not saved, or you edited a copy outside
  `site/`. Save `site/index.html` and run `terraform plan` again.
- **`terraform apply` fails with an error about the security token or access key:** a call went to real AWS.
  Check that `provider.tf` is unchanged.
- **LocalStack exits right after it starts, and `docker compose logs localstack` mentions credentials or an auth
  token:** the image tag in `docker-compose.yml` was changed. Put back `localstack/localstack:4.14.0`.
