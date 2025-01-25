resource "aws_lb" "webservice_alb" {
  name                        = "webservice-alb"
  internal                    = false
  load_balancer_type          = "application"
  security_groups             = [aws_security_group.webservice_sg.id]
  subnets                     = [var.subnet-id, var.public-web-subnet-id]
  enable_deletion_protection  = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "webservice-alb"
  }
}

resource "aws_lb_target_group" "webservice_target_group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc-id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    protocol            = "HTTP"
  }

  tags = {
    Name = "webservice-target-group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webservice_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webservice_target_group.arn
  }
}

resource "aws_security_group" "webservice_sg" {
  name        = "webservice-sg"
  description = "SG for ALB"
  vpc_id      = var.vpc-id

  ingress {
    from_port   = 80
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
