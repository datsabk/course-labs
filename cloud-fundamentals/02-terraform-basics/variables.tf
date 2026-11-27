# An input variable: a value you can change without editing main.tf.
# main.tf reads it as var.greeting. To use another value for one command, pass -var, for example:
#   terraform plan -var 'greeting=Hi from Terraform'
# (no spaces around the = sign, and single quotes in bash so the spaces in the value survive).
variable "greeting" {
  description = "The text Terraform writes into hello.txt"
  type        = string
  default     = "Hello from Terraform"
}
