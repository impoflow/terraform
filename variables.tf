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
  default = "neo4j-tscd-100-10-2024"
}

variable "neo4j_username" {
  description = "Nombre de usuario para Neo4j"
  default = "words_db_manager"
}

variable "mage_project_name" {
  description = "Nombre del proyecto Mage"
  default = "data-orchestator"
}

variable "docker-username" {
  description = "Username for DockerHub"
  type = string
}

variable "docker-passwd" {
  description = "Password for DockerHub"
  type = string
  sensitive = true
}