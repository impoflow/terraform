resource "aws_eip" "mage" {
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "my-key-pair"
  public_key = file(var.ssh_key_name)
}

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

resource "aws_instance" "mage_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.mage_sg.id]

  user_data = <<-EOF
                #!/bin/bash
                set -e

                # Actualizamos el sistema
                sudo yum update -y

                # Instalamos Python 3
                sudo yum install -y python3

                # Instalamos pip si no está disponible
                sudo python3 -m ensurepip

                # Creamos un entorno virtual para Mage AI
                python3 -m venv /home/ec2-user/myenv
                source /home/ec2-user/myenv/bin/activate

                # Instalamos Mage AI
                pip install --upgrade pip
                pip install mage-ai

                if [ ! -d "/home/ec2-user/${var.mage_project_name}" ]; then
                    mage init "/home/ec2-user/${var.mage_project_name}"
                fi

                # Iniciamos Mage AI en segundo plano
                nohup mage start "/home/ec2-user/${var.mage_project_name}" --host 0.0.0.0 --port 6789 &
                EOF

  tags = {
    Name = "Mage-Instance"
  }
}

resource "aws_eip_association" "mage_eip_association" {
  instance_id   = aws_instance.mage_instance.id
  allocation_id = aws_eip.mage.id
}

output "mage_instance_public_ip" {
  description = "La IP pública de la instancia Mage"
  value       = "Mage: http://${aws_eip.mage.public_ip}:6789"
}