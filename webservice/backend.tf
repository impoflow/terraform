resource "aws_eip" "backend" {
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-security-group"
  description = "Grupo de seguridad para el backend"
  vpc_id      = var.vpc-id
  
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
    from_port   = 9090  # PROMETHEUS
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

  iam_instance_profile = "LabInstanceProfile"

  user_data = <<-EOF
                #!/bin/bash
                set -e

                # Actualizamos el sistema
                sudo yum update -y

                # Instalamos Python 3
                sudo yum install -y python3 git

                # Instalamos pip si no está disponible
                sudo python3 -m ensurepip

                # Creamos un entorno virtual
                python3 -m venv /home/ec2-user/myenv
                source /home/ec2-user/myenv/bin/activate

                # Instalamos dependencias
                pip install --upgrade pip
                pip install gunicorn

                # Clonamos el repositorio del backend
                cd /home/ec2-user
                if [ ! -d "webservice" ]; then
                    git clone https://${var.github-token}@github.com/impoflow/webservice.git
                fi
                
                cd webservice
                git checkout develop
                cd server

                # Iniciamos el servidor
                sudo su
                source ../../myenv/bin/activate
                pip install -r requirements.txt
                /home/ec2-user/myenv/bin/gunicorn -w 4 -b 0.0.0.0:80 api_handler:app
                EOF

  tags = {
    Name = "backend-Instance"
  }
}

resource "aws_eip_association" "backend_eip_association" {
  instance_id   = aws_instance.backend_instance.id
  allocation_id = aws_eip.backend.id
}