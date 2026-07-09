resource "helm_release" "app" {
  name             = "demo-app-${var.env}"
  namespace        = "demo-${var.env}"
  create_namespace = true

  chart = "${path.module}/chart"

  set {
    name  = "image"
    value = var.image
  }

  set {
    name  = "replicas"
    value = var.replicas
  }

  set {
    name  = "env"
    value = var.env
  }

  set {
    name  = "ingress.host"
    value = var.ingress_host
  }
}

