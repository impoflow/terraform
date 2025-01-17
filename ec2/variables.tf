variable "vpc-id" {
  type = string
}

variable "subnet-id" {
  type = string
}

variable "key-name" {
  type = string
}

variable "docker-username" {
  type = string
}

variable "docker-passwd" {
  type      = string
  sensitive = true
}

variable "bucket-name" {
  type = string
}

variable "mongodb-username" {
  type = string
}

variable "mongodb-passwd" {
  type      = string
  sensitive = true
}

variable "neo4j-username" {
  type = string
}

variable "neo4j-passwd" {
  type      = string
  sensitive = true
}

variable "secret-key" {
  type      = string
  sensitive = true
}

variable "access-key" {
  type      = string
  sensitive = true
}

variable "session-token" {
  type      = string
  sensitive = true
}

variable "github-token" {
  type = string
}