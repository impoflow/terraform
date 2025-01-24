variable "region" {
  description = "The region in which the resources will be created."
  type        = string
  default     = "us-west-2"
}

variable "vpc-id" {
  description = "The ID of the VPC in which the resources will be created."
  type        = string
}

variable "subnet-id" {
  description = "The ID of the subnet in which the resources will be created."
  type        = string
}

variable "bucket-name" {
  description = "The name of the S3 bucket where the data will be stored."
  type        = string
}

variable "docker-username" {
  description = "The username to login to the Docker registry."
  type        = string
}

variable "docker-passwd" {
  description = "The password to login to the Docker registry."
  type        = string
}

variable "key-name" {
  description = "The name of the key pair to use to connect to the instances."
  type        = string
}

variable "backend-ip" {
  description = "The IP address of the backend server."
  type        = string
}