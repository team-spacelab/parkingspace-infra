resource "aws_subnet" "backend_a" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "parkingspace-subnet-backend-a"
  }
}

resource "aws_subnet" "backend_c" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "parkingspace-subnet-backend-c"
  }
}

resource "aws_route_table_association" "backend_a" {
  subnet_id = aws_subnet.backend_a.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "backend_c" {
  subnet_id = aws_subnet.backend_c.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "backend" {
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "TCP"
    security_groups = [
      aws_security_group.backend_elb.id
    ]
  }
}

resource "aws_security_group" "backend_elb" {
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 80
    to_port = 80
    protocol = "TCP"
  }
}
