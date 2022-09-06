resource "aws_lb_target_group" "space" {
  name = "parkingspace-space-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    enabled = true
    interval = 60 
    path = "/api/space/v1/health"
    timeout = 10
    matcher = "200"
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "space" {
  listener_arn = aws_lb_listener.backend.arn
  priority = 3

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.space.arn
  }

  condition {
    path_pattern {
      values = ["/api/space/*"]
    }
  }
}
