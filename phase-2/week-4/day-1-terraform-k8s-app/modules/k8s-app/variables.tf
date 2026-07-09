variable "image" {
  description = "Container image used by the demo app."
  type        = string
}

variable "replicas" {
  description = "Number of application replicas."
  type        = number
}

variable "env" {
  description = "Environment name, for example dev or stg."
  type        = string
}

variable "ingress_host" {
  description = "Hostname used by the Kubernetes Ingress."
  type        = string
}

