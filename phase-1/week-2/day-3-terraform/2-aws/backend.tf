terraform {
  backend "s3" {
    bucket         = "tfstate-chienqt-8bcb3c58"
    key            = "phase1/week2/day3.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tfstate-lock"
    encrypt        = true
  }
}
