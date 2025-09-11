terraform {
  backend "s3" {
    bucket = "4tierbucket-demo"
    key    = "3tier/terraform.tfstate"
    region = "eu-north-1"
  }
}