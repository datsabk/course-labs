# 02-terraform-basics: your first Terraform configuration

Used by lesson 16 of Cloud Fundamentals, **Terraform Basics: Your First Infrastructure as Code**.

Nothing here touches a cloud. The configuration uses the `hashicorp/local` provider, which manages files on your
own machine, so the one resource Terraform creates is a text file, `hello.txt`, in this folder. That is enough to
learn the whole workflow: `terraform init`, `terraform plan`, `terraform apply`, a second `apply` that changes
nothing, and `terraform destroy`. The next lab, `03-terraform-with-localstack`, uses the same workflow with AWS
resources in LocalStack.

## What is in this folder

| File | What it does |
| --- | --- |
| `main.tf` | The `terraform` block (Terraform 1.5 or newer, `hashicorp/local` pinned to 2.9.1), an empty `provider "local"` block and one resource, `local_file.hello`, which writes `hello.txt` |
| `variables.tf` | The input variable `greeting`: the text that goes into `hello.txt` (default `Hello from Terraform`) |
| `outputs.tf` | The output `file_path`, which Terraform prints after `apply` |
| `extras/receipt.tf` | An optional second resource, `local_file.receipt`, that uses an attribute of the first one. Terraform ignores it until you copy it into this folder |
| `.gitignore` | Keeps Terraform's working files (`.terraform/`, `terraform.tfstate`) and the files it creates out of Git |

## What you need

Terraform 1.5 or newer (`terraform version` prints it) and an internet connection the first time you run
`terraform init`, which downloads the provider from the Terraform Registry. You do not need Docker, the AWS CLI or
any account for this lab.

## Port

This lab uses no network port: Terraform only writes files in this folder. LocalStack and its port 4566 come back in
`03-terraform-with-localstack`.

## Start it

```sh
cd course-labs/cloud-fundamentals/02-terraform-basics
terraform init
```

You should see `- Installed hashicorp/local v2.9.1 (signed by HashiCorp)` and then
`Terraform has been successfully initialized!`. Init creates a `.terraform/` folder (the downloaded provider) and a
`.terraform.lock.hcl` file (the exact provider version it chose, with checksums). You run it once per folder, and
again only when you add a provider.

## Check that it works

Preview the change, which creates nothing yet:

```sh
terraform plan
```

You should see `# local_file.hello will be created`, a block of lines starting with `+`, and the summary
`Plan: 1 to add, 0 to change, 0 to destroy.`

Make it so, then look at the file:

```sh
terraform apply -auto-approve
cat hello.txt
```

You should see `local_file.hello: Creation complete after 0s`, then
`Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` and the output `file_path = "hello.txt"`. `cat`
prints `Hello from Terraform`. The file has no line break at the end, so your prompt may appear right after the
text. Without `-auto-approve`, `apply` shows the plan and waits for you to type `yes`.

Apply again, without changing anything:

```sh
terraform apply -auto-approve
```

You should see `local_file.hello: Refreshing state...`, then
`No changes. Your infrastructure matches the configuration.` and
`Apply complete! Resources: 0 added, 0 changed, 0 destroyed.` Applying the same code twice changes nothing.

## Read a replacement plan

Ask what would happen with a different greeting. This is only a plan, so `hello.txt` stays as it is:

```sh
terraform plan -var 'greeting=Hi from Terraform'
```

You should see `# local_file.hello must be replaced`, a line starting with `-/+ resource "local_file" "hello"`, the
`content` line ending in `# forces replacement`, and `Plan: 1 to add, 0 to change, 1 to destroy.` The local
provider cannot edit a file in place: every argument of `local_file` forces a replacement, so a new value means
"delete the old file, write a new one".

## Optional: a reference between resources

Copy the second resource into the folder and apply:

```sh
cp extras/receipt.tf .
terraform apply -auto-approve
cat receipt.txt
```

You should see `# local_file.receipt will be created`, `Plan: 1 to add, 0 to change, 0 to destroy.` and then
`Apply complete! Resources: 1 added, 0 changed, 0 destroyed.` `receipt.txt` holds `hello.txt has SHA-256 ` followed
by 64 hexadecimal characters. To check the hash, run `sha256sum hello.txt` (Linux or WSL) or
`shasum -a 256 hello.txt` (macOS): it prints the same 64 characters.

## Stop it and clean up

```sh
terraform destroy -auto-approve
rm -f receipt.tf
```

You should see `Destroy complete! Resources: 1 destroyed.`, or `2 destroyed.` if you copied `receipt.tf`, and
`hello.txt` (and `receipt.txt`) are gone. Removing the copy of `receipt.tf` puts the folder back to its starting
point. To start completely fresh, also delete `.terraform/`, `.terraform.lock.hcl` and the `terraform.tfstate`
files, then run `terraform init` again.

## Troubleshooting

- **`terraform: command not found`:** Terraform is not installed or not on your `PATH`. Install it from
  https://developer.hashicorp.com/terraform/install, open a new terminal and check with `terraform version`.
- **`plan` or `apply` fails and tells you to run `terraform init`:** you skipped `init`, or ran it in another folder.
  Run `terraform init` in this folder.
- **`terraform init` cannot download the provider:** it needs internet access to reach the Terraform Registry once.
  Later runs use the copy in `.terraform/`.
- **The second `apply` creates `hello.txt` again:** the file was deleted or edited by hand. Each plan, the local
  provider checks the file on disk; a missing file, or one whose content differs from what Terraform wrote, counts as
  gone, so Terraform writes it again. That is drift being put right.
- **`-var` gives an error:** put no spaces around the `=` sign, and use single quotes in bash, as shown above.
- **A fresh start shows `Plan: 2 to add`:** the copy of `receipt.tf` is still in the folder. Delete it with
  `rm receipt.tf` if you want only `hello.txt`.
