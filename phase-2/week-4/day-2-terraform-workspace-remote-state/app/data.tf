data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket         = var.state_bucket
    key            = "week4/day2/shared.tfstate"
    region         = var.aws_region
    dynamodb_table = var.lock_table_name
    encrypt        = true
  }
}

