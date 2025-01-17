resource "aws_eip" "locust" {
}

resource "aws_security_group" "locust_sg" {
  name        = "locust-security-group"
  description = "Grupo de seguridad para el locust"
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
    from_port   = 8089 # LOCUST
    to_port     = 8089
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

resource "aws_instance" "locust_instance" {
  ami                    = "ami-0fff1b9a61dec8a5f" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.subnet-id
  key_name               = aws_key_pair.locust_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.locust_sg.id]

  iam_instance_profile = "LabInstanceProfile"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user

              # Crear directorios para los volúmenes
              mkdir -p /home/ec2-user/prometheus
              mkdir -p /home/ec2-user/locust

              aws s3 cp s3://${var.bucket-name}/locustfile.py /home/ec2-user/locust/locustfile.py
              aws s3 cp s3://${var.bucket-name}/prometheus.yml /home/ec2-user/prometheus/prometheus.yml

              sudo sed -i "s/{BACKEND_IP}/${var.backend-ip}/g" /home/ec2-user/prometheus/prometheus.yml

              while [ ! -f /home/ec2-user/locust/locustfile.py ] || [ ! -f /home/ec2-user/prometheus/prometheus.yml ]; do
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

              docker network create locust-network
              docker run -d \
                --name locust_master \
                --network locust-network \
                -p 8089:8089 \
                -p 5557:5557 \
                -p 5558:5558 \
                -v /home/ec2-user/locust:/mnt/locust \
                locustio/locust:latest \
                -f /mnt/locust/locustfile.py --master --host=http://${var.backend-ip}:80

              docker run -d \
                --name locust_worker \
                --network locust-network \
                -v /home/ec2-user/locust:/mnt/locust \
                locustio/locust:latest \
                -f /mnt/locust/locustfile.py --worker --master-host=locust_master

              EOF

  tags = {
    Name = "Locust-Instance"
  }
}

resource "aws_eip_association" "locust_eip_association" {
  instance_id   = aws_instance.locust_instance.id
  allocation_id = aws_eip.locust.id
}