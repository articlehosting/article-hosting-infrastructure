provider "aws" {
  region  = var.region
}

provider "kubernetes" {
  host                   = module.kube_cluster.kubernetes_config.host
  cluster_ca_certificate = module.kube_cluster.kubernetes_config.cluster_ca_certificate
  token                  = module.kube_cluster.kubernetes_config.token
  load_config_file       = false
  version                = "~> 1.10"
}

provider "helm" {
  kubernetes {
	host = module.kube_cluster.kubernetes_config.host
	cluster_ca_certificate = module.kube_cluster.kubernetes_config.cluster_ca_certificate
	token =  module.kube_cluster.kubernetes_config.token
	load_config_file = false
  }
  version = "~> 1.2"
}

terraform {
  backend "s3" {
	bucket = "libero-terraform"
	# specify with terraform init --backend-config="key=<env>/terraform.tfstate" to make it dynamic
	region = "us-east-1"
  }
  required_version = ">= 0.12.0"
}

locals {
  cluster_name = "hive-eks-${var.env}"
}

module "vpc" {
  source = "../../modules/vpc"
  name   = var.env
  tags = {
    "kubernetes.io/cluster/${var.env}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.env}" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }
}

module "kube_cluster" {
  source       = "../../modules/kubernetes_cluster"
  cluster_name = local.cluster_name
  env          = var.env
  map_users    = var.map_users
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.subnets
}

module "kube_dns" {
  source = "../../modules/kubernetes_dns"
  domain_name = var.domain_name
  owner_id = local.cluster_name
  role_name = module.kube_cluster.worker_iam_role_name
}
