variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "my_ip" {
  description = "Your public IP in CIDR format, for example 1.2.3.4/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0)) && var.my_ip != "0.0.0.0/0"
    error_message = "my_ip must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "project_name" {
  description = "Project name used for tags and nginx content"
  type        = string
  default     = "devops-training"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}
