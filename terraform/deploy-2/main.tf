
terraform {
	required_version = ">= 0.12.0"
}

module "bq" {
  source = "./modules/bq"
}

module "iam" {
  source = "./modules/iam"
}

module "vpc" {
  source = "./modules/vpc"
}

module "gce" {
  source = "./modules/gce"
}

module "quota" {
  source = "./modules/quota"
}
