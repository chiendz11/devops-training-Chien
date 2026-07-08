module "k8s_app" {
  source = "../../modules/k8s-app"

  image        = var.image
  replicas     = var.replicas
  env          = var.env
  ingress_host = var.ingress_host
}

