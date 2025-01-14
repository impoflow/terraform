  resource "aws_eip" "mongodb" {
  }

  resource "aws_security_group" "mongodb_sg" {
    name        = "mongodb-security-group"
    description = "Grupo de seguridad para MongoDB"
    vpc_id      = var.vpc-id

    ingress {
      from_port   = 22
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
      from_port   = 27017
      to_port     = 27017
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

resource "aws_instance" "mongodb_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]

  iam_instance_profile = "EMR_EC2_DefaultRole"

  user_data = <<-EOF
              #!/bin/bash

              # Actualizar el sistema
              sudo yum update -y

              # Instalar Amazon Linux Extras y Java
              sudo yum install -y amazon-linux-extras
              sudo amazon-linux-extras enable corretto8
              sudo yum install -y java-1.8.0-openjdk-devel

              # Instalar Docker
              sudo amazon-linux-extras enable docker
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user

              # Instalar AWS CLI (si no está instalado)
              sudo yum install -y aws-cli

              cd /home/ec2-user

              # Descargar el archivo de configuración de mongod desde S3
              sudo mkdir -p mongod
              sudo mkdir -p mongod/log
              sudo mkdir -p mongod/data

              aws s3 cp s3://${var.bucket-name}/mongod.conf /home/ec2-user/mongod/mongod.conf

              # Asegurar permisos para el archivo de configuración
              sudo chown -R ec2-user:ec2-user /home/ec2-user/mongod/data /home/ec2-user/mongod/log
              sudo chmod 644 /home/ec2-user/mongod/mongod.conf

              # Ejecutar MongoDB con Docker
              docker run -d \
                -p 27017:27017 \
                --name mongodb \
                -v /home/ec2-user/mongod/data:/data/db \
                -v /home/ec2-user/mongod/log:/var/log/mongodb \
                -v /home/ec2-user/mongod/mongod.conf:/etc/mongod.conf:ro \
                -e MONGO_INITDB_ROOT_USERNAME=${var.mongodb-username} \
                -e MONGO_INITDB_ROOT_PASSWORD=${var.mongodb-passwd} \
                mongo:latest --config /etc/mongod.conf --auth
              
              # Verificar estado de MongoDB
              docker ps > /home/ec2-user/mongo_status.log 2>&1
              EOF


  tags = {
    Name = "MongoDB-Instance"
  }
}


  resource "aws_eip_association" "mongodb_eip_association" {
    instance_id   = aws_instance.mongodb_instance.id
    allocation_id = aws_eip.mongodb.id
  }