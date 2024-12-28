  resource "aws_eip" "mongodb" {
  }

  resource "aws_security_group" "mongodb_sg" {
    name        = "mongodb-security-group"
    description = "Grupo de seguridad para MongoDB"
    vpc_id      = aws_vpc.main.id

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
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  depends_on             = [null_resource.create_bucket_and_upload]

  iam_instance_profile = "myS3Role"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y amazon-linux-extras
              sudo amazon-linux-extras enable corretto8
              sudo yum install -y java-1.8.0-openjdk-devel

              # Instalar MongoDB
              sudo tee /etc/yum.repos.d/mongodb-org-8.0.repo <<EOL
              [mongodb-org-8.0]
              name=MongoDB Repository
              baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/x86_64/
              gpgcheck=1
              enabled=1
              gpgkey=https://pgp.mongodb.com/server-8.0.asc
              EOL

              sudo yum install -y mongodb-mongosh-shared-openssl3
              sudo yum install -y mongodb-org

              # Descargar el archivo de configuración de mongod
              aws s3 cp s3://${var.bucket_name}/mongod.conf /etc/mongod.conf 

              # Iniciar y habilitar MongoDB
              sudo systemctl start mongod
              sudo systemctl enable mongod

              # Esperar a que MongoDB se inicie
              sleep 20

              # Crear usuario administrador en MongoDB
              mongosh <<EOM
              use admin
              db.createUser({
                user: "admin",
                pwd: "securePassword123",
                roles: [{ role: "userAdminAnyDatabase", db: "admin" }]
              });
              EOM

              # Reiniciar MongoDB para aplicar configuración de seguridad
              sudo systemctl restart mongod
              EOF

  tags = {
    Name = "MongoDB-Instance"
  }
}


  resource "aws_eip_association" "mongodb_eip_association" {
    instance_id   = aws_instance.mongodb_instance.id
    allocation_id = aws_eip.mongodb.id
  }

  output "mongodb_instance_public_ip" {
    description = "La IP pública de la instancia MongoDB"
    value       = "MongoDB: mongodb://${aws_eip.mongodb.public_ip}:27017"
  }
