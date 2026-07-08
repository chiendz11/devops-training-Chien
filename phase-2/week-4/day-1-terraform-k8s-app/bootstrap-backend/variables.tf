variable "region" {
  description = "AWS region for the backend resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket used for Terraform remote state."
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  type        = string
}

variable "owner" {
  description = "Owner tag for lab resources."
  type        = string
  default     = "Bui Anh Chien"
}

