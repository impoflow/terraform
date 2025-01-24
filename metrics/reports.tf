resource "aws_eip" "reports" {
}

resource "aws_security_group" "reports_sg" {
  name        = "reports-security-group"
  description = "Grupo de seguridad para el reports"
  vpc_id      = var.vpc-id

  ingress {
    from_port   = 22 # SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090 # prometheus
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

resource "aws_instance" "reports_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.reports_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.reports_sg.id]

  iam_instance_profile = "myS3Role"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user

              # Crear directorios para los volúmenes
              mkdir -p /home/ec2-user/prometheus

              aws s3 cp s3://${var.bucket-name}/prometheus.yml /home/ec2-user/prometheus/prometheus.yml
              sudo sed -i "s/{BACKEND_IP}/${var.backend-ip}/g" /home/ec2-user/prometheus/prometheus.yml

              while [ ! -f /home/ec2-user/prometheus/prometheus.yml ]; do
                  sleep 5
                  echo "Esperando archivos..."
              done

              # Ejecutar docker
              docker run -d \
                --name prometheus \
                -p 9090:9090 \
                -v /home/ec2-user/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
                -v prometheus_data:/prometheus \
                prom/prometheus:latest \
                --config.file=/etc/prometheus/prometheus.yml
              EOF

  tags = {
    Name = "Reports-Instance"
  }
}

resource "aws_eip_association" "reports_eip_association" {
  instance_id   = aws_instance.reports_instance.id
  allocation_id = aws_eip.reports.id
}