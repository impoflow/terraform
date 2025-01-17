resource "aws_eip" "load_balancer" {
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "lb-security-group"
  description = "Grupo de seguridad para Load Balancer"
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
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6789 # MAGE
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

resource "aws_instance" "lb_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.load_balancer_sg.id]

  iam_instance_profile = "EMR_EC2_DefaultRole"

  depends_on = [aws_instance.mage_instance]

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

            aws s3 cp s3://${var.bucket-name}/nginx.conf /home/ec2-user/nginx.conf
            aws s3 cp s3://${var.bucket-name}/Dockerfile /home/ec2-user/Dockerfile

            sed -i "s/{MAGE_IP_1}/${aws_instance.mage_instance[0].public_ip}/g" /home/ec2-user/nginx.conf
            sed -i "s/{MAGE_IP_2}/${aws_instance.mage_instance[1].public_ip}/g" /home/ec2-user/nginx.conf

            cd /home/ec2-user
            sudo docker build -t nginx .
            sudo docker run --name nginx -p 6789:6789 nginx
            EOF

  tags = {
    Name = "Load-Balancer-Instance"
  }
}

resource "aws_eip_association" "lb_eip_association" {
  instance_id   = aws_instance.lb_instance.id
  allocation_id = aws_eip.load_balancer.id
}