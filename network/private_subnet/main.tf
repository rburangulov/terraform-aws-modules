resource "aws_eip" "eip" {
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "${var.env_name}-${var.availability_zone}"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.env_name}-private-${var.availability_zone}"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_block

  availability_zone = var.availability_zone

  tags = {
    Name                              = "${var.env_name}-private-${var.availability_zone}"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
