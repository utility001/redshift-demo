# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "redshift-vpc"
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

  tags = {
    Name = "redshift_priv_rt"
  }
}

resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_rt.id
}



## SECURITY GROUP
resource "aws_security_group" "private_sg" {
  name        = "redshift_private_sg"
  description = "Allow ssh inbound traffic and All outbound traffic"
  vpc_id      = aws_vpc.tt_vpc.id

  tags = {
    created_by = "Sam"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_sg_ingress_rule" {
  security_group_id = aws_security_group.redshift_private_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Which ip range do we allw traffic to come from
  from_port         = 5439        # i.e redshift default port
  to_port           = 5439        # Apparently, we must specify from and to while using tcp/udp
  ip_protocol       = "tcp"       # ssh uses tcp protocol
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tt_pub_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow us traffic to everywhere.
  ip_protocol       = "-1"        # All protocols and All ports
}

