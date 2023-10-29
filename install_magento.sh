#!/bin/bash

# Source the .env file to load environment variables
if [ -f /vagrant/.env_local ]; then
    source /vagrant/.env_local
else
    echo "Error: .env_local file not found."
    exit 1
fi

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
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS' WITH GRANT OPTION;
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
composer create-project -n --repository-url=https://repo.magento.com/ magento/project-community-edition=$MAGENTO_VERSION /opt/magento2
cd /opt/magento2
bin/magento setup:install --base-url=http://$DOMAIN_NAME --db-host=$DB_HOST --db-name=$DB_NAME --db-user=$DB_USER --db-password=$DB_PASS --admin-firstname=$ADMIN_FIRSTNAME --admin-lastname=$ADMIN_LASTNAME --admin-email=$ADMIN_EMAIL --admin-user=$ADMIN_USER --admin-password=$ADMIN_PASS --language=$MAGENTO_LANGUAGE --currency=$MAGENTO_CURRENCY --timezone=$MAGENTO_TIMEZONE --use-rewrites=1
chown -R www-data. /opt/magento2
sudo -u www-data bin/magento module:disable Magento_TwoFactorAuth
sudo -u www-data bin/magento cache:flush
sudo -u www-data bin/magento cron:install

# Install sample data
sudo cp /root/.config/composer/auth.json /opt/magento2
sudo chown -R www-data. /var/www
sudo -u www-data composer require magento/module-bundle-sample-data magento/module-widget-sample-data magento/module-theme-sample-data magento/module-catalog-sample-data magento/module-customer-sample-data magento/module-cms-sample-data  magento/module-catalog-rule-sample-data magento/module-sales-rule-sample-data magento/module-review-sample-data magento/module-tax-sample-data magento/module-sales-sample-data magento/module-grouped-product-sample-data magento/module-downloadable-sample-data magento/module-msrp-sample-data magento/module-configurable-sample-data magento/module-product-links-sample-data magento/module-wishlist-sample-data magento/module-swatches-sample-data magento/sample-data-media magento/module-offline-shipping-sample-data --no-update
sudo -u www-data composer update
sudo -u www-data bin/magento module:enable Magento_CustomerSampleData Magento_MsrpSampleData Magento_CatalogSampleData Magento_DownloadableSampleData Magento_OfflineShippingSampleData Magento_BundleSampleData Magento_ConfigurableSampleData Magento_ThemeSampleData Magento_ProductLinksSampleData Magento_ReviewSampleData Magento_CatalogRuleSampleData Magento_SwatchesSampleData Magento_GroupedProductSampleData Magento_TaxSampleData Magento_CmsSampleData Magento_SalesRuleSampleData Magento_SalesSampleData Magento_WidgetSampleData Magento_WishlistSampleData
sudo rm -rf var/cache/* var/page_cache/* var/generation/*
sudo -u www-data bin/magento setup:upgrade
sudo -u www-data bin/magento setup:di:compile
sudo -u www-data bin/magento indexer:reindex
sudo -u www-data bin/magento setup:static-content:deploy -f

sudo systemctl start nginx

echo "127.0.0.1 $DOMAIN_NAME" | sudo tee -a /etc/hosts