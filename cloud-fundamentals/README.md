# Cloud Fundamentals: labs

These are the hands-on labs for the free course
[Cloud Fundamentals](https://abhishekkothari.in/courses/cloud-fundamentals/index.html).
They go with the course's last section, Infrastructure as Code. You start with a plain shell script and see why
clicking or scripting by hand is hard to repeat. Then you write your first Terraform, point Terraform at
[LocalStack](https://www.localstack.cloud/) (an emulator of AWS APIs that runs in a container on your laptop),
learn how state and modules work, and finish by deploying a static website to an S3 bucket. Each folder belongs
to one or more lessons, and the lessons tell you which folder to open and what to try.

Everything runs on your own machine. You do not need an AWS, Azure or Google Cloud account, a credit card or any
paid service, and nothing you do here costs money.

## What you need

| Tool | Why | Check that it is installed |
| --- | --- | --- |
| A terminal and git | To get the labs and run the commands | `git --version` |
| Docker (Docker Desktop on macOS or Windows, Docker Engine on Linux) | Runs LocalStack in a container | `docker --version`, then `docker info` to check the daemon is running |
| Docker Compose v2 (the `docker compose` plugin) | Starts LocalStack from each lab's `docker-compose.yml` | `docker compose version` (expect v2.x) |
| Terraform 1.5 or newer | Every lab from `02-terraform-basics` onwards | `terraform version` |
| AWS CLI v2 | To check what Terraform created in LocalStack, with `--endpoint-url=http://localhost:4566` | `aws --version` (expect `aws-cli/2.x`) |
| curl | To check that LocalStack is healthy and to fetch the website you deploy | `curl --version` |
| A bash shell | For the helper scripts such as `create-bucket.sh` (on Windows, use WSL 2) | `bash --version` |

Install Terraform from HashiCorp's install page (https://developer.hashicorp.com/terraform/install) and the AWS CLI
from its user guide. Both are free. The AWS CLI does not need a real AWS account here: the labs give it dummy
credentials and send every call to LocalStack.

Machine resources: LocalStack is light. Give Docker at least 2 GB of memory and keep about 3 GB of disk free for
the image. The first `docker compose up` downloads it, which takes a few minutes; later starts are quick.

## Getting the labs

```sh
git clone https://github.com/datsabk/course-labs.git
cd course-labs/cloud-fundamentals
ls
```

You should see the numbered lab folders listed below. You can also browse them on GitHub:
https://github.com/datsabk/course-labs/tree/main/cloud-fundamentals

## The lab folders

Folders are shared: one or more lessons use the same folder, and each lab builds on what the earlier ones taught,
so do them in order.

| Folder | What you build there | Lessons that use it |
| --- | --- | --- |
| `01-iac-concepts/` | LocalStack in Docker Compose and a small imperative script that creates a bucket every time it runs, so you can see why declarative infrastructure as code is safer to re-run | 15. Infrastructure as Code Explained for Beginners |
| `02-terraform-basics/` | Your first Terraform configuration: a `resource` block, a variable, an output and a reference between two resources, the `init`, `plan`, `apply` and `destroy` workflow, and a second `apply` that changes nothing. It writes a text file on your machine with the `hashicorp/local` provider, so it needs Terraform only, not Docker | 16. Terraform Basics: Your First Infrastructure as Code |
| `03-terraform-with-localstack/` | The Terraform AWS provider pointed at LocalStack (dummy credentials, the `endpoints` block, path-style S3), creating an S3 bucket and an SQS queue and checking them with the AWS CLI | 17. Run Terraform Locally with LocalStack, Hands-On |
| `04-state-and-modules/` | A look inside `terraform.tfstate` with `terraform state list` and `terraform state show`, and a repeated bucket definition refactored into a reusable module in `modules/bucket/`, called twice from the root module for a `dev` and a `prod` bucket in LocalStack | 18. Terraform State and Modules Explained, Hands-On |
| `05-static-website/` | The capstone: an S3 bucket configured for website hosting, a public-read bucket policy, `index.html` and `error.html` uploaded as objects, and an output with the site URL you open with `curl` | 19. Capstone: Deploy a Static Website with Terraform |

The lessons are at https://abhishekkothari.in/courses/cloud-fundamentals/index.html. Lessons 1 to 14 explain the
cloud itself (regions, compute, storage, networking, databases, IAM and cost) and need no lab.

## How the labs work

Every lab folder has its own `README.md`. It tells you how to start the lab, what you should see when it works, and
how to stop it and clean up. For a lab that runs LocalStack, the usual loop is:

```sh
cd 03-terraform-with-localstack            # the folder the lesson names
docker compose up -d                       # start LocalStack in the background
docker compose ps                          # the localstack service should be running (healthy)
curl http://localhost:4566/_localstack/health   # lists the emulated services and their state
terraform init                             # download the providers the lab uses
terraform apply                            # read the plan, then type yes
terraform destroy                          # remove what you created
docker compose down -v                     # stop LocalStack and delete its container, network and volumes
```

Some things to know:

- **One lab at a time.** The labs that run LocalStack all use port 4566, so run `docker compose down -v` in one lab
  folder before you start the next. If `up` fails with "port is already allocated", another lab or program is
  still using that port. If a lab's README says it reuses the LocalStack of an earlier lab instead of starting its
  own, keep that one running.
- **Localhost only.** Every published port listens on 127.0.0.1 only, so LocalStack is reachable from your own
  machine and not from your network. Open it as `http://localhost:4566`.
- **LocalStack is pinned to 4.14.0.** Since March 2026, newer LocalStack images (`latest` and the `2026.x` versions)
  need a LocalStack account and an auth token to start. Version 4.14.0 is the last release that starts without one,
  so the labs use `localstack/localstack:4.14.0`. It no longer gets updates, which is one more reason its port listens
  on 127.0.0.1 only. Keep the tag as it is in each lab's `docker-compose.yml`.
- **Dummy credentials only.** LocalStack accepts any credentials, so the labs use the dummy value `test` for the
  access key and the secret key. Each lab's README shows the exact values to set for the AWS CLI. Never put a real
  access key in these folders.
- **State stays in the folder.** Terraform writes `terraform.tfstate` and a `.terraform/` folder next to the lab's
  `.tf` files. They are local and git-ignored. Delete them, or run `terraform destroy`, to start a lab again from
  scratch. `docker compose down -v` also wipes everything LocalStack was holding, so after it, Terraform's state no
  longer matches and the next `apply` creates everything again.
- **An emulator, not the real cloud.** LocalStack behaves like AWS for everything these labs use, but not every
  feature behaves identically. Treat it as a fast, free feedback loop. The capstone lesson explains what changes
  when you take the same code to a real AWS account.

## Troubleshooting

- **`docker compose ps` shows LocalStack restarting or exited:** run `docker compose logs localstack`. The last lines
  say why it stopped, for example a port clash or a message about the image or licence. Check that you are using the
  image and settings in the lab's `docker-compose.yml`, unchanged.
- **Terraform says it cannot connect, or times out on `localhost:4566`:** LocalStack is not up yet. Wait until
  `curl http://localhost:4566/_localstack/health` answers, then run the command again.
- **The AWS CLI asks for credentials or says "Unable to locate credentials":** set the dummy values from the lab's
  README in that terminal, and add `--endpoint-url=http://localhost:4566` to every `aws` command.
- **`terraform init` fails to download providers:** it needs internet access once to fetch the providers from the
  Terraform Registry. Later runs use the cached copy in `.terraform/`.
