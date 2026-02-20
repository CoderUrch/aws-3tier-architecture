variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zones" {
  type    = list(string)
}

variable "vpc_cidr" {}

variable "webtier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
}

variable "apptier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
}

variable "dbtier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
}

variable "vpc_name" {
  description = "The name tag for the VPC"
  type        = string
}