output "helm_release_name" {
  description = "Helm release name."
  value       = module.k8s_app.helm_release_name
}

output "namespace" {
  description = "Kubernetes namespace created for this app."
  value       = module.k8s_app.namespace
}

output "service_endpoint" {
  description = "Internal Kubernetes service endpoint."
  value       = module.k8s_app.service_endpoint
}

