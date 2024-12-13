# Crear una VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Crear una Subnet pública
resource "aws_subnet" "public" {
  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Asegura que las instancias obtengan una IP pública
}

# Crear un Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  
}

# Crear una tabla de rutas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # Permitir tráfico a Internet
    gateway_id = aws_internet_gateway.main.id
  }
}

# Asociar la Subnet con la tabla de rutas pública
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}