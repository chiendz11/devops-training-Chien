output "workspace" {
  description = "Active Terraform workspace."
  value       = terraform.workspace
}

output "helm_release_name" {
  description = "Helm release name."
  value       = module.k8s_app.helm_release_name
}

output "namespace" {
  description = "Kubernetes namespace created for this app."
  value       = module.k8s_app.namespace
}

output "module_env" {
  description = "Environment name passed into the reused k8s-app module."
  value       = local.module_env
}

output "service_endpoint" {
  description = "Internal Kubernetes service endpoint."
  value       = module.k8s_app.service_endpoint
}

output "ingress_host" {
  description = "Ingress host derived from workspace and shared remote state."
  value       = local.ingress_host
}

output "image_from_shared_state" {
  description = "Image read from shared remote state."
  value       = local.image
}
