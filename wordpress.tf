# WordPress設定用の変数
variable "wordpress_config" {
  description = "WordPress configuration"
  type = object({
    user_name    = string
    domain_name  = string
    server_admin = string
    db_name      = string
    db_user      = string
  })
  default = {
    user_name    = "wordpress"
    domain_name  = "example.com"
    server_admin = "admin@example.com"
    db_name      = "wordpress"
    db_user      = "wordpress"
  }
}

# データベースパスワードの生成
resource "random_password" "wordpress_db" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "wordpress_db_root" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
