variable "ssh_key_name" {
  description = "Nombre de la clave SSH para acceder a la instancia"
  default = "~/.ssh/my-ssh-key.pub"
}

variable "region" {
  description = "value of the region"
  default = "us-east-1"
}

variable "bucket_name" {
  description = "bucket name"
  default = "neo4j-tscd-110-10-2024"
}

variable "mage_project_name" {
  description = "Nombre del proyecto Mage"
  default = "data-orchestator"
}

variable "neo4j_username" {
  description = "Nombre de usuario para Neo4j"
  default = "user"
}

variable "neo4j-passwd" {
  description = "Password for neo4j"
  type = string
  sensitive = true
}

variable "mongodb_username" {
  description = "Nombre de usuario para MongoDB"
  default = "user"
}

variable "mongodb-passwd" {
  description = "Password for mongodb"
  type = string
  sensitive = true
}

variable "docker-username" {
  description = "Username for DockerHub"
  default = ""
}

variable "docker-passwd" {
  description = "Password for DockerHub"
  type = string
  sensitive = true
}