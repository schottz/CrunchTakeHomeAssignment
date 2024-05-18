resource "aws_ecr_repository" "take_home_repo" {
  name = "take_home_nodes"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_vpc_endpoint" "ecr_endpoint" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  private_dns_enabled = true
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}

resource "aws_vpc_endpoint" "ecr_endpoint_api" {
  vpc_endpoint_type = "Interface"
  vpc_id = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  private_dns_enabled = true
  subnet_ids = [ for subnet in aws_subnet.private_subnets: subnet.id]
  security_group_ids = [aws_security_group.private_sg.id]
}