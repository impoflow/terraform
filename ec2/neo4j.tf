resource "aws_eip" "neo4j" {
}

resource "aws_security_group" "neo4j_sg" {
  name        = "neo4j-security-group"
  description = "Grupo de seguridad para Neo4j"
  vpc_id      = var.vpc-id

  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80 # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7474 # Puerto para Neo4j
    to_port     = 7474
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7687 # Puerto para Neo4j
    to_port     = 7687
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

resource "aws_instance" "neo4j_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI (actualiza si es necesario)
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  vpc_security_group_ids = [aws_security_group.neo4j_sg.id]

  iam_instance_profile = "myS3Role"

  user_data = <<-EOF
              #!/bin/bash

              # Actualizar el sistema
              sudo yum update -y
              sudo yum install -y amazon-linux-extras
              sudo amazon-linux-extras enable docker
              sudo yum install -y docker aws-cli
              sudo service docker start
              sudo usermod -a -G docker ec2-user

              # Crear directorios para Neo4j
              mkdir -p /home/ec2-user/neo4j/data
              mkdir -p /home/ec2-user/neo4j/logs
              mkdir -p /home/ec2-user/neo4j/conf

              # Descargar el archivo de configuración neo4j.conf desde S3
              aws s3 cp s3://${var.bucket-name}/neo4j.conf /home/ec2-user/neo4j/conf/neo4j.conf

              # Reemplazar {public_ip} en neo4j.conf con la IP pública de la instancia
              INSTANCE_PUBLIC_IP=${aws_eip.neo4j.public_ip}
              sed -i "s/{public_ip}/$INSTANCE_PUBLIC_IP/g" /home/ec2-user/neo4j/conf/neo4j.conf

              # Ejecutar Neo4j con Docker
              docker run -d \
                --name neo4j \
                -p 7474:7474 -p 7687:7687 \
                -v /home/ec2-user/neo4j/data:/data \
                -v /home/ec2-user/neo4j/logs:/logs \
                -v /home/ec2-user/neo4j/conf:/conf \
                -e NEO4J_AUTH=neo4j/${var.neo4j-passwd} \
                neo4j:5.12.0-community

              # Verificar el estado de Neo4j
              docker ps > /home/ec2-user/neo4j_status.log
            EOF

  tags = {
    Name = "Neo4j-Instance"
  }
}

resource "aws_eip_association" "neo4j_eip_association" {
  instance_id   = aws_instance.neo4j_instance.id
  allocation_id = aws_eip.neo4j.id
}