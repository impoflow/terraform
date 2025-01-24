resource "aws_eip" "backend" {
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-security-group"
  description = "Grupo de seguridad para el backend"
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
    from_port   = 5000 # HTTP
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5001 # HTTP
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090 # PROMETHEUS
    to_port     = 9090
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

resource "aws_instance" "backend_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.web_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  iam_instance_profile = "myS3Role"

  user_data = <<-EOF
                #!/bin/bash
                set -e

                # Actualizamos el sistema
                sudo yum update -y

                # Instalamos Docker
                sudo yum install -y docker

                # Iniciamos el servicio Docker
                sudo service docker start

                # Añadimos el usuario actual al grupo docker para evitar usar sudo en cada comando
                sudo usermod -aG docker ec2-user

                # Instalamos Docker Compose
                sudo curl -L "https://github.com/docker/compose/releases/download/v2.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose

                # Instalación de git
                sudo yum install -y git

                # Clonamos el repositorio del backend
                cd /home/ec2-user
                if [ ! -d "webservice" ]; then
                    git clone https://${var.github-token}@github.com/impoflow/webservice.git
                fi
                
                cd webservice
                export INSTANCE_PUBLIC_IP=${aws_eip.backend.public_ip}
                cat <<-EOC > /home/ec2-user/webservice/.env
                BUCKET_NAME=${var.bucket-name}
                REGION=${var.region}
                EOC

                sed -i "s/{backend_ip}/$INSTANCE_PUBLIC_IP/g" client/script.js

                # Construimos y levantamos los contenedores con Docker Compose
                sudo /usr/local/bin/docker-compose up --build -d
                EOF

  tags = {
    Name = "Web-Service-Instance"
  }
}

resource "aws_eip_association" "backend_eip_association" {
  instance_id   = aws_instance.backend_instance.id
  allocation_id = aws_eip.backend.id
}