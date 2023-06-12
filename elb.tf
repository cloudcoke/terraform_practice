# 로드 밸런서
resource "aws_lb" "external" {
  name     = "${var.project}-lb-ext"
  subnets  = [aws_subnet.public_subnet["10.10.10.0/27"].id, aws_subnet.public_subnet["10.10.10.32/27"].id]
  internal = false

  security_groups = [
    aws_security_group.external_lb.id
  ]

  load_balancer_type = "application"

  tags = {
    Name = "${var.project}-lb-ext"
  }
}

resource "aws_lb" "my_api" {
  name     = "${var.project}-lb-api"
  subnets  = [aws_subnet.public_subnet["10.10.10.64/27"].id, aws_subnet.public_subnet["10.10.10.96/27"].id]
  internal = false

  security_groups = [
    aws_security_group.external_lb.id
  ]

  load_balancer_type = "application"

  tags = {
    Name = "${var.project}-lb-api"
  }
}

# 대상 그룹
resource "aws_lb_target_group" "external" {
  name     = "${var.project}-lb-target-group-ext"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    port    = 80
    path    = "/"
    matcher = "200"
  }

  tags = {
    Name = "${var.project}-lb-target-group-ext"
  }
}

resource "aws_lb_target_group" "my_api" {
  name     = "${var.project}-lb-target-group-api"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    port    = 80
    path    = "/health"
    matcher = "200"
  }

  tags = {
    Name = "${var.project}-lb-target-group-api"
  }
}

# 로드 밸런서 리스너
resource "aws_lb_listener" "external_443" {
  load_balancer_arn = aws_lb.external.arn
  port              = "443"
  protocol          = "HTTPS"

  # HTTPS를 위한 인증서
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.my_acm

  default_action {
    target_group_arn = aws_lb_target_group.external.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "external_80" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  # 80 -> 443으로 리다이렉트
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "api_443" {
  load_balancer_arn = aws_lb.my_api.arn
  port              = "443"
  protocol          = "HTTPS"

  # HTTPS를 위한 인증서
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.my_acm

  default_action {
    target_group_arn = aws_lb_target_group.my_api.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "api_80" {
  load_balancer_arn = aws_lb.my_api.arn
  port              = "80"
  protocol          = "HTTP"

  # 80 -> 443으로 리다이렉트
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 대상 그룹과 인스턴스 연결
resource "aws_lb_target_group_attachment" "front_main" {
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.front_main.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "front_backup" {
  target_group_arn = aws_lb_target_group.external.arn
  target_id        = aws_instance.front_backup.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "back_main" {
  target_group_arn = aws_lb_target_group.my_api.arn
  target_id        = aws_instance.back_main.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "back_backup" {
  target_group_arn = aws_lb_target_group.my_api.arn
  target_id        = aws_instance.back_backup.id
  port             = 80
}