resource "aws_eip" "locust" {
}

resource "aws_security_group" "locust_sg" {
  name        = "locust-security-group"
  description = "Grupo de seguridad para el locust"
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
    from_port   = 8089  # LOCUST
    to_port     = 8089
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

resource "aws_instance" "locust_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.locust_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.locust_sg.id]

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
                python3 -m venv env
                source env/bin/activate
                pip install locust

                # Definimos las variables de entorno
                export BACKEND_IP=${var.backend-ip}
                echo $BACKEND_IP

                # Nos traemos el código de locust desde S3
                aws s3 cp s3://${var.bucket-name}/locustfile.py locustfile.py

                # Ejecutamos locust
                locust
                EOF

  tags = {
    Name = "Locust-Instance"
  }
}

resource "aws_eip_association" "locust_eip_association" {
  instance_id   = aws_instance.locust_instance.id
  allocation_id = aws_eip.locust.id
}