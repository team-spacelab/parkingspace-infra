resource "aws_lb_target_group" "auth" {
  name = "parkingspace-auth-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    enabled = true
    interval = 60 
    path = "/api/auth/v1/health"
    timeout = 10
    matcher = "200"
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.backend.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = ["/api/auth/*"]
    }
  }
}
