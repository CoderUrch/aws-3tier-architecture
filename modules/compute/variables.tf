variable "ec2_instance_profile" {}
variable "webtier" { type = list(string) }
variable "apptier" { type = list(string) }
variable "web_tg" {}
variable "app_tg" {}
variable "web_sg" {}
variable "app_sg" {}