#AWSプロバイダーの設定
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      environment = var.environment
    }
  }
}

#httpプロバイダーの設定
provider "http" {}