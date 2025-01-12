variable "bucket-name" {
  type = string
}

variable "neo4j-passwd" {
  type = string
  sensitive = true
}

variable "neo4j-ip" {
  type = string
}

variable "mage-ip" {
  type = string
}