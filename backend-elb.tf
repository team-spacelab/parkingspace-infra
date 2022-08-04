resource "aws_lb" "backend" {
  name = "parkingspace-backend-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.backend_elb.id
  ]

  subnets = [
    aws_subnet.backend_a.id,
    aws_subnet.backend_c.id
  ]
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"
    
    redirect {
      path = "/"
      protocol = "HTTPS"
      port = "443"
      status_code = "HTTP_301"
    }
  }
}
