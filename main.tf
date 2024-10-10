provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      "Environment" = var.environment
      "createdby"   = "firefly"
    }
  
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_vpc" "training" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "training" {
  vpc_id = aws_vpc.training.id

}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.training.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.training.id
}

data "aws_availability_zones" "available" {
}

resource "aws_subnet" "training" {
  count                   = length(var.cidr_blocks)
  vpc_id                  = aws_vpc.training.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.cidr_blocks[count.index]
  map_public_ip_on_launch = true

}

resource "aws_security_group" "training" {
  name_prefix = "awsaccount"
  vpc_id      = aws_vpc.training.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.image_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.training[0].id
  vpc_security_group_ids = aws_security_group.training[*].id

  key_name = ""

  tags = {
    "Environment" = var.environment
    "createdby"   = "firefly"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}