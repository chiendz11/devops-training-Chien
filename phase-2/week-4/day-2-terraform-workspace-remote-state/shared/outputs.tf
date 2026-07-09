output "image" {
  description = "Demo app image read by the app root through terraform_remote_state."
  value       = terraform_data.shared_config.output.image
}

output "domain_suffix" {
  description = "Local domain suffix used to build dev/stg ingress hosts."
  value       = terraform_data.shared_config.output.domain_suffix
}

