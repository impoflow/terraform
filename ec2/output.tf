output "scrapper-instance-public-ip" {
  description = "La IP pública de la instancia Scrapper"
  value       = aws_eip.scrapper.public_ip
}

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
  value       = aws_eip.mage.public_ip
}