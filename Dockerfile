FROM php:7.0-apache
RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update && apt-get install -y \
        curl \
        ruby \
        gem \
        wget \
        git \ 
        libpng12-dev \
        libjpeg-dev \
        libxml2-dev \
        libmcrypt-dev \
        libmhash2 \
        libc6 \
        zlib1g \
        bzip2 \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache mcrypt soap pdo_mysql json


RUN cd /tmp \
    && wget https://xdebug.org/files/xdebug-2.5.0.tgz \
    && tar -zxvf xdebug-2.5.0.tgz \
    && cd xdebug-2.5.0 \
    && /usr/local/bin/phpize \
    && ./configure --enable-xdebug --with-php-config=/usr/local/bin/php-config \
    && make \
    && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/

RUN { \
        echo '[xdebug]'; \
        echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so'; \
        echo 'xdebug.remote_enable=on'; \
        echo 'xdebug.remote_autostart=on'; \
        echo 'xdebug.remote_connect_back=off'; \
        echo 'xdebug.remote_handler=dbgp'; \
        echo 'xdebug.profiler_enable=off'; \
        echo 'xdebug.profiler_output_dir="/var/www/html"'; \
        echo 'xdebug.remote_port=9001'; \
        echo 'xdebug.remote_host=172.254.254.254'; \
    } > /usr/local/etc/php/conf.d/xdebug.ini

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash


RUN cd /var/www/html
RUN composer install
RUN php artisan migrate
RUN php artisan db:seed