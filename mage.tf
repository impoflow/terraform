# Crear una Elastic IP
resource "aws_eip" "mage" {
  vpc = true
}

# Crear un par de claves SSH
resource "aws_key_pair" "ssh_key" {
  key_name   = "my-key-pair"
  public_key = file(var.ssh_key_name)  # Ruta a tu clave pública
}

# Crear el grupo de seguridad para permitir acceso a la instancia
resource "aws_security_group" "mage_sg" {
  name        = "mage-security-group"
  description = "Grupo de seguridad para Mage"
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
    from_port   = 8080  # Mage AI
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6789  # Puerto personalizado para Mage
    to_port     = 6789
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

# Crear una instancia EC2 para Mage
resource "aws_instance" "mage_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.mage_sg.id]

  # Asociar el rol de IAM a la instancia
  iam_instance_profile   = "EMR_EC2_DefaultRole"

 # Configuración para instalar Mage y dependencias
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y

              # Instalamos python3 y venv
              sudo yum install -y python3-venv

              # Crear un entorno virtual
              python3 -m venv myenv
              source myenv/bin/activate

              # Instalar Mage AI dentro del entorno virtual
              pip install mage-ai

              # Iniciar Mage AI en segundo plano
              nohup mage start ${var.mage_project_name} &
              EOF

  tags = {
    Name = "Mage-Instance"
  }
}

# Asociar la Elastic IP a la instancia EC2
resource "aws_eip_association" "mage_eip_association" {
  instance_id   = aws_instance.mage_instance.id
  allocation_id = aws_eip.mage.id
}

# Mostrar la IP pública
output "mage_instance_public_ip" {
  description = "La IP pública de la instancia Mage"
  value       = "Mage: http://${aws_eip.mage.public_ip}:6789"
}