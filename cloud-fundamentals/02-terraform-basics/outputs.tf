# An output: a value Terraform prints at the end of apply, and again whenever you run `terraform output`.
output "file_path" {
  description = "The file Terraform manages"
  value       = local_file.hello.filename # a reference: <resource type>.<local name>.<attribute>
}
