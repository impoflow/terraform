resource "aws_eip" "mage" {
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "my-key-pair"
  public_key = file(var.key-name)
}

resource "aws_security_group" "mage_sg" {
  name        = "mage-security-group"
  description = "Grupo de seguridad para Mage"
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
    from_port   = 8080 # Mage AI
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6789 # Puerto personalizado para Mage
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
  instance_type          = "t2.medium"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.mage_sg.id]

  iam_instance_profile = "EMR_EC2_DefaultRole"

  depends_on = [aws_instance.mongodb_instance, aws_instance.neo4j_instance]

  user_data = <<-EOF
                #!/bin/bash
                set -e

                # Actualizamos el sistema
                sudo yum update -y

                # Instalamos Python 3
                sudo yum install -y python3 git

                # Instalamos pip si no está disponible
                sudo python3 -m ensurepip

                # Creamos un entorno virtual para Mage AI
                python3 -m venv /home/ec2-user/myenv
                source /home/ec2-user/myenv/bin/activate

                # Instalamos Mage AI y dependencias adicionales
                pip install --upgrade pip
                pip install mage-ai
                pip install neo4j pymongo boto3

                cat <<EOT >> /home/ec2-user/mage_env.sh
                export MONGO_USER=${var.mongodb-username}
                export MONGO_PASSWD=${var.mongodb-passwd}
                export MONGO_HOST=${aws_eip.mongodb.public_ip}
                export NEO_USER=${var.neo4j-username}
                export NEO_PASSWD=${var.neo4j-passwd}
                export NEO_HOST=${aws_eip.neo4j.public_ip}
                EOT

                chmod +x /home/ec2-user/mage_env.sh
                source /home/ec2-user/mage_env.sh

                # Clonamos el repositorio de Mage AI
                cd /home/ec2-user
                if [ ! -d "mage" ]; then
                    git clone https://${var.github-token}@github.com/impoflow/mage.git
                fi
                
                nohup mage start "/home/ec2-user/mage" --host 0.0.0.0 --port 6789 &
                EOF

  tags = {
    Name = "Mage-Instance"
  }
}

resource "aws_eip_association" "mage_eip_association" {
  instance_id   = aws_instance.mage_instance.id
  allocation_id = aws_eip.mage.id
}