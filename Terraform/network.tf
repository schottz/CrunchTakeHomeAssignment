###############################
#  VIRTUAL PRIVATE CLOUD      #
###############################

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

}

#########################
# Subnets               #
#########################

resource "aws_subnet" "public_subnets" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[each.key]
  availability_zone = each.key

  tags = {
    Name = "Subnet Pública ${each.key}"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each          = toset(var.availability_zones)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[each.key]
  availability_zone = each.key

  tags = {
    Name = "Subnet Privada ${each.key}"
  }
}

#########################
# INTERNET GATEWAY      #
#########################

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

#########################
#       ROUTES          #
#########################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Pública"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  for_each          = aws_subnet.public_subnets
  subnet_id         = each.value.id
  route_table_id    = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-1a.id
  }

  tags = {
    Name = "Interna"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  for_each          = aws_subnet.private_subnets
  subnet_id         = each.value.id
  route_table_id    = aws_route_table.private_route_table.id
}

#########################
#  NAT GATEWAY          #
#########################

resource "aws_eip" "nat_gateway_eip" {
  instance = null
}

resource "aws_nat_gateway" "nat-gateway-1a" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["sa-east-1a"].id

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [ aws_internet_gateway.my_igw ]
}

#########################
#  ACL's                #
#########################

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.my_vpc.id
  subnet_ids = [ for p_subnet in aws_subnet.public_subnets: p_subnet.id]

  tags = {
    Name = "Public"
  }
}

resource "aws_network_acl_rule" "https_nacl" {
    network_acl_id = aws_network_acl.public_nacl.id
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_action = "allow"
    rule_number = 100
}

resource "aws_network_acl_rule" "outbound_nacl" {
    network_acl_id = aws_network_acl.public_nacl.id
    egress      = true
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_block  = "0.0.0.0/0"
    rule_action = "allow"
    rule_number = 100
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.my_vpc.id
  subnet_ids = [ for i_subnet in aws_subnet.private_subnets: i_subnet.id ]

  tags = {
    Name = "Interno"
  }
}

resource "aws_network_acl_rule" "internal_ephemeral_rule" {
    network_acl_id = aws_network_acl.private_nacl.id
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_block = "10.0.0.0/16"
    rule_action = "allow"
    rule_number = 100
}

resource "aws_network_acl_rule" "internal_ephemeral_egress_rule" {
    network_acl_id = aws_network_acl.private_nacl.id
    egress      = true
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_block = "0.0.0.0/0"
    rule_action = "allow"
    rule_number = 100
}

resource "aws_network_acl_rule" "internal_https_rule" {
    network_acl_id = aws_network_acl.private_nacl.id
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    rule_action = "allow"
    rule_number = 200
}

resource "aws_network_acl_rule" "internal_httpsegress_rule" {
    network_acl_id = aws_network_acl.private_nacl.id
    egress      = true
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
    cidr_block = "0.0.0.0/0"
    rule_action = "allow"
    rule_number = 200
}