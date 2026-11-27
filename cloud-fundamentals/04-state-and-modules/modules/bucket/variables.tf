# The module's inputs. The caller sets them as arguments in its module block.
# An input with no default is required: Terraform stops with an error if the caller leaves it out.

variable "environment" {
  description = "The environment the bucket belongs to, such as dev or prod"
  type        = string
}

variable "project" {
  description = "A short project name, used at the start of the bucket name"
  type        = string
  default     = "course-labs"
}
