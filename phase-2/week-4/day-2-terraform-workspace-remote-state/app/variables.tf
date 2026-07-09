variable "kubeconfig_path" {
  description = "Path to kubeconfig used by the Helm provider."
  type        = string
  default     = "~/.kube/config"
}

variable "aws_region" {
  description = "AWS region of the S3 remote state backend."
  type        = string
  default     = "ap-southeast-1"
}

variable "state_bucket" {
  description = "S3 bucket containing the shared Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  type        = string
}

variable "replicas_by_workspace" {
  description = "Replica count per Terraform workspace."
  type        = map(number)

  default = {
    dev = 2
    stg = 3
  }
}

