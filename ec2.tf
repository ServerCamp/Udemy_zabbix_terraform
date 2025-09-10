#httpプロバイダーを使用してmyipのURLを取得する
data "http" "my_ip" {
  url = "https://api.ipify.org?format=json"
}

#ローカル変数
locals {
  public_key_file  = "./.key/${var.name}-key.id_rsa.pub"
  private_key_file = "./.key/${var.name}-key.id_rsa"
  my_ip            = "${jsondecode(data.http.my_ip.response_body).ip}/32"
}

#秘密鍵の作成
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  filename        = local.private_key_file
  content         = tls_private_key.keygen.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key_pem" {
  filename        = local.public_key_file
  content         = tls_private_key.keygen.public_key_pem
  file_permission = "0644"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.keygen.public_key_openssh
}

# Web用のセキュリティグループを作成
resource "aws_security_group" "education_web_sg" {
  name        = "${var.name}-${var.environment}-web-sg"
  description = "${var.name}-${var.environment}-web-sg"
  vpc_id      = aws_vpc.my_vpc.id

  # SSH (自分のIPのみ許可)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # HTTP (全許可)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (全許可)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドは全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Zabbix用のセキュリティグループを作成
resource "aws_security_group" "education_zabbix_sg" {
  name        = "${var.name}-${var.environment}-zabbix-sg"
  description = "${var.name}-${var.environment}-zabbix-sg"
  vpc_id      = aws_vpc.my_vpc.id

  # SSH (自分のIPのみ許可)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # HTTP (全許可)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # HTTPS (全許可)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
  }

  # アウトバウンドは全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#インスタンス作成
## webサーバ
resource "aws_instance" "my_web_server" {
  ami                    = data.aws_ami.web_latest.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.my_pub_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.education_web_sg.id]
  tags = {
    Name = "${var.name}-${var.environment}-web01"
  }
}

## Zabbixサーバ
resource "aws_instance" "my_zabbix_server" {
  ami                    = data.aws_ami.zabbix_latest.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.key_pair.key_name
  subnet_id              = aws_subnet.my_pub_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.education_zabbix_sg.id]
  tags = {
    Name = "${var.name}-${var.environment}-zabbix-server01"
  }
}

# Webサーバ用 EIP
resource "aws_eip" "web_eip" {
  tags = {
    Name = "${var.name}-${var.environment}-web01-eip"
  }
}

# WebサーバにEIPを関連付け
resource "aws_eip_association" "web_eip_assoc" {
  instance_id   = aws_instance.my_web_server.id
  allocation_id = aws_eip.web_eip.id
}


# Zabbixサーバ用 EIP
resource "aws_eip" "zabbix_eip" {
  tags = {
    Name = "${var.name}-${var.environment}-zabbix-server01-eip"
  }
}

# ZabbixサーバにEIPを関連付け
resource "aws_eip_association" "zabbix_eip_assoc" {
  instance_id   = aws_instance.my_zabbix_server.id
  allocation_id = aws_eip.zabbix_eip.id
}