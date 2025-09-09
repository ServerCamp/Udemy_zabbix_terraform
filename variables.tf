#リージョン
variable "region" {
  type        = string
  description = "メインリージョン"
  default     = "ap-northeast-1"
}

#名前
variable "name" {
  type        = string
  description = "自分の名前"
  default     = "hoge"
}

#環境名
variable "environment" {
  type        = string
  description = "環境名"
  default     = "environment"
}

#ドメイン名
variable "domain" {
  type        = string
  description = "ドメイン名"
  default     = "example.com"
}

#Web AMI ID
variable "web_ami_id" {
  description = "webインスタンスのAMI ID"
  type        = string
}

#Zabbix AMI ID
variable "zabbix_ami_id" {
  description = "zabbixインスタンスのAMI ID"
  type        = string
}