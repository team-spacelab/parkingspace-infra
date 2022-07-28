resource "aws_subnet" "database" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.0.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "parkingspace-subnet-db"
  }
}

resource "aws_route_table_association" "database" {
  subnet_id = aws_subnet.database.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_network_interface" "database" {
  subnet_id = aws_subnet.database.id
  private_ips = ["172.16.0.100"]

  security_groups = [
    aws_security_group.database.id
  ]

  tags = {
    Name = "parkingspace-eni-db"
  }
}

resource "aws_instance" "database" {
  ami = "ami-0cbec04a61be382d9"
  instance_type = "t3a.micro"

  network_interface {
    network_interface_id = aws_network_interface.database.id
    device_index = 0
  }

  key_name = aws_key_pair.database.key_name

  tags = {
    Name = "parkingspace-db"
  }

  user_data = <<EOF
#!/bin/bash
amazon-linux-extras install -y mariadb10.5
systemctl start mariadb
EOF
}

resource "aws_security_group" "database" {
  vpc_id = aws_vpc.vpc.id
  name = "parkingspace-sg-db"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "parkingspace-sg-db"
  }
}

resource "aws_eip" "database" {
  instance = aws_instance.database.id
  vpc = true
  
  depends_on = [
    aws_internet_gateway.igw
  ]
}
