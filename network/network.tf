# VPC Definition
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet in AZ A
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Specify an AZ
  map_public_ip_on_launch = true
}

# public_web Subnet in AZ B
resource "aws_subnet" "public_web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Different AZ
  map_public_ip_on_launch = true
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# public_web Route Table (No Internet Access)
resource "aws_route_table" "public_web" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate public_web Subnet with public_web Route Table
resource "aws_route_table_association" "public_web_association" {
  subnet_id      = aws_subnet.public_web.id
  route_table_id = aws_route_table.public_web.id
}