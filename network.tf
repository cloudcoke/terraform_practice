data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "instance-type"
    values = [var.my_ec2_type]
  }

  location_type = "availability-zone"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc-${var.region}"
  }
}

# Internet Gateway : VPC 내부와 외부 인터넷이 통신하기 위한 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project}-igw-${var.region}"
  }
}

# Subnet : VPC 내에서 나눠진 독립적인 네트워크 구역
resource "aws_subnet" "public_subnet" {
  for_each          = toset(var.public_subnet)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value
  availability_zone = index(var.public_subnet, each.value) % 2 == 0 ? data.aws_ec2_instance_type_offerings.available.locations[0] : data.aws_ec2_instance_type_offerings.available.locations[1]

  tags = {
    Name = "${var.project}-public_subnet-${index(var.public_subnet, each.value)}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each          = toset(var.private_subnet)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value
  availability_zone = index(var.private_subnet, each.value) % 2 == 0 ? data.aws_ec2_instance_type_offerings.available.locations[0] : data.aws_ec2_instance_type_offerings.available.locations[1]

  tags = {
    Name = "${var.project}-private_subnet-${index(var.private_subnet, each.value)}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each       = toset(var.public_subnet)
  subnet_id      = aws_subnet.public_subnet[each.value].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "front_eip" {
  instance = aws_instance.front.id
  domain   = "vpc"
}

resource "aws_eip" "back_eip" {
  instance = aws_instance.back.id
  domain   = "vpc"
}

# resource "aws_route53_zone" "cloudcoke_site" {
#   name = var.default_domain
# }

data "aws_route53_zone" "my_site" {
  name = "${var.default_domain}."
}

resource "aws_route53_record" "my_default_record" {
  zone_id = data.aws_route53_zone.my_site.zone_id
  name    = var.default_domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.front_eip.public_ip]
}

resource "aws_route53_record" "my_www_record" {
  depends_on = [aws_route53_record.my_default_record]

  zone_id = data.aws_route53_zone.my_site.zone_id
  name    = "www.${var.default_domain}"
  type    = "CNAME"
  ttl     = 5
  records = [var.default_domain]
}

resource "aws_route53_record" "my_api_record" {
  zone_id = data.aws_route53_zone.my_site.zone_id
  name    = "api.${var.default_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.back_eip.public_ip]
}