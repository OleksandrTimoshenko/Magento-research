#!/bin/bash
/opt/wait-for-it.sh db:3306 -t 50 -- echo "Connected to DB..."
bin/magento setup:install --base-url=http://localhost --db-host=db --db-name=$MYSQL_DATABASE --db-user=$MYSQL_USER --db-password=$MYSQL_PASSWORD --admin-firstname=$ADMIN_FIRSTNAME --admin-lastname=$ADMIN_LASTNAME --admin-email=$ADMIN_EMAIL --admin-user=$ADMIN_USER --admin-password=$ADMIN_PASS --language=$MAGENTO_LANGUAGE --currency=$MAGENTO_CURRENCY --timezone=$MAGENTO_TIMEZONE --use-rewrites=1 --elasticsearch-host=elasticsearch
bin/magento module:disable Magento_TwoFactorAuth
bin/magento cache:flush
chown -R www-data. /opt/magento2/var
chown -R www-data. /opt/magento2/pub
chown -R www-data. /opt/magento2/generated
apt install nginx -y
service nginx stop && service nginx start && service nginx status
mkdir /run/php/ && touch /run/php/php8.1-fpm.sock
/usr/sbin/php-fpm8.1 -F