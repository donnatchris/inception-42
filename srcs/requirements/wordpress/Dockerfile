FROM debian:11.11

RUN apt update -y \
    && apt-get install -y \
        php \
        php-fpm \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-xmlrpc \
        php-soap \
        php-zip \
        php-intl \
        php-opcache \
        mariadb-client \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
# lwejw
RUN mkdir -p /var/www \
	&& curl -o /var/www/wordpress.tar.gz https://fr.wordpress.org/wordpress-6.8.2-fr_FR.tar.gz \
    && tar -xzf /var/www/wordpress.tar.gz -C /var/www \
    && rm /var/www/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/wordpress

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

EXPOSE 9000

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www/wordpress

ENTRYPOINT [ "/entrypoint.sh" ]
