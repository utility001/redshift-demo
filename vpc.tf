# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "redshift-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "redshift-igw"
  }
}

## PUBLIC SUBNET
resource "aws_subnet" "public_sub" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true # Give public ip

  tags = {
    Name = "redshift_public_sub"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "redshift_public_rt"
  }
}

resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_rt.id
}



# NAT GATEWAY SETUP
resource "aws_eip" "nat_elastic_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_elastic_ip.id
  subnet_id         = aws_subnet.public_sub.id

  tags = {
    Name = "redshift-nat-gateway"
  }
}


## PRIVATE SUBNET
resource "aws_subnet" "private_sub" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "eu-central-1a" # This is another availability zone for resilience

  tags = {
    Name = "redshift_private_sub"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "redshift_priv_rt"
  }
}

resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_rt.id
}



## SECURITY GROUP
resource "aws_security_group" "redshift_sg" {
  name        = "redshift_sg"
  description = "Allow redshift inbound traffic and All outbound traffic"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress_rule" {
  security_group_id = aws_security_group.redshift_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Which ip range do we allw traffic to come from
  from_port         = 5439        # i.e redshift default port
  to_port           = 5439        # Apparently, we must specify from and to while using tcp/udp
  ip_protocol       = "tcp"       # ssh uses tcp protocol
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.redshift_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow us traffic to everywhere.
  ip_protocol       = "-1"        # All protocols and All ports
}

