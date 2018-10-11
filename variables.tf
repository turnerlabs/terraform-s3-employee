//name of the bucket
variable "bucket_name" {}

//enable versioning
variable "versioning" {
  default = false
}

//bucket access: list of federated assumed role users (e.g., aws-account-devops/me@turner.com). Roles must exist in the target account and are case sensitive.
variable "role_users" {
  type = "list"
}

// bucket and kms key access: list of roles that need access to the bucket
variable "roles" {
  type = "list"
}

//environment tag
variable "tag_environment" {}

//team tag
variable "tag_team" {}

//application tag
variable "tag_application" {}

//contact-email tag
variable "tag_contact-email" {}

//customer tag
variable "tag_customer" {}

//incomplete multipart upload deletion
variable "multipart_delete" {
  default = true
}

variable "multipart_days" {
  default = 3
}
