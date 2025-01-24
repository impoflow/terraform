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
  count                  = 2
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.medium"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.mage_sg.id]

  iam_instance_profile = "myS3Role"

  depends_on = [aws_instance.mongodb_instance, aws_instance.neo4j_instance]

  user_data = <<-EOF
#!/bin/bash
              set -e  # Exit on any error

              # Add Docker repository
              sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

              # Install Docker
              sudo dnf install -y docker

              # Start Docker service
              sudo systemctl start docker
              sudo systemctl enable docker

              # Add the current user to the Docker group to avoid permission issues
              sudo usermod -aG docker ec2-user

              # Ensure the Docker daemon is ready
              sleep 10  # Give Docker time to initialize

              # Login to Docker registry
              echo ${var.docker-passwd} | docker login -u ${var.docker-username} --password-stdin

              # Pull the Docker image
              sudo docker pull ${var.docker-username}/mage-project

              docker run \
                -e "MONGO_USER=${var.mongodb-username}" \
                -e "MONGO_PASSWD=${var.mongodb-passwd}" \
                -e "MONGO_HOST=${aws_eip.mongodb.public_ip}" \
                -e "NEO_USER=${var.neo4j-username}" \
                -e "NEO_PASSWD=${var.neo4j-passwd}" \
                -e "NEO_HOST=${aws_eip.neo4j.public_ip}" \
                -p 6789:6789 \
                -d ${var.docker-username}/mage-project
              EOF

  tags = {
    Name = "Mage-Instance-${count.index + 1}"
  }
}