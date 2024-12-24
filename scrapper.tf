# Crear una Elastic IP
resource "aws_eip" "scrapper" {
  vpc = true
}

# Grupo de seguridad de la instancia
resource "aws_security_group" "scrapper_sg" {
  name        = "scrapper-security-group"
  description = "Grupo de seguridad para el Scrapper"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 22    # SSH
    to_port     = 22
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

# Crear una instancia EC2
resource "aws_instance" "scrapper_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.scrapper_sg.id]

  # Configuración
  user_data = <<-EOF
              #!/bin/bash

              sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
              
              echo ${var.docker-passwd} | docker login -u ${var.docker-username} --password-stdin
              docker pull ${var.docker-username}/github-scrapper

              mkdir ./datalake

              docker run -d --name github-scrapper -v $(pwd)/datalake:/app/datalake ${var.docker-username}/github-scrapper
              EOF

  tags = {
    Name = "Scrapper-Instance"
  }
}

# Asociar la Elastic IP a la instancia EC2
resource "aws_eip_association" "scrapper_eip_association" {
  instance_id   = aws_instance.scrapper_instance.id
  allocation_id = aws_eip.scrapper.id
}

# Mostrar la IP pública
output "scrapper_instance_public_ip" {
  description = "La IP pública de la instancia Scrapper"
  value       = "Scrapper: ${aws_eip.scrapper.public_ip}"
}