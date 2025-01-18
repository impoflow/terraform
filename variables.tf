variable "ssh-key-name" {
  description = "Nombre de la clave SSH para acceder a la instancia"
  default     = "~/.ssh/my-ssh-key.pub"
}

variable "region" {
  description = "value of the region"
  default     = "us-east-1"
}

variable "bucket-name" {
  description = "bucket name"
  default     = "neo4j-tscd-18-01-2025"
}

variable "neo4j-username" {
  description = "Nombre de usuario para MongoDB"
  default     = "neo4j"
}

variable "neo4j-passwd" {
  description = "Password for neo4j"
  type        = string
  sensitive   = true
}

variable "mongodb-username" {
  description = "Nombre de usuario para MongoDB"
  default     = "user"
}

variable "mongodb-passwd" {
  description = "Password for mongodb"
  type        = string
  sensitive   = true
}

variable "docker-username" {
  description = "Username for DockerHub"
  default     = "autogram"
}

variable "docker-passwd" {
  description = "Password for DockerHub"
  type        = string
  sensitive   = true
}

variable "github-token" {
  description = "Token for GitHub"
  type        = string
  sensitive   = true
}