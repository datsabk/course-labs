# Optional step of lesson 16: a second resource that uses an attribute of the first one.
# Terraform reads only the .tf files directly in the folder you run it from, so it ignores
# this file while it sits in extras/. To use it, run this from the 02-terraform-basics folder:
#   cp extras/receipt.tf .
# To get back to the starting point later, delete the copy:  rm receipt.tf
resource "local_file" "receipt" {
  filename = "receipt.txt"

  # local_file.hello.content_sha256 is the SHA-256 hash of hello.txt's content, which the
  # provider works out when it writes the file. Using it here is a reference: it passes the
  # value along and tells Terraform to create hello.txt before receipt.txt.
  content = "hello.txt has SHA-256 ${local_file.hello.content_sha256}"
}
