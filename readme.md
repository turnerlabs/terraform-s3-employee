terraform-s3-employee
======================

A terraform module that creates a tagged S3 bucket with federated assumed role access.

Note that the `role_users` must be valid roles that exist in the same account that the script is run in.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| bucket_name | name of the bucket | string | - | yes |
| role_users | bucket access: list of federated assumed role users (e.g., aws-account-devops/me@turner.com). Roles must exist in the target account and are case sensitive. | list | - | yes |
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

requires terraform >= 0.12

```hcl
provider "aws" {
  profile = "aws-account:aws-account-devops"
}

module "s3_employee" {
  source      = "github.com/turnerlabs/terraform-s3-employee?ref=v1.0.0"
  
  bucket_name = "my-bucket"

  role_users = [
    "aws-account-devops/me@turner.com",
    "aws-account-devops/you@turner.com",
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
