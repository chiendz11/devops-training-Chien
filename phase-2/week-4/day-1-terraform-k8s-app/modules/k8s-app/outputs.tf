output "helm_release_name" {
  description = "Helm release name."
  value       = helm_release.app.name
}

output "namespace" {
  description = "Kubernetes namespace created for this app."
  value       = helm_release.app.namespace
}

output "service_endpoint" {
  description = "Internal Kubernetes service endpoint."
  value       = "http://${helm_release.app.name}.${helm_release.app.namespace}.svc.cluster.local"
}

