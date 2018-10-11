terraform-s3-employee
======================

A terraform module that creates a tagged S3 bucket with federated assumed role access using KMS key encryption by default.

Note that the `role_users` and `roles` must be valid roles that exist in the same account that the script is run in.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bucket_name | name of the bucket | string | - | yes |
| role_users | bucket access: list of federated assumed role users (e.g., aws-account-devops/me@turner.com). Roles must exist in the target account and are case sensitive. | list | - | yes |
| roles | bucket and kms key access: list roles that have access to encrypt and decrypt bucket content (e.g., aws-account-devops). Roles must exist in the target account and are case sensitive. | list | - | yes |
| tag_application | application tag | string | - | yes |
| tag_contact-email | contact-email tag | string | - | yes |
| tag_customer | customer tag | string | - | yes |
| tag_environment | environment tag | string | - | yes |
| tag_team | team tag | string | - | yes |
| versioning | enable versioning | string | `false` | no |
| multipart_delete | enable incomplete multipart upload deletion | string | `true` | no |
| multipart_days | incomplete multipart upload deletion days | string | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_arn | the arn of the bucket that was created |


### usage example

```hcl
provider "aws" {
  profile = "aws-account:aws-account-devops"
}

module "s3_employee" {
  source      = "github.com/turnerlabs/terraform-s3-employee?ref=v0.2.0"
  
  bucket_name = "my-bucket"

  role_users = [
    "aws-account-devops/me@turner.com",
    "aws-account-devops/you@turner.com",
  ]

  roles = [
    "dev-my-task-role",
    "qa-my-task-role",
  ]

  tag_team          = "my-team"
  tag_contact-email = "my-team@turner.com"
  tag_application   = "my-app"
  tag_environment   = "dev"
  tag_customer      = "my-customer"
}
```

```
terraform init
terraform plan
terraform apply
```
