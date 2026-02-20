# Fetch your current public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

module "networking" {
  source              = "./modules/networking"
  vpc_cidr            = var.vpc_cidr
  webtier_subnet_cidr = var.webtier_subnet_cidr
  apptier_subnet_cidr = var.apptier_subnet_cidr
  dbtier_subnet_cidr  = var.dbtier_subnet_cidr
  availability_zones  = var.availability_zones
  vpc_name            = var.vpc_name

}

module "security" {
  source = "./modules/security"
  vpc_id = module.networking.vpc_id
  my_ip  = chomp(data.http.my_ip.response_body)
}

module "iam" {
  source = "./modules/iam"
}

module "loadbalancer" {
  source                           = "./modules/loadbalancer"
  vpc_id                           = module.networking.vpc_id
  apptier                          = module.networking.app_subnets
  webtier                          = module.networking.web_subnets
  internet_facing_load_balancer_sg = module.security.internet_facing_load_balancer_sg
  internal_load_balancer_sg        = module.security.internal_load_balancer_sg
}

module "database" {
  source = "./modules/database"
  db_sg  = module.security.db_sg
  dbtier = module.networking.db_subnets
}

module "compute" {
  source               = "./modules/compute"
  ec2_instance_profile = module.iam.ec2_instance_profile
  webtier              = module.networking.web_subnets
  apptier              = module.networking.app_subnets
  web_tg               = module.loadbalancer.web_tg
  app_tg               = module.loadbalancer.app_tg
  web_sg               = module.security.web_sg
  app_sg               = module.security.app_sg
}

