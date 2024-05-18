resource "aws_lb" "my_loadbalancer" {
  name               = "take-home-ecs-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [ for p_subnet in aws_subnet.public_subnets: p_subnet.id]
  security_groups = [
    aws_security_group.public_sg.id
  ]
}

resource "aws_lb_target_group" "my_target_group" {
  name            = "take-home-ecs-tg"
  port            = var.applicatio_port
  protocol        = "HTTP"
  target_type     = "ip"
  vpc_id          = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_loadbalancer.arn
  port              = 80
  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "my_listener_rule" {
  listener_arn = aws_lb_listener.my_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
