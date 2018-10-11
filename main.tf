/**
 * A terraform module that creates a tagged S3 bucket with federated assumed role access and default kms key encryption.

 *Note that the `role_users` and `roles` must be valid roles that exist in the same account that the script is run in.
 */

resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.bucket_name}"
  force_destroy = "true"

  versioning {
    enabled = "${var.versioning}"
  }

  tags {
    team          = "${var.tag_team}"
    application   = "${var.tag_application}"
    environment   = "${var.tag_environment}"
    contact-email = "${var.tag_contact-email}"
    customer      = "${var.tag_customer}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
      }
    }
  }

  lifecycle_rule {
    id                                     = "auto-delete-incomplete-after-x-days"
    prefix                                 = ""
    enabled                                = "${var.multipart_delete}"
    abort_incomplete_multipart_upload_days = "${var.multipart_days}"
  }
}

resource "aws_kms_key" "bucket_key" {
  policy = "${data.template_file.key_policy.rendered}"
  
  tags {
    team          = "${var.tag_team}"
    application   = "${var.tag_application}"
    environment   = "${var.tag_environment}"
    contact-email = "${var.tag_contact-email}"
    customer      = "${var.tag_customer}"
  }
}

resource "aws_kms_alias" "bucket_key_alias" {
  name          = "alias/${var.bucket_name}-key"
  target_key_id = "${aws_kms_key.bucket_key.key_id}"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.template_file.bucket_policy.rendered}"
}

data "aws_caller_identity" "current" {}

//render dynamic list of users for s3
data "template_file" "s3_user_principal" {
  count    = "${length(var.role_users)}"
  template = "arn:aws:sts::$${account}:assumed-role/$${user}"

  vars {
    account = "${data.aws_caller_identity.current.account_id}"
    user    = "${var.role_users[count.index]}"
  }
}

//render dynamic list of roles for s3
data "template_file" "s3_role_principal" {
  count    = "${length(var.roles)}"
  template = "arn:aws:sts::$${account}:assumed-role/$${role}/*"

  vars {
    account = "${data.aws_caller_identity.current.account_id}"
    role    = "${var.roles[count.index]}"
  }
}

//render dynamic list of role for kms
data "template_file" "kms_role_principal" {
  count    = "${length(var.roles)}"
  template = "arn:aws:iam::$${account}:role/$${role}"

  vars {
    account = "${data.aws_caller_identity.current.account_id}"
    role    = "${var.roles[count.index]}"
  }
}

//render KMS key policy including dynamic principals
data "template_file" "key_policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::558224608801:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow roles to encrypt and decrypt",
      "Effect": "Allow",
      "Principal": { "AWS": $${principals} },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Resource": "*" 
    }
  ]
}
EOF

  vars {
    principals = "${jsonencode(data.template_file.kms_role_principal.*.rendered)}"
  }
}

//render bucket policy including dynamic principals
data "template_file" "bucket_policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [    
    {
      "Sid": "DenyWriteToAllExceptRoleUsers",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [ 
        "s3:GetObject",
        "s3:Delete*",
        "s3:Put*",
        "s3:Replicate*",
        "s3:Restore*"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ],
      "Condition": {
        "StringNotLike": {
          "aws:arn": $${principals}
        }
      }
    },
    {
      "Sid": "AllowRoleUsersToRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [         
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ],
      "Condition": {
        "StringLike": {
          "aws:arn": $${principals}
        }
      }      
    },    
    {
      "Sid": "AllowSamlAccountUsersToReadTagsAndAcl",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [         
        "s3:GetBucketTagging",
        "s3:GetBucketAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ],
      "Condition": {
        "StringLike": {
          "aws:arn": "arn:aws:sts::${data.aws_caller_identity.current.account_id}:*"
        }
      }      
    }
  ]
}
EOF

  vars {
    principals = "${jsonencode(concat(data.template_file.s3_user_principal.*.rendered, data.template_file.s3_role_principal.*.rendered))}"
  }
}


