terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-unique-name"
    key    = "3tier/terraform.tfstate"
    region = "eu-north-1"
  }
}