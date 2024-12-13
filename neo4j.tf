# Crear una Elastic IP
resource "aws_eip" "neo4j" {
  vpc = true
}

# Crear el grupo de seguridad para permitir acceso a la instancia
resource "aws_security_group" "neo4j_sg" {
  name        = "neo4j-security-group"
  description = "Grupo de seguridad para Neo4j"
  vpc_id = aws_vpc.main.id
  
  ingress {
    from_port   = 22    # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7474  # Puerto para Neo4j
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7687  # Puerto para Neo4j
    to_port     = 7687
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crear una instancia EC2 para Neo4j
resource "aws_instance" "neo4j_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI (actualiza si es necesario)
  instance_type         = "t2.micro"
  subnet_id             = aws_subnet.public.id
  key_name              = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.neo4j_sg.id]
  depends_on = [ aws_s3_bucket.bucket_for_file ]

  # Asociar el rol de IAM a la instancia
  iam_instance_profile = "EMR_EC2_DefaultRole"

  # Configuración para instalar Neo4j y descargar el archivo de configuración desde S3
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install java-1.8.0-openjdk-devel -y
              sudo yum install aws-cli -y

              # Añadir el repositorio Neo4j

              sudo rpm --import https://debian.neo4j.com/neotechnology.gpg.key
              sudo sh -c 'echo -e "[neo4j]\\nname=Neo4j\\nbaseurl=http://yum.neo4j.com/stable\\nenabled=1\\ngpgcheck=1" > /etc/yum.repos.d/neo4j.repo'

              # Instalar Neo4j
              
              sudo yum install neo4j -y

              # Descargar el archivo de configuración de neo4j
              aws s3 cp s3://${aws_s3_bucket.bucket_for_file.bucket}/neo4j.conf /etc/neo4j/neo4j.conf            

              # Instalar Neo4j
              INSTANCE_PUBLIC_IP=${aws_eip.neo4j.public_ip}
              sudo sed -i "s/{public_ip}/$INSTANCE_PUBLIC_IP/g" /etc/neo4j/neo4j.conf

              sudo systemctl start neo4j
              sudo systemctl enable neo4j
              EOF

  tags = {
    Name = "Neo4j-Instance"
  }
}

resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.neo4j_instance.id
  allocation_id = aws_eip.neo4j.id
}

output "instance_public_ip" {
  description = "La IP pública de la instancia Neo4j"
  value       = "Neo4j: http://${aws_eip.neo4j.public_ip}:7474"
}