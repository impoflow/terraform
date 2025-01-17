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
  default     = "neo4j-tscd-310-10-2025"
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

variable "access-key" {
  description = "Access key for AWS"
  type        = string
  sensitive   = true
}

variable "secret-key" {
  description = "Secret key for AWS"
  type        = string
  sensitive   = true
}

variable "session-token" {
  description = "Session token for AWS"
  type        = string
  sensitive   = true
}

variable "github-mage-token" {
  description = "Token for GitHub"
  default     = "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"
  sensitive   = true
}

variable "github-webservice-token" {
  description = "Token for GitHub"
  default     = "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"
  sensitive   = true
}