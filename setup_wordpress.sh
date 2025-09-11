#!/bin/bash

# ==============================================================================
# AlmaLinux 9.6 で Apache + PHP 8.3 + MySQL 8.0 + WordPress 環境を構築するスクリプト
# ==============================================================================

set -e
set -o pipefail

# ------------------------------------------------------------------------------
# ユーザーが変更する変数
# ------------------------------------------------------------------------------
USER_NAME="kitada"
DOMAIN_NAME="example.com"
SERVER_ADMIN="admin@example.com"
DB_ROOT_PASSWORD="ChangeMe123!"
DB_NAME="wp_db"
DB_USER="wp_user"
DB_PASSWORD="ChangeMe123!"

# ------------------------------------------------------------------------------
WORDPRESS_DIR="/var/www/vhosts/web.${DOMAIN_NAME}/public_html"

# ------------------------------------------------------------------------------
# チェック
# ------------------------------------------------------------------------------
echo "スクリプトを開始します..."
if [ "$(id -u)" != "0" ]; then
  echo "エラー: root ユーザーで実行してください。" 1>&2
  exit 1
fi

# ------------------------------------------------------------------------------
# ホスト名変更
# ------------------------------------------------------------------------------

echo "=== ホスト名を設定します ==="
hostnamectl set-hostname ${USER_NAME}-education-web01
echo "ホスト名を ${USER_NAME}-education-web01 に変更しました"

# ------------------------------------------------------------------------------
# 必要なパッケージのインストール
# ------------------------------------------------------------------------------
echo "=== パッケージをインストールします ==="
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
dnf module -y reset php
dnf module -y enable php:remi-8.3
dnf install -y httpd php-fpm php-mysqlnd php-gd php-xml php-mbstring php-json php-zip php-opcache \
  mysql-community-server wget expect tar

# ------------------------------------------------------------------------------
# Apache 設定
# ------------------------------------------------------------------------------
echo "=== Apache を設定します ==="
cp -ip /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original
sed -i "s|#ServerName www.example.com:80|ServerName web.${DOMAIN_NAME}:80|" /etc/httpd/conf/httpd.conf

mkdir -p $WORDPRESS_DIR
cat <<EOF > /etc/httpd/conf.d/web.${DOMAIN_NAME}.conf
<VirtualHost *:80>
   ServerAdmin ${SERVER_ADMIN}
   ServerName web.${DOMAIN_NAME}
   DocumentRoot "${WORDPRESS_DIR}"
   DirectoryIndex index.php index.html index.xml
   <Directory "${WORDPRESS_DIR}">
       Options FollowSymLinks
       AllowOverride All
       Require all granted
   </Directory>
   CustomLog "/var/log/httpd/web.${DOMAIN_NAME}-access_log" combined
   ErrorLog "/var/log/httpd/web.${DOMAIN_NAME}-error_log"
</VirtualHost>
EOF
systemctl enable --now httpd

# ------------------------------------------------------------------------------
# PHP 設定
# ------------------------------------------------------------------------------
echo "=== PHP を設定します ==="
cp -ip /etc/php.ini /etc/php.ini.original
sed -i 's|^;date.timezone =|date.timezone = Asia/Tokyo|' /etc/php.ini
sed -i 's/^expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 128M/' /etc/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 128M/' /etc/php.ini

systemctl restart php-fpm
sed -i 's/^user = .*/user = apache/' /etc/php-fpm.d/www.conf
sed -i 's/^group = .*/group = apache/' /etc/php-fpm.d/www.conf
systemctl enable --now php-fpm

# ------------------------------------------------------------------------------
# MySQL 設定
# ------------------------------------------------------------------------------
echo "=== MySQL を設定します ==="
systemctl enable --now mysqld


TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)

# root 初期パスワード設定と最低限のセキュリティ対策
mysql --connect-expired-password -u root -p"$TEMP_PASS" <<MYSQL_SCRIPT
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# WordPress 用 DB 作成
mysql -u root -p"$DB_ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# ------------------------------------------------------------------------------
# SELinux 停止
# ------------------------------------------------------------------------------
echo "=== SELinux を無効化します ==="
setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# ------------------------------------------------------------------------------
# WordPress インストール
# ------------------------------------------------------------------------------
echo "=== WordPress をインストールします ==="
wget https://ja.wordpress.org/latest-ja.tar.gz -O /var/tmp/latest-ja.tar.gz
tar -xzf /var/tmp/latest-ja.tar.gz -C /var/tmp/
cp -rp /var/tmp/wordpress/* $WORDPRESS_DIR 2>/dev/null || true
chown -R apache:apache $WORDPRESS_DIR
find $WORDPRESS_DIR -type d -exec chmod 755 {} \;
find $WORDPRESS_DIR -type f -exec chmod 644 {} \;

cp $WORDPRESS_DIR/wp-config-sample.php $WORDPRESS_DIR/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $WORDPRESS_DIR/wp-config.php
sed -i "s/username_here/$DB_USER/" $WORDPRESS_DIR/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" $WORDPRESS_DIR/wp-config.php
rm -f /var/tmp/wordpress-salts

# ------------------------------------------------------------------------------
# firewalld 停止
# ------------------------------------------------------------------------------
#echo "=== firewalld を停止します ==="s
#systemctl disable --now firewalld || true

# ------------------------------------------------------------------------------
# 完了
# ------------------------------------------------------------------------------
echo "=================================================="
echo "WordPress 環境の構築が完了しました。"
echo "http://web.${DOMAIN_NAME}/ にアクセスしてください。"