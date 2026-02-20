variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "vpc_name" {
  description = "The name tag for the VPC"
  type        = string
  default     = "main-vpc"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-north-1a", "eu-north-1b"]
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "webtier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

}

variable "apptier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]

}

variable "dbtier_subnet_cidr" {
  description = "The CIDR block for the web tier subnet"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]

}

