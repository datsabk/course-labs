# Your first Terraform configuration (lesson 16 of Cloud Fundamentals).
# It uses the hashicorp/local provider, which manages files on your own machine,
# so you need no cloud account, no emulator and no network port.
# Run every terraform command from this folder: Terraform reads all the .tf files here together.

# Terraform settings: which Terraform version and which providers this folder needs.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local" # where terraform init downloads it from (the Terraform Registry)
      version = "2.9.1"           # pinned, so everyone gets the same provider version
    }
  }
}

# Provider settings. A cloud provider takes its settings here (the AWS provider, for example,
# takes a region). The local provider has no settings, so its block is empty.
provider "local" {}

# One resource: a text file called hello.txt, written into this folder.
# Its address is local_file.hello (resource type, a dot, then the local name).
resource "local_file" "hello" {
  filename = "hello.txt"
  content  = var.greeting # the value of the input variable declared in variables.tf
}
