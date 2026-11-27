# The root module reads each module's outputs as module.<NAME>.<OUTPUT> and prints them after apply,
# and again whenever you run `terraform output`.
output "dev_bucket_name" {
  description = "The dev bucket, created by module.site_bucket_dev"
  value       = module.site_bucket_dev.name
}

output "prod_bucket_name" {
  description = "The prod bucket, created by module.site_bucket_prod"
  value       = module.site_bucket_prod.name
}
