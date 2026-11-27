#S3 Backend

# backend "s3" {
#   region         = "us-east-2"
#   bucket         = "terraform-state-file-s3-1987"
#   key            = "terraform.tfstate"
#   dynamodb_table = "< the name of the DynamoDB locking table >"
#   profile        = ""
#   role_arn       = "arn:aws:s3:::terraform-state-file-s3-1987"
#   encrypt        = true
# }

terraform {
  backend "s3" {
    bucket       = "terraform-state-file-s3-1987"
    key          = "terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true # Enables S3 native locking (Terraform >= 1.10)
  }
}





#Instances
resource "aws_instance" "server1" {
  ami                    = "ami-0fcb94efd00764cf7"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.pub-sub-1.id
  vpc_security_group_ids = [aws_security_group.server1.id]

  tags = {
    Name = "Tomcat"
  }
}

resource "aws_instance" "server2" {
  ami           = "ami-0fcb94efd00764cf7"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.priv-sub-2.id
  tags = {
    Name = "Jenkins"
  }
}




#VPC
resource "aws_vpc" "shola-vpc" {
  cidr_block = "10.0.0.0/16"
}


# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.shola-vpc.id

  tags = {
    Name = "main"
  }
}

# Creating Route Table for Public Subnet
resource "aws_route_table" "test" {
  vpc_id = aws_vpc.shola-vpc.id
}

resource "aws_network_interface" "test" {
  subnet_id = aws_subnet.pub-sub-1.id
}

#Subnet Association

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.test.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.test.id
}


# Creating Subnet
resource "aws_subnet" "pub-sub-1" {
  vpc_id     = aws_vpc.shola-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public_Subnet"
  }
}

resource "aws_subnet" "priv-sub-2" {
  vpc_id     = aws_vpc.shola-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private_Subnet"
  }
}


# Creating Security Group for server1

resource "aws_security_group" "server1" {
  name        = "sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.shola-vpc.id
  tags = {
    Name = "Tomcat-sg"
  }
}



# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
#   security_group_id = aws_security_group.server1.id
#   cidr_ipv4         = aws_vpc.shola-vpc.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.server1.id
  prefix_list_id    = "pl-047d464325e7bf465"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.server1.id
  cidr_ipv4         = var.cidr_ipv4
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.server1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#Associate Elastic IP with Server1
resource "aws_eip" "lb" {
  instance = aws_instance.server1.id
  domain   = "vpc"
}



