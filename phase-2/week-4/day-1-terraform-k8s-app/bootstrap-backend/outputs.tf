output "bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tf_lock.name
}

