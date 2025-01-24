provider "aws" {
  region = var.region
}

module "aws-network" {
  source = "./network"
}

module "aws-s3" {
  source      = "./s3"
  bucket-name = var.bucket-name
}

module "aws-ec2" {
  source    = "./ec2"
  vpc-id    = module.aws-network.vpc-id
  subnet-id = module.aws-network.subnet-id

  key-name    = var.ssh-key-name
  bucket-name = var.bucket-name

  docker-username  = var.docker-username
  docker-passwd    = var.docker-passwd
  mongodb-username = var.mongodb-username
  mongodb-passwd   = var.mongodb-passwd
  neo4j-username   = var.neo4j-username
  neo4j-passwd     = var.neo4j-passwd

  github-token = var.github-token
}

module "aws-lambda" {
  source = "./lambda"

  neo4j-ip = module.aws-ec2.neo4j-instance-public-ip
  mage-ip  = module.aws-ec2.mage-instance-public-ip

  bucket-name  = var.bucket-name
  neo4j-passwd = var.neo4j-passwd

  mongodb-ip = module.aws-ec2.mongodb-instance-public-ip
  mongodb-username = var.mongodb-username
  mongodb-passwd   = var.mongodb-passwd
}

module "aws-webservice" {
  source = "./webservice"

  vpc-id    = module.aws-network.vpc-id
  subnet-id = module.aws-network.subnet-id

  bucket-name = var.bucket-name
  region      = var.region

  key-name     = var.ssh-key-name
  github-token = var.github-token

  s3-function-arn    = module.aws-lambda.s3-function-arn
  neo4j-function-arn = module.aws-lambda.neo4j-function-arn
}

module "aws-metrics" {
  source = "./metrics"

  vpc-id    = module.aws-network.vpc-id
  subnet-id = module.aws-network.subnet-id

  key-name    = var.ssh-key-name
  bucket-name = var.bucket-name
  backend-ip  = module.aws-webservice.backend-instance-public-ip
}

module "aws-tests" {
  count = var.deploy_tests ? 1 : 0

  source = "./tests"

  region     = var.region
  vpc-id     = module.aws-network.vpc-id
  subnet-id  = module.aws-network.subnet-id
  bucket-name = var.bucket-name

  docker-username = var.docker-username
  docker-passwd   = var.docker-passwd
  key-name = var.ssh-key-name
  
  backend-ip      = module.aws-webservice.backend-instance-public-ip
}