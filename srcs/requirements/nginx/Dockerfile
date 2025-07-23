FROM debian:11.11
RUN apt-get update \
	&& apt-get install -y nginx curl openssl procps \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /etc/ssl/certs \
	&& mkdir -p /etc/ssl/private \
	&& openssl req -x509 -nodes -days 365 \
	-out /etc/ssl/certs/nginx.crt \
	-keyout /etc/ssl/private/nginx.key \
	-subj "/C=FR/ST=Occitanie/L=Perpignan/O=42/OU=42/CN=chdonnat.42.fr/UID=chdonnat" \
	&& mkdir -p /var/run/nginx \
	&& mkdir -p /var/www/wordpress \
	&& mkdir -p /var/www/html
COPY conf/nginx.conf /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
