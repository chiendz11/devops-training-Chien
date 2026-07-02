output "tfstate_bucket" {
  description = "S3 bucket name for Terraform remote state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "backend_config_example" {
  description = "Backend config example for 2-aws/backend.tf"
  value       = <<EOT
terraform {
  backend "s3" {
    bucket         = "${aws_s3_bucket.tfstate.bucket}"
    key            = "phase1/week2/day3.tfstate"
    region         = "${var.region}"
    dynamodb_table = "${aws_dynamodb_table.tfstate_lock.name}"
    encrypt        = true
  }
}
EOT
}
