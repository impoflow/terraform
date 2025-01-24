resource "aws_security_group" "scrapper_sg" {
  name        = "scrapper-security-group"
  description = "Grupo de seguridad para el Scrapper"
  vpc_id      = var.vpc-id

  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80 # LOCUST
    to_port     = 80
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
  instance_type          = "t2.medium"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.tests_ssh_key.key_name
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

              # Ensure the Docker daemon is ready
              sleep 10  # Give Docker time to initialize

              # Login to Docker registry
              echo ${var.docker-passwd} | docker login -u ${var.docker-username} --password-stdin

              # Pull the Docker image
              sudo docker pull ${var.docker-username}/github-scrapper

              # Run the container
              cat <<EOT >> /home/ec2-user/run.sh
              docker run -d --name scrapper -e "BUCKET_NAME=${var.bucket-name}" -e "REGION=us-east-1" -e "USERS=300" -e "URL=https://github.com/search?q=java+agenda&type=repositories&p=" ${var.docker-username}/github-scrapper
              EOT

              chmod +x /home/ec2-user/run.sh

              # Locust
              mkdir -p /home/ec2-user/locust

              aws s3 cp s3://${var.bucket-name}/locustfile.py /home/ec2-user/locust/locustfile.py  
              while [ ! -f /home/ec2-user/locust/locustfile.py ]; do
                  sleep 5
                  echo "Esperando archivos..."
              done            

              docker network create locust-network
              docker run -d \
                --name locust_master \
                --network locust-network \
                -p 80:8089 \
                -p 5557:5557 \
                -p 5558:5558 \
                -v /home/ec2-user/locust:/mnt/locust \
                locustio/locust:latest \
                -f /mnt/locust/locustfile.py --master --host=http://${var.backend-ip}:5000

              docker run -d \
                --name locust_worker \
                --network locust-network \
                -v /home/ec2-user/locust:/mnt/locust \
                locustio/locust:latest \
                -f /mnt/locust/locustfile.py --worker --master-host=locust_master

              EOF

  tags = {
    Name = "Testing-Instance"
  }
}