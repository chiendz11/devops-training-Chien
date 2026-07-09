locals {
  allowed_workspaces = ["dev", "stg"]
  env                = terraform.workspace

  image         = data.terraform_remote_state.shared.outputs.image
  domain_suffix = data.terraform_remote_state.shared.outputs.domain_suffix
  ingress_host  = "${local.env}.${local.domain_suffix}"
  module_env    = "day2-${local.env}"
  replicas      = lookup(var.replicas_by_workspace, local.env, 1)
}

resource "terraform_data" "workspace_guard" {
  input = local.env

  lifecycle {
    precondition {
      condition     = contains(local.allowed_workspaces, terraform.workspace)
      error_message = "Use workspace dev or stg. Do not apply from default workspace."
    }
  }
}

module "k8s_app" {
  source = "../../day-1-terraform-k8s-app/modules/k8s-app"

  image        = local.image
  replicas     = local.replicas
  env          = local.module_env
  ingress_host = local.ingress_host

  depends_on = [terraform_data.workspace_guard]
}
