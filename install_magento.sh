#!/bin/sh
MYSQL_PASS="1234"
PHP_VERSION="8.1"
MAGENTO_USER="<your_magento_user>"
MAGENTO_PASSWORD="your_magento_password"
DOMAIN_NAME="magento.feature-testing.link"

echo "Install and setup PHP-$PHP_VERSION"
apt update
apt install software-properties-common -y && add-apt-repository ppa:ondrej/php -y
sleep 15
apt update
for package in bcmath common curl fpm gd intl mbstring mysql soap xml xsl zip cli
do
    apt install php$PHP_VERSION-$package -y
done
sed -i 's/file_uploads = Off/file_uploads = On/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/memory_limit = .*/memory_limit = 4G/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 128M/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 360/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo = 0/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = America\/Chicago/g' /etc/php/$PHP_VERSION/fpm/php.ini
sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/$PHP_VERSION/fpm/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/$PHP_VERSION/fpm/php.ini

echo "Install and setup NGINX"
apt -y install nginx
systemctl enable nginx.service
touch /etc/nginx/sites-enabled/magento.conf
cat > /etc/nginx/sites-enabled/magento.conf << EOF
upstream fastcgi_backend {
server unix:/run/php/php$PHP_VERSION-fpm.sock;
}
server {
server_name $DOMAIN_NAME;
listen 80;
set \$MAGE_ROOT /opt/magento2;
set \$MAGE_MODE developer; # or production

access_log /var/log/nginx/magento2-access.log;
error_log /var/log/nginx/magento2-error.log;

include /opt/magento2/nginx.conf.sample;
}
EOF
systemctl restart nginx.service

echo "Install and setup MYSQL"
apt install mariadb-server mariadb-client -y
systemctl enable mysql.service
systemctl enable mariadb.service
mysql_secure_installation <<EOF
y
secret
secret
y
y
y
y
EOF
cat > /tmp/mysql_setup.sql << EOF
CREATE DATABASE magentodb;
CREATE USER 'magentouser'@'localhost' IDENTIFIED BY '1234';
GRANT ALL ON magentodb.* TO 'magentouser'@'localhost' IDENTIFIED BY '1234' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
mysql -u root -p$MYSQL_PASS < /tmp/mysql_setup.sql

echo "Install and setup elasticsearch"
apt install apt-transport-https ca-certificates gnupg2 -y
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list'
apt update -y
apt install elasticsearch -y
systemctl --now enable elasticsearch
curl -X GET "localhost:9200"

echo "Install composer"
curl -sS https://getcomposer.org/installer -o composer-setup.php
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
touch /root/.config/composer/auth.json
cat > /root/.config/composer/auth.json << EOF
{
    "http-basic": {
        "repo.magento.com": {
            "username":"$MAGENTO_USER",
            "password":"$MAGENTO_PASSWORD"
        }
    }
}
EOF
composer create-project -n --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.4 /opt/magento2
cd /opt/magento2
# creds for connect to admin: admin admin123
bin/magento setup:install --base-url=http://$DOMAIN_NAME --db-host=localhost --db-name=magentodb --db-user=magentouser --db-password=1234 --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1
chown -R www-data. /opt/magento2
sudo -u www-data bin/magento module:disable Magento_TwoFactorAuth
sudo -u www-data bin/magento cache:flush
sudo -u www-data bin/magento cron:install

sudo systemctl start nginx