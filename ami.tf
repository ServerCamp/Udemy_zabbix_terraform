data "aws_ami" "web_latest" {
  most_recent = true
  owners      = [var.ami_owner_id]

  filter {
    name   = "name"
    values = [var.web_ami_filter]
  }
}

data "aws_ami" "zabbix_latest" {
  most_recent = true
  owners      = [var.ami_owner_id]

  filter {
    name   = "name"
    values = [var.zabbix_ami_filter]
  }
}
