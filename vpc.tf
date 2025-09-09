resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.name}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "my_pub_subnet_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-${var.environment}-public-1a"
  }
}


resource "aws_subnet" "my_pri_subnet_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.30.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-${var.environment}-private-1a"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name}-${var.environment}-igw"
  }
}

resource "aws_route_table" "my_public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name}-public-rt"
  }
}

resource "aws_route" "my_route" {
  route_table_id         = aws_route_table.my_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_route_table_association" "my_route_public_1a" {
  subnet_id      = aws_subnet.my_pub_subnet_1a.id
  route_table_id = aws_route_table.my_public_rt.id
}



resource "aws_route_table" "my_private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.name}-${var.environment}-private-rt"
  }
}
resource "aws_route_table_association" "my_route_private_1a" {
  subnet_id      = aws_subnet.my_pri_subnet_1a.id
  route_table_id = aws_route_table.my_private_rt.id
}