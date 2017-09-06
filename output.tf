//the arn of the bucket that was created
output "bucket_arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}
