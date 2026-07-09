resource "terraform_data" "shared_config" {
  input = {
    image         = var.image
    domain_suffix = var.domain_suffix
  }
}

