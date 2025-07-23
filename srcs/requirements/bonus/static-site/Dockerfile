FROM debian:11.11
RUN apt-get update \
	&& apt-get install -y nginx \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
COPY conf/default.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /var/www/html
COPY static-site/ /var/www/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
