variable "vpc_id" {}
variable "webtier" {
    type = list(string)
}
variable "apptier" {
    type = list(string)
}
variable "internet_facing_load_balancer_sg" {}
variable "internal_load_balancer_sg" {}