resource "aws_eip" "web-service" {
  vpc = true
}

# Crear el grupo de seguridad para el servicio web
resource "aws_security_group" "web_sg" {
  name        = "webservice-security-group"
  description = "Grupo de seguridad para el servicio web"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22    # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80    # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080  # Web service
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000  # Custom web service port
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

# Configuración del servicio web en la misma instancia EC2
resource "aws_instance" "web_service_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  depends_on = [ aws_instance.neo4j_instance ]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install aws-cli -y

              # Descargar el código del web service
              sudo mkdir /neo4j_web_service
              aws s3 cp s3://${aws_s3_bucket.bucket_for_file.bucket}/neo4j_web_service.zip /neo4j_web_service
              cd /neo4j_web_service
              sudo unzip neo4j_web_service.zip

              # Instalar dependencias de Python y ejecutar el servicio
              sudo dnf install -y python-pip
              sudo pip3 install Flask neo4j gunicorn

              # Ejecutar el servicio web
              gunicorn -w 4 -b 0.0.0.0:80 /neo4j_web_service/notification_endpoint:app

              export DB_URI=bolt://localhost:7687
              export DB_USER=neo4j
              export DB_PASSWORD=admin

              sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
              sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
              sudo firewall-cmd --permanent --zone=public --add-port=5000/tcp
              sudo firewall-cmd --reload
              EOF

  tags = {
    Name = "WebService-Instance"
  }
}

resource "aws_eip_association" "ws_eip_association" {
  instance_id   = aws_instance.web_service_instance.id
  allocation_id = aws_eip.web-service.id
}

output "web_service_url" {
  description = "La URL pública del servicio web"
  value       = "WebService: http://${aws_eip.web-service.public_ip}:80"
}