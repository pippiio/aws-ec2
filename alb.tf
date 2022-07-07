resource "aws_security_group" "alb" {
  count = local.enable_load_balancer

  description = "Allow global http(s) traffic to ALB"
  name_prefix = "${local.name_prefix}alb"
  vpc_id      = local.config.vpc_id

  ingress {
    description = "Allow ingress http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ingress https traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all egress traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}alb"
  })
}

resource "aws_lb" "this" {
  count = local.enable_load_balancer

  name               = "${local.name_prefix}alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = local.config.public_subnets

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}alb"
  })
}

resource "aws_lb_target_group" "this" {
  count = local.enable_load_balancer

  name     = "${local.name_prefix}alb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.config.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-299"
    path                = local.config.health_check
    port                = 80
    timeout             = 10
    unhealthy_threshold = 3
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}alb"
  })
}

resource "aws_lb_listener" "http" {
  count = local.enable_load_balancer

  load_balancer_arn = aws_lb.this[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.enable_load_balancer

  load_balancer_arn = aws_lb.this[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  depends_on = [
    aws_lb.this,
    aws_lb_target_group.this
  ]
}
