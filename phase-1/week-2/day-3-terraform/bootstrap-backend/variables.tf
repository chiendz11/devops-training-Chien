variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "owner" {
  description = "Owner name for tags"
  type        = string
  default     = "Bui Anh Chien"
}

variable "project_name" {
  description = "Project tag value"
  type        = string
  default     = "devops-training"
}

variable "bucket_prefix" {
  description = "Prefix for Terraform state S3 bucket"
  type        = string
  default     = "tfstate-chienqt"
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "tfstate-lock"
}
