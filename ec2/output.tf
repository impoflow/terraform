output "neo4j-instance-public-ip" {
  description = "La IP pública de la instancia Neo4j"
  value       = aws_eip.neo4j.public_ip
}

output "mongodb-instance-public-ip" {
  description = "La IP pública de la instancia MongoDB"
  value       = aws_eip.mongodb.public_ip
}

output "mage-instance-public-ip" {
  description = "La IP pública de la instancia Mage"
  value       = aws_eip.load_balancer.public_ip
}