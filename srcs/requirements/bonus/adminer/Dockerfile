FROM debian:11.11
RUN apt-get update \
&& apt-get install -y \
apache2 \
php \
php-mysql \
libapache2-mod-php \
&& apt-get clean \
&& rm -rf /var/www/* \
&& rm -rf /var/lib/apt/lists/* \
&& mkdir -p /usr/share/adminer
COPY tools/adminer-5.3.0-mysql-en.php /var/www/html/index.php
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
