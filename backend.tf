terraform {
  backend "s3" {
    bucket = "testi-terraform-state-dev"
    key    = "dev/terraform.tfstate"
    region = "eu-north-1"
  }
}