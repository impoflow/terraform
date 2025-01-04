resource "aws_eip" "scrapper" {
}

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

resource "aws_instance" "scrapper_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.scrapper_sg.id]

  iam_instance_profile = "myS3Role"

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

              # Create directory for data storage
              sudo mkdir -p /datalake

              # Ensure the Docker daemon is ready
              sleep 10  # Give Docker time to initialize

              # Login to Docker registry
              echo ${var.docker-passwd} | docker login -u ${var.docker-username} --password-stdin

              # Pull the Docker image
              sudo docker pull ${var.docker-username}/github-scrapper

              # Run the container
              sudo  docker run -e "BUCKET_NAME=${var.bucket_name}" -e "REGION=us-east-1" ${var.docker-username}/github-scrapper
              EOF

  tags = {
    Name = "Scrapper-Instance"
  }
}

resource "aws_eip_association" "scrapper_eip_association" {
  instance_id   = aws_instance.scrapper_instance.id
  allocation_id = aws_eip.scrapper.id
}

output "scrapper_instance_public_ip" {
  description = "La IP pública de la instancia Scrapper"
  value       = "Scrapper: ${aws_eip.scrapper.public_ip}"
}