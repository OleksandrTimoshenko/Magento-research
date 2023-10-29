#!/bin/bash
/opt/wait-for-it.sh db:3306 -t 50 -- echo "Connected to DB..."
bin/magento setup:install --base-url=http://localhost --db-host=db --db-name=$MYSQL_DATABASE --db-user=$MYSQL_USER --db-password=$MYSQL_PASSWORD --admin-firstname=$ADMIN_FIRSTNAME --admin-lastname=$ADMIN_LASTNAME --admin-email=$ADMIN_EMAIL --admin-user=$ADMIN_USER --admin-password=$ADMIN_PASS --language=$MAGENTO_LANGUAGE --currency=$MAGENTO_CURRENCY --timezone=$MAGENTO_TIMEZONE --use-rewrites=1 --elasticsearch-host=elasticsearch
cp /root/.config/composer/auth.json /opt/mahento2
bin/magento module:disable Magento_TwoFactorAuth
# Install sampledata using composer
composer require magento/module-bundle-sample-data magento/module-widget-sample-data magento/module-theme-sample-data magento/module-catalog-sample-data magento/module-customer-sample-data magento/module-cms-sample-data  magento/module-catalog-rule-sample-data magento/module-sales-rule-sample-data magento/module-review-sample-data magento/module-tax-sample-data magento/module-sales-sample-data magento/module-grouped-product-sample-data magento/module-downloadable-sample-data magento/module-msrp-sample-data magento/module-configurable-sample-data magento/module-product-links-sample-data magento/module-wishlist-sample-data magento/module-swatches-sample-data magento/sample-data-media magento/module-offline-shipping-sample-data --no-update
composer update
# Install sampledata using magento
#bin/magento sampledata:deploy
bin/magento module:enable Magento_CustomerSampleData Magento_MsrpSampleData Magento_CatalogSampleData Magento_DownloadableSampleData Magento_OfflineShippingSampleData Magento_BundleSampleData Magento_ConfigurableSampleData Magento_ThemeSampleData Magento_ProductLinksSampleData Magento_ReviewSampleData Magento_CatalogRuleSampleData Magento_SwatchesSampleData Magento_GroupedProductSampleData Magento_TaxSampleData Magento_CmsSampleData Magento_SalesRuleSampleData Magento_SalesSampleData Magento_WidgetSampleData Magento_WishlistSampleData
rm -rf var/cache/* var/page_cache/* var/generation/*
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento indexer:reindex
bin/magento setup:static-content:deploy -f
chown -R www-data. /opt/magento2/var
chown -R www-data. /opt/magento2/pub
chown -R www-data. /opt/magento2/generated
apt install nginx -y
service nginx stop && service nginx start && service nginx status
mkdir /run/php/ && touch /run/php/php8.1-fpm.sock
/usr/sbin/php-fpm8.1 -F