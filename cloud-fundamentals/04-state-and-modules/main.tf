# The root module: the .tf files in the folder you run Terraform in.
# It calls the bucket module in modules/bucket/ twice, once per environment.
# Each call creates the same kit (a bucket with versioning turned on) from different inputs.
#
# Before the refactor, this file repeated two near-identical pairs of resources, one for dev and one for
# prod. Now the shared part lives once in the module, and each environment is a few lines.
#
# Note: real projects usually give each environment its own root folder and its own state, so a mistake
# in dev cannot touch prod. This lab keeps both in one folder to stay short.

module "site_bucket_dev" {
  source      = "./modules/bucket" # a local path must start with ./ or ../
  environment = "dev"
}

module "site_bucket_prod" {
  source      = "./modules/bucket"
  environment = "prod"
}
