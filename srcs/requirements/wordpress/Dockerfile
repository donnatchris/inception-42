FROM debian:11.11

RUN apt update -y && \
	apt upgrade -y && \
	apt install -y \
	wget \
	curl \
	php7.4 \
	php7.4-fpm \
	php7.4-mysql \
	mariadb-client \
	unzip \
	less \
	redis \
	php-redis \
	netcat && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

RUN wget https://fr.wordpress.org/wordpress-6.8.2-fr_FR.tar.gz -P /var/www && \
	tar -xzf /var/www/wordpress-6.8.2-fr_FR.tar.gz -C /var/www && \
	rm /var/www/wordpress-6.8.2-fr_FR.tar.gz && \
	chown -R www-data:www-data /var/www/wordpress

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

EXPOSE 9000

COPY tools/install.sh /install.sh
RUN chmod +x /install.sh
RUN chmod 777 /var/www/wordpress


WORKDIR /var/www/wordpress

HEALTHCHECK --interval=3s --timeout=3s --retries=3 \
CMD mysqladmin -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" ping &>/dev/null;

ENTRYPOINT [ "/install.sh" ]