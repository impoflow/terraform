output "vpc-id" {
  value = aws_vpc.main.id
}

output "subnet-id" {
  value = aws_subnet.public.id
}

output "public-web-subnet-id" {
  value = aws_subnet.public_web.id
}