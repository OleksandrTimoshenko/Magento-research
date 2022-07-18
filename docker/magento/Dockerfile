FROM ubuntu:20.04

ARG PHP_VERSION=8.1

RUN apt update && \
    apt install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php -y && \
    apt update

RUN apt install php$PHP_VERSION-bcmath \
                php$PHP_VERSION-common \
                php$PHP_VERSION-curl \
                php$PHP_VERSION-fpm \
                php$PHP_VERSION-gd \
                php$PHP_VERSION-intl \
                php$PHP_VERSION-mbstring \
                php$PHP_VERSION-mysql \
                php$PHP_VERSION-soap \
                php$PHP_VERSION-xml \
                php$PHP_VERSION-xsl \
                php$PHP_VERSION-zip \
                php$PHP_VERSION-cli \
                curl \
                nginx -y

ADD magento.conf /etc/nginx/sites-enabled/magento.conf

RUN sed -i 's/file_uploads = Off/file_uploads = On/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/memory_limit = .*/memory_limit = 8G/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 500M/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 500/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo = 0/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i 's/;date.timezone =/date.timezone = America\/Chicago/g' /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/$PHP_VERSION/fpm/php.ini && \
    sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/$PHP_VERSION/fpm/php.ini

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

COPY auth.json /root/.config/composer/auth.json

RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.4 /opt/magento2

WORKDIR /opt/magento2

ADD start_magento.sh /opt/magento2/start_magento.sh