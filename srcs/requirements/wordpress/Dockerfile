# instructions en majuscule
# FROM : image de depart
# WORKDIR : repertoire de travail dans le cadre du build (plusieurs possibles)
# ARG : definir des variables de build (clef=valeur)
# ENV : variables d environnement pour le build et lancement (clef=valeur)
# USER : utilisateur pour les cmdes suivantes et user qui lance le processus
# ADD : ajoute fichiers ou repertoires - peut etre une url, un repo git... (ADD source destination)
# COPY : idem que ADD mais ne peut pas utiliser des fichiers distants
# RUN : lance des commandes shell, utile aussi pour les layers (apt, etc)
# CMD : commande lancee dans le conteneur sous forme de liste (ex : CMD ["python3","-m","flask","run"])
# ENTRYPOINT : plus ou moins comme CMD
# LABEL : ajout de metadatas (cle=valeur)
#docker  EXPOSE : ports en ecoute par le processus, plusieurs lignes possibles (ex : EXPOSE 80/tcp)
# VOLUME : declare les volumes de maniere separee, sous forme de liste (ex : VOLUME ["/var/www","/var/log/apache2"])

# escape=\

FROM debian:11.11
LABEL version=v1.0
LABEL author=chdonnat
RUN apt-get update \
	&& apt-get upgrade -y \
	&& mkdir -p /run/php \
	&& apt-get install -y wget php7.4 php-fpm php-mysql mariadb-client \
	&& wget https://fr.wordpress.org/wordpress-6.8.1-fr_FR.tar.gz -P /var/www \
	&& cd /var/www && tar -xzf wordpress-6.8.1-fr_FR.tar.gz \
	&& rm wordpress-6.8.1-fr_FR.tar.gz \
	&& chown -R root:root /var/www/wordpress \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
EXPOSE 9000
CMD ["php-fpm7.4", "-F"]
