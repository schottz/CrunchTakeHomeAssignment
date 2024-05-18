resource "aws_cloudwatch_log_group" "ecs_container_logs" {
  name = "/ecs/take-home-container-logs"
}

resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.logs"
  private_dns_enabled = true
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}