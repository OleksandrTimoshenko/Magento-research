#!/bin/bash
bin/magento setup:install --base-url=http://127.0.0.1 --db-host=db --db-name=magentodb --db-user=magentouser --db-password=1234 --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --elasticsearch-host=elasticsearch
bin/magento module:disable Magento_TwoFactorAuth
bin/magento cache:flush
chown -R www-data. /opt/magento2

apt install nginx -y
service nginx stop && service nginx start && service nginx status
mkdir /run/php/ && touch /run/php/php8.1-fpm.sock
/usr/sbin/php-fpm8.1 -F