# PROJET INCEPTION POUR 42
Par chdonnat (Christophe Donnat de 42 Perpignan, France)  

[🇬🇧 English version](README.md)

## OBJECTIF DU PROJET :

Le but du projet Inception est de mettre en place une infrastructure sécurisée et fonctionnelle basée sur Docker, en conteneurisant plusieurs services (comme Nginx, WordPress et MariaDB) et en les orchestrant avec docker-compose.  
Cela permet d'apprendre la conteneurisation, le réseau, les volumes et la gestion des dépendances entre services dans un environnement de déploiement proche du réel.

### PARTIE BONUS

J'ai ajouté deux fonctionnalités bonus à ce projet :

* **Adminer** : une interface graphique pour gérer les bases de données.
* **Site statique** : j'ai converti le coffre Obsidian que j'avais créé en apprenant le C++ en un site statique complet grâce à Quartz.

## QUELQUES COMMANDES UTILES :

### Commandes disponibles dans le Makefile

* Lancer l’ensemble du projet :

  ```bash
  make
  ```

* Arrêter et supprimer les conteneurs (sans effacer les données) :

  ```bash
  make clear
  ```

* Tout réinitialiser (conteneurs + données) :

  ```bash
  make reset
  ```

### Après avoir lancé `make`, vous pouvez accéder dans votre navigateur à :

* Le site WordPress :
  [https://localhost](https://localhost)

* L’interface d’administration de WordPress :
  [https://localhost/wp-admin](https://localhost/wp-admin)

* Le site statique (vous pouvez y apprendre le C++ !) :
  [https://localhost/static/](https://localhost/static/)

* L’interface Adminer (gestionnaire de base de données graphique) :
  [https://localhost/adminer/](https://localhost/adminer/)

## ARCHITECTURE

Pour ce projet, j’ai suivi l’architecture fournie dans le sujet.
La seule différence est que je **n’utilise pas de dossier `secrets/`** : tous les mots de passe et identifiants sont stockés dans le fichier `.env` à la place.

---

# TUTO COMPLET

## SOMMAIRE

- [Quelques définitions](#quelques-définitions)
- [Docker Nginx](#docker-nginx)
- [Docker MariaDB](#docker-mariadb)
- [Docker Wordpress](#docker-wordpress)
- [Finaliser le docker-compose](#finaliser-le-fichier-docker-compose.yml)
- [Tests](#tests)
- [Tests](#tests)

## QUELQUES DEFINITIONS

### 🐳 **Docker**

**Docker** est un outil qui permet d’exécuter des applications dans des environnements isolés et reproductibles appelés *conteneurs*.
Plutôt que d’installer manuellement chaque dépendance sur le système hôte, Docker regroupe l’ensemble des éléments nécessaires (code, bibliothèques, configuration) dans une unité autonome et portable.

> *Docker peut être comparé à une cuisine entièrement équipée dans une boîte : où qu’elle soit déployée, elle permet de préparer exactement le même plat avec les mêmes outils.*
> Ainsi, une application s’exécute de manière fiable, quel que soit l’environnement.

### 📦 **Image Docker**

Une **image Docker** est une sorte de **recette prête à l’emploi** : elle contient tous les fichiers nécessaires pour créer un conteneur, y compris le système de fichiers, les bibliothèques, le code applicatif, et les commandes d’initialisation.
Les images sont **immutables**, ce qui les rend fiables, reproductibles, et facilement partageables.

### 🧱 **Conteneur Docker**

Un **conteneur** est une **instance active d’une image**. Il s’agit d’un processus isolé qui exécute l’application définie par l’image.

> *Si l’image représente la recette, le conteneur est le plat effectivement préparé.*
> Chaque conteneur peut être démarré, arrêté, supprimé ou recréé à volonté, sans impacter le système ou les autres conteneurs.

### 🧩 **Docker Compose**

**Docker Compose** est un outil permettant de **définir et de lancer plusieurs conteneurs Docker en une seule commande**, à l’aide d’un fichier `docker-compose.yml`.
Ce fichier décrit les services nécessaires (par exemple : un serveur web, une base de données), leur configuration, leurs connexions réseau et les volumes partagés.
Une fois configuré, l’ensemble peut être lancé avec :

```bash
docker compose up
```

> *Cela revient à confier à un chef un menu complet à préparer, chaque plat ayant ses ustensiles, ses ingrédients et son timing.*

---

## DOCKER NGINX

Nginx est un serveur web performant et léger, conçu pour gérer efficacement un grand nombre de connexions simultanées.
Dans le projet Inception, il sert à recevoir les requêtes HTTPS des clients et à les transmettre, selon le cas :
- soit directement (pour des fichiers statiques comme HTML ou CSS),
- soit à un service en arrière-plan comme PHP-FPM (pour exécuter WordPress).
C’est le point d’entrée du site web, le composant qui fait l’interface entre le monde extérieur et les services internes du projet.


Pour realiser le docker Nginx , il faut d'abord créer un fichier de configuration pour Nginx, puis un  Dockerfile qui creera le docker a partir d'une image Debian ou Alpine.

### FICHIER DE CONFIGURATION NGINX `nginx.conf`

Un fichier de configuration Nginx est constitué de blocs suivis d’accolades `{}` contenant les instructions. Chaque instruction est constituée de son nom, d’un espace, puis de son ou ses arguments séparés par des espaces s’il y en a plusieurs, terminée par un point-virgule `;`. Certains blocs seront contenus à l’intérieur d’un bloc "parent".

Exemple minimal de `nginx.conf` :

```nginx
events {}

http {
    server {
        listen 80;
        server_name localhost;

        location / {
            return 200 "Hello, Nginx!\n";
        }
    }
}
```

#### Bloc `events {}`

Il configure la manière dont Nginx gère les connexions réseau (par exemple, combien de connexions simultanées peuvent être traitées). Pour une configuration simple ou un usage dans Docker, on peut laisser ce bloc vide : `events {}`

#### Bloc `http {}`

Il définit toutes les directives liées au protocole HTTP : les serveurs web que Nginx va gérer, les logs, les types de contenu, etc.

Il peut contenir les directives suivantes :

* `access_log` Détermine où sont redirigés les logs d’accès. On lui donne l’argument `/proc/self/fd/1`, qui est un chemin spécial dans Linux permettant à un processus (comme Nginx) d’écrire directement dans sa sortie standard (stdout). Docker capte automatiquement stdout et stderr de chaque conteneur, ce qui permet d’accéder aux logs de Nginx avec une simple commande : `docker logs <nom_du_conteneur>`

* `error_log` Idem mais pour les logs d’erreurs, qu’on redirige vers la sortie d’erreur avec l’argument `/proc/self/fd/2`

* `include` Sert à inclure le contenu d’un autre fichier dans le fichier de configuration principal de Nginx. On lui passe l’argument `/etc/nginx/mime.types` afin de charger les types **MIME** (associations entre extensions de fichiers et leur type de contenu, comme .html → text/html ou .png → image/png), indispensable pour servir des fichiers statiques.

* `default_type` Définit le type MIME par défaut si aucun n’est trouvé. On lui donne l’argument `application/octet-stream`, qui signifie que c’est un fichier binaire générique (ce qui déclenchera le plus souvent un téléchargement par le client).

Le bloc `http` contient aussi le ou les blocs `server` (un seul pour les besoins de Inception).

#### Bloc `server {}`

Ce bloc définit un serveur virtuel, c’est-à-dire une instance de serveur web que Nginx va gérer. Il doit obligatoirement être placé à l’intérieur d’un bloc `http`.

Il peut contenir les directives suivantes :

* `listen` Définit le port sur lequel le serveur va écouter les requêtes. Pour un serveur HTTP classique, on utilise `listen 80;`. Pour un serveur HTTPS (comme dans Inception), on utilise `listen 443 ssl;`. Si la configuration Nginx contient uniquement `listen 443 ssl;`, alors le serveur ne répond qu’aux requêtes HTTPS. Toute tentative de connexion via HTTP (port 80) échouera. Pour une expérience fluide, on peut ajouter un second bloc server qui écoute le port 80 et redirige vers HTTPS:

```nginx
server {
    listen 80;
    server_name localhost <votre_login>.42.fr;
    return 301 https://$host$request_uri;
}
```

* `server_name` Spécifie les noms de domaine ou adresses IP que ce serveur va accepter. Exemple : `server_name localhost;` ou `server_name ${DOMAIN_NAME} localhost;` si on utilise une variable d’environnement dans Docker (le nom de domaine pour Inception sera "<votre_login>.42.fr").

* `root` Indique le chemin du dossier racine du site, c’est-à-dire là où se trouvent les fichiers à servir. Exemple : `root /var/www/wordpress;`. Ce chemin correspond au volume monté dans le conteneur Nginx pour accéder aux fichiers WordPress. Dans le projet Inception, WordPress tourne dans son propre conteneur (wordpress), mais le conteneur Nginx a aussi besoin d’accéder aux fichiers statiques de WordPress pour pouvoir les servir (HTML, CSS, images, fichiers PHP à passer à PHP-FPM, etc.). *→ Voir plus bas le paragraphe sur les volumes*.

* `index` Spécifie le ou les fichiers à rechercher par défaut lorsqu’un utilisateur accède à un répertoire. Exemple : `index index.php index.html index.htm;`.

* `ssl_certificate` et `ssl_certificate_key` Obligatoires si on active SSL avec `listen 443 ssl;`. Ces directives désignent le chemin vers le certificat SSL et sa clé privée. Exemple :

  ```
  ssl_certificate     /etc/ssl/certs/nginx.crt;
  ssl_certificate_key /etc/ssl/private/nginx.key;
  ```

* `ssl_protocols` Permet de choisir les versions de TLS autorisées. Exemple : `ssl_protocols TLSv1.2 TLSv1.3;` (recommandé pour la sécurité).

> **Note : SSL, TLS et HTTPS**
>
> Le terme **SSL** (*Secure Sockets Layer*) est couramment utilisé, mais il est techniquement dépassé : aujourd’hui, on utilise en réalité **TLS** (*Transport Layer Security*), une version plus moderne et plus sécurisée du protocole.
>
> Malgré cela, le mot **“SSL” reste largement employé** dans la documentation, les outils (comme `ssl_certificate`) et les configurations, même lorsqu’on parle de TLS.
>
> Quand un serveur web utilise SSL/TLS, il chiffre les communications avec le client. Cela permet d’assurer :
>
> * la **confidentialité** des échanges (personne ne peut lire les données),
> * l’**authenticité** du serveur (via le certificat),
> * l’**intégrité** des données échangées.
>
> C’est ce qui différencie :
>
> * **HTTP** : communication en clair, non sécurisée
> * **HTTPS** : communication **chiffrée** et **sécurisée** via SSL/TLS
>
> Pour activer HTTPS sur un serveur Nginx, il faut :
>
> * un **certificat** (`.crt`)
> * une **clé privée** (`.key`)
> * et la directive `listen 443 ssl;` dans le bloc `server {}`
>
> Dans le cadre du projet Inception, on utilise des certificats auto-signés, créés automatiquement lors de la construction du conteneur Nginx.
> Cela se fera dans le Dockerfile, à l’aide de la commande `openssl`.
> Ces certificats ne sont pas validés par une autorité de certification : ils sont uniquement destinés à un usage local ou pédagogique.
> Le navigateur affichera une alerte de sécurité, ce qui est normal.

Le bloc `server` peut également contenir des blocs `location` qui définissent le comportement pour certaines URL (comme `/`, ou toutes les URLs se terminant par `.php`, etc.).

#### Blocs `location {}`

Un bloc `location` permet de définir un **comportement spécifique pour une ou plusieurs URL**. Il s’écrit à l’intérieur d’un bloc `server` et commence par un motif (chemin ou expression régulière) suivi d’accolades contenant des directives.

Il peut y avoir plusieurs blocs `location`, chacun correspondant à un cas précis.

Voici les plus utilisés dans Inception :

* `location / {}`
  Ce bloc s’applique à la **racine du site** (toutes les requêtes qui ne correspondent à rien de plus précis).
  Exemple :

  ```nginx
  location / {
      try_files $uri $uri/ =404;
  }
  ```

Cela signifie : "essaie d’abord de servir le fichier tel quel (`$uri`), puis en tant que répertoire (`$uri/`), et si rien n’est trouvé, renvoie une erreur 404". Cette directive est essentielle pour éviter que Nginx tente d’interpréter des chemins inexistants.

* `location ~ \.php$ {}`

Ce bloc redirige toutes les requêtes vers des fichiers PHP vers PHP-FPM (FastCGI), qui tourne dans un conteneur séparé (ici : `wordpress`). Il permet à Nginx de **déléguer l’exécution des scripts PHP** au bon service.

#### Le bloc `location ~ \.php$ {}` en détail


```
location ~ \.php$ {
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    fastcgi_pass wordpress:9000;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
}
```

Explication des directives :

* `fastcgi_split_path_info` Sépare le chemin du fichier PHP et le reste de l’URL.
  Exemple : `/index.php/xyz` → fichier : `index.php`, path\_info : `/xyz`

* `fastcgi_pass` Indique où envoyer la requête : ici vers le conteneur `wordpress` sur le port `9000`, où tourne PHP-FPM.

* `fastcgi_index` Définit le fichier par défaut à exécuter si aucun fichier n’est précisé dans l’URL (ex : `/admin/` → `index.php`).

* `include fastcgi_params` Inclut un fichier standard contenant les variables d’environnement nécessaires à FastCGI (ex : `REQUEST_METHOD`, `SCRIPT_NAME`, etc.).

* `fastcgi_param SCRIPT_FILENAME` Spécifie le chemin complet du fichier PHP à exécuter, en combinant le `document_root` et le nom du fichier PHP demandé.

* `fastcgi_param PATH_INFO` Transmet à PHP la partie de l’URL située **après** le fichier `.php`, utile pour certains frameworks.

> Les directives `fastcgi_pass`, `include fastcgi_params`, et `fastcgi_param SCRIPT_FILENAME` sont **indispensables** pour exécuter du PHP avec Nginx. Les autres sont **fortement recommandées** pour une compatibilité maximale.


### DOCKERFILE

Un `Dockerfile` est un fichier texte qui contient **l’ensemble des instructions nécessaires pour construire une image Docker**.
Chaque instruction est lue ligne par ligne et exécutée dans l’ordre, pour créer une image qui servira de base à un conteneur.

Un `Dockerfile` peut contenir différentes directives, les plus courantes étant :

* `FROM`
  Spécifie l’**image de base** sur laquelle construire. Cette image sera téléchargée depuis le Docker Hub
  
* `LABEL`
  Ajoute des **informations descriptives** (métadonnées) à l’image, comme l’auteur ou une description.

* `RUN`
  Exécute une commande **au moment de la construction de l’image** (ex : installation de paquets). On peut enchaîner plusieurs commandes dans une même ligne `RUN` en les séparant par des `&&`, ce qui permet de créer une image noins lourde qu'une image créée à partir d 'un Dockefile contenant de multiples lignes `RUN`.

* `COPY`
  Copie un fichier ou un dossier **depuis le contexte de build local** vers le système de fichiers de l’image (depuis la machine hôte ou la VM vers vers le conteneur).
  Exemple :

* `EXPOSE`
  Indique **le port sur lequel le conteneur écoutera** une fois lancé. C’est **informatif** (il ne publie pas le port automatiquement).

* `CMD`
  Définit la **commande par défaut** à exécuter quand le conteneur démarre.

* `ENTRYPOINT`
  Très semblable à `CMD` mais définit un programme à exécuter au lieu d'une commande.

Pour plus de lisibilité, on peut couper les longues lignes avec des retours à la ligne précédés du caractère `\`.

Exemple :

```dockerfile
FROM nginx:alpine
LABEL maintainer="votre_login@student.42.fr"
COPY ./html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### COMMANDES DE BASES POUR UTILISER UN DOCKERFILE

Voici les commandes les plus courantes :

* `docker build`
  Sert à créer une image Docker à partir d’un Dockerfile.

  ```bash
  docker build -t nom_de_l_image .
  ```

  * `-t` sert à donner un nom à l’image (exemple : `nginx42`)
  * `.` indique le contexte de build : le dossier contenant le `Dockerfile` (il faut donc être dans le répertoire du Dockerfile pour exécuter cette commande)

* `docker images`
  Affiche la liste des images Docker disponibles localement.

  ```bash
  docker images
  ```
  
* `docker run`
  Sert à lancer un conteneur à partir d’une image.

  ```bash
  docker run -d -p 8080:80 --name mon_conteneur nom_de_l_image
  ```

  * `-d` exécute le conteneur en arrière-plan (mode "détaché")
  * `-p` publie le port du conteneur sur le port de la machine hôte (`hôte:conteneur`)
  * `--name` donne un nom personnalisé au conteneur

* `docker ps`
  Affiche les conteneurs en cours d’exécution.

  ```bash
  docker ps
  ```
  
* `docker logs`
  Affiche les logs d’un conteneur (utile si `access_log` est redirigé vers `stdout` dans Nginx).

  ```bash
  docker logs mon_conteneur
  ```

* `docker stop`
  Arrête un conteneur en cours d’exécution.

  ```bash
  docker stop mon_conteneur
  ```

* `docker rm`
  Supprime un conteneur arrêté.

  ```bash
  docker rm mon_conteneur
  ```

* `docker rmi`
  Supprime une image Docker.

  ```bash
  docker rmi nom_de_l_image
  ```

* `docker system prune -a -f`
  Supprime tout ce qui est inutilisé par Docker :
  * conteneurs arrêtés
  * volumes non utilisés (optionnel, voir plus bas)
  * réseaux non utilisés
  * images non utilisées par un conteneur actif


  ```bash
  docker system prune -a -f
  ```

  * `-a` (ou `--all`) supprime toutes les images non utilisées, même celles qui ne sont pas "dangling" (non taguées). Sans `-a`, seules les images "dangling" sont supprimées.
  * `-f` force la suppression sans demander confirmation.


Parfait, voici une **explication rédigée pour ton README**, dans ton style, qui explique **pas à pas la logique** ayant conduit à l’écriture de ce `Dockerfile`. On garde le ton pédagogique et progressif, avec des retours aux concepts vus précédemment.


### CONSTRUCTION DU DOCKERFILE NGINX

Maintenant que l’on a vu les principales directives d’un `Dockerfile`, on peut comprendre étape par étape la construction de l’image Nginx pour le projet Inception.

Voici le fichier utilisé :

```dockerfile
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
COPY conf/index.html /var/www/html/index.html
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
```

#### *`FROM debian:11.11`*

On part d’une image Debian minimale (`11.11`). On aurait aussi pu utiliser `bookworm`, mais ici on utilise une version précise pour éviter les différences futures.

#### *`RUN ...`*

Cette instruction enchaîne plusieurs commandes dans une seule ligne, séparées par `&&`, pour des raisons de lisibilité et d’optimisation (éviter des couches inutiles dans l’image).

Voici ce que fait chaque partie :

* `apt-get update`
  Met à jour la liste des paquets disponibles.

* `apt-get install -y nginx curl openssl procps`
  Installe :

  * `nginx` : le serveur web
  * `curl` : outil de test HTTP (optionnel mais utile)
  * `openssl` : pour générer un certificat SSL auto-signé
  * `procps` : pour des outils comme `ps` (optionnel mais utile en debug)

* `apt-get clean && rm -rf /var/lib/apt/lists/*`
  Nettoie les fichiers inutiles après installation pour réduire la taille de l’image.

* `mkdir -p /etc/ssl/certs` et `/etc/ssl/private`
  Crée les dossiers qui vont contenir le certificat SSL et la clé privée.

* `openssl req -x509 ...`
  Génère un **certificat SSL auto-signé**, valable un an (`365 jours`).
  Ce certificat sera utilisé par Nginx pour activer le **HTTPS**.

> Génération d’un certificat SSL auto-signé avec `openssl`
>
> Dans le projet Inception, on a besoin d’un certificat SSL pour activer le HTTPS dans Nginx.
> Plutôt que d’utiliser un certificat signé par une autorité (comme Let's Encrypt), on génère un **certificat auto-signé** lors de la construction du conteneur.
>
> La commande suivante est utilisée dans le `Dockerfile` :
>
> ```dockerfile
> openssl req -x509 -nodes -days 365 \
>   -out /etc/ssl/certs/nginx.crt \
>   -keyout /etc/ssl/private/nginx.key \
>   -subj "/C=FR/ST=Occitanie/L=Perpignan/O=42/OU=42/CN=chdonnat.42.fr"
> ```
>
> Cette commande permet de :
>
> * Générer un **certificat auto-signé** (`-x509`) sans passer par une autorité externe
> * **Ne pas chiffrer** la clé privée (`-nodes`) — indispensable en Docker, pour éviter toute saisie de mot de passe
> * Définir une **durée de validité** de 365 jours (`-days 365`)
> * Spécifier les chemins de sortie du certificat et de la clé (`-out`, `-keyout`)
> * Fournir toutes les **informations d’identité** directement en ligne avec l’option `-subj`
>
> Ce certificat et sa clé sont ensuite utilisés dans la configuration Nginx pour activer HTTPS :
>
> ```nginx
> ssl_certificate     /etc/ssl/certs/nginx.crt;
> ssl_certificate_key /etc/ssl/private/nginx.key;
> ```

* `mkdir -p /var/run/nginx`
  Crée le dossier nécessaire pour que Nginx puisse écrire son PID. Nginx a besoin d’un endroit pour stocker son fichier PID (Process ID) lorsqu’il démarre. Par défaut, ce fichier est : `/var/run/nginx.pid`. Mais le fichier ne peut être créé que si le répertoire, or ce dossier n'existe pas forcément par défaut (comme dans un conteneur Debian minimal). Si le dossier n’existe pas et que Nginx essaie d’y écrire, le serveur échouera au démarrage.

* `mkdir -p /var/www/wordpress` et `/var/www/html`
  Crée les répertoires où seront stockés les fichiers du site WordPress et éventuellement une page statique d’accueil (pour faire des test par exemple).
  Ces dossiers correspondent aussi aux **volumes partagés** entre Nginx et d'autres conteneurs (comme WordPress).

#### *`COPY`*

* `COPY conf/nginx.conf /etc/nginx/nginx.conf`
  Copie le fichier de configuration Nginx personnalisé dans l’image, à l’endroit attendu par Nginx.

* `COPY conf/index.html /var/www/html/index.html`
  Copie une page d’accueil statique par défaut (utile pour tester que le serveur fonctionne même sans WordPress).


#### *`EXPOSE 443`*

Indique que le serveur écoute sur le **port HTTPS** (443). Cela ne publie pas le port tout seul, mais **documente** que ce conteneur est conçu pour recevoir des connexions SSL.

#### *`CMD ["nginx", "-g", "daemon off;"]`*

Démarre Nginx en mode **non-daemonisé**, ce qui est indispensable dans un conteneur Docker (sinon le processus principal quitte immédiatement et le conteneur s’arrête).

> Pourquoi utiliser `daemon off;` avec Nginx dans Docker ?
> 
> Quand on exécute un conteneur Docker, il attend qu’un processus principal s’exécute en "PID 1".
> Ce processus devient le "processus maître" du conteneur.
> Si ce processus se termine, le conteneur s’arrête immédiatement.
>
> Le PID 1 dans un conteneur joue un rôle spécial :
> * Il est le parent de tous les autres processus.
> * Il doit rester actif tant que le conteneur tourne.
> * Il doit capturer les signaux (comme SIGTERM) pour permettre un arrêt propre.
>
> Si le processus PID 1 se termine (ou entre en arrière-plan), Docker considère que le conteneur est fini, et l’arrête.
>
> L’option `-g` permet de passer une directive de configuration globale directement en ligne de commande, sans modifier le fichier `nginx.conf`.
>
> `daemon off;` permet de désactiver le mode daemon (arrière-plan) pour que Nginx reste au premier plan en tant que processus principal (PID 1) du conteneur.


---


## DOCKER MARIADB

MariaDB est un système de gestion de base de données relationnelle (SGBDR), compatible avec MySQL.
Il est utilisé par WordPress pour stocker toutes les données dynamiques du site : utilisateurs, articles, paramètres, commentaires, etc.


Dans le projet Inception, MariaDB fonctionne comme un service autonome (dans son propre conteneur) auquel WordPress se connecte via un nom d’hôte (mariadb) et un ensemble d’identifiants (base de données, nom d’utilisateur, mot de passe).


Pour realiser le docker MariaDB , il faut d abord creer un fichier de configuration pour MariaDB, puis un Dockerfile qui creera le docker a partir d une image Debian ou Alpine, et enfin un script d'initialisation.

### FICHIER DE CONFIGURATION MARIADB

Le fichier de configuration de MariaDB permet de définir les paramètres du serveur de base de données au démarrage : ports, noms de fichiers de log, limites de connexions, emplacements des bases, encodage, etc.


Dans le cadre d’Inception, ce fichier est généralement peu modifié. On se contente le plus souvent de créer un fichier SQL d’initialisation (exécuté au premier lancement) pour créer la base, l’utilisateur, et définir ses droits.

#### Comment le nommer et où le placer

MariaDB lit sa configuration à partir de plusieurs fichiers, dans un ordre bien défini. Le fichier principal est généralement situé à `/etc/mysql/my.cnf`.
Mais il inclut aussi automatiquement **tous les fichiers se terminant par `.cnf`** présents dans le dossier `/etc/mysql/conf.d/`.

C’est pourquoi, dans le projet Inception, on peut nommer le fichier de configuration : `50-server.cnf`.
Ce nom suit une **convention d’ordre alphabétique** pour garantir que le fichier soit lu **après les fichiers par défaut**, sans avoir à modifier le fichier `my.cnf` principal.

Il faudra s'assurer que le Dockerfile copie le fichier de configuration dans le conteneur MariaDB dans le dossier `/etc/mysql/conf.d/50-server.cnf`.

> Le nom `50-server.cnf` est recommandé car il est explicite, respecte les conventions, et permet de modifier uniquement ce qui est nécessaire sans toucher aux fichiers système.

#### Contenu d'un fichier de configuration `50-server.cnf`

Un fichier de configuration MariaDB est structuré en deux parties :

* **Des blocs (ou sections)**
  Chaque bloc est indiqué entre crochets, comme `[mysqld]` ou `[client]`.
  Chaque bloc s’applique à une partie spécifique de l’écosystème MariaDB :

  * `[mysqld]` : options pour le serveur MariaDB lui-même
  * `[mysql]` : options pour le client `mysql` (l’interface en ligne de commande)
  * `[client]` : options pour tous les clients (y compris `mysqldump`, `mysqladmin`, etc.)

* **Des directives**
  À l’intérieur de chaque bloc, on écrit des lignes sous la forme `clé = valeur` pour définir les paramètres à appliquer.

#### Exemple de structure utilisée dans Inception :

```ini
[mysqld]
datadir = /var/lib/mysql
socket  = /run/mysqld/mysqld.sock
bind_address = 0.0.0.0
port = 3306
user = mysql
```

> Le bloc `[mysqld]` est le seul obligatoire dans le contexte du projet Inception, car c’est lui qui configure le **comportement du serveur MariaDB** au démarrage.
> Les blocs `[client]` et `[mysql]` sont facultatifs, mais utiles si on veut interagir avec la base en ligne de commande depuis l’intérieur du conteneur.

#### Explication des directives

* `datadir = /var/lib/mysql`
  Spécifie le répertoire où sont stockées les **données des bases**.
  C’est aussi là que sera monté le volume Docker pour persister les données.
  *-> Voir le paragraphe sur les volumes plus loin.*

* `socket = /run/mysqld/mysqld.sock`
  Définit le chemin du **fichier socket UNIX** utilisé pour les connexions locales (utile pour des outils comme `mysql` en ligne de commande dans le conteneur).

* `bind_address = 0.0.0.0`
  Permet à MariaDB d'écouter sur **toutes les interfaces réseau** du conteneur.
  ➤ Cela permet à **WordPress (dans un autre conteneur)** de s’y connecter.

* `port = 3306`
  Définit le port utilisé par MariaDB (3306 est le port standard).

* `user = mysql`
  Indique l’utilisateur système Linux sous lequel MariaDB s’exécute.
  Par défaut dans Docker, l’utilisateur `mysql` est déjà configuré.

### DOCKERFILE MARIADB

Pour le Dockerfile de MariaDB, nous pouvons garder les choses simples. Il faut utiliser une image `debian` ou `alpine` comme l'exige le sujet, installer `mariadb-server`, copier le fichier de configuration réalisé précedemment dans le docker, exposer le port 3306 comme exigé dans le sujet.

Toutefois, lorsque MariaDB démarre pour la première fois, il initialise un répertoire de données vide (`/var/lib/mysql`) et configure la base de données système.
À ce moment-là, si aucun mot de passe ou configuration n’est défini, aucune base ni utilisateur personnalisé n’existe encore, et l’accès root peut être sans mot de passe – ce qui est dangereux en production.
C’est pourquoi, dans un déploiement automatisé (comme dans un conteneur Docker), il est essentiel de fournir dès le départ des variables suivantes pour :

* Créer une base de données personnalisée
  `DB_NAME` : permet d’indiquer à MariaDB quelle base créer automatiquement (ex. wordpress)
  Sans cette variable, il faudrait le faire manuellement après lancement

* Créer un utilisateur avec mot de passe
  `DB_USER` et `DB_USER_PASS` : permettent de créer un utilisateur dédié
  pour se connecter à la base sans utiliser le compte `root`
  **Bonnes pratiques de sécurité :** chaque application (ex. WordPress) doit avoir son propre utilisateur

* Protéger le compte root
  `DB_ROOT_PASS` : fixe un mot de passe sécurisé pour l’utilisateur root de MariaDB
  Sans cela, root pourrait ne pas avoir de mot de passe, ce qui pose un risque critique

Nous allons donc devoir créer un script (`entrypoint.sh` que nous enregistrerons dans le répertoire `tools`) à exécuter au lancement du conteneur MariaDB afin de configurer tout cela (exactement comme si nous tappions des commandes dans le conteneur après son lancement).

Le Dockerfile va donc aussi devoir copier ce script dans de conteneur, donner les droits d'exécutions à ce script, puis exécuter le script.

```Dockerfile
FROM debian:11.11
RUN apt-get update -y \
&& apt-get install -y mariadb-server \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

>  Pourquoi ENTRYPOINT et pas CMD ?
> Parce que ENTRYPOINT permet de remplacer le processus principal du conteneur (PID 1) par un script ou programme, ce qui est idéal pour exécuter notre script d’initialisation.

### DOCKER ET LES VARIABLES D'ENVIRONNEMENT

#### Passer des variables d’environnement à un conteneur Docker

Les **variables d’environnement** permettent de transmettre des informations dynamiques à un conteneur, comme des identifiants, un mot de passe, ou un nom de base de données.
Il existe plusieurs manières de les définir, selon l’outil utilisé.

#### En ligne de commande avec `docker run -e`

Lorsqu’on utilise `docker run` directement (sans `docker-compose`), il est possible de passer les variables une par une avec l'option `-e` :

```bash
docker run -e DB_NAME=wordpress \
           -e DB_USER=wp_user \
           -e DB_USER_PASS=wp_pass \
           -e DB_ROOT_PASS=rootpass \
           nom_de_l_image
```

#### Avec un fichier `.env` et `docker run --env-file`

Les variables peuvent également être stockées dans un fichier `.env` et injectées au conteneur via l’option `--env-file` :

```bash
docker run --env-file .env nom_de_l_image
```

#### Avec l’instruction `ENV` dans le `Dockerfile`

Il est aussi possible de définir des variables directement dans le `Dockerfile` :

```dockerfile
ENV DB_NAME=wordpress
ENV DB_USER=wp_user
ENV DB_USER_PASS=wp_pass
ENV DB_ROOT_PASS=rootpass
```

Cependant, cette méthode rend les valeurs **statiques et figées dans l’image**. Il faut reconstruire l’image si l’on souhaite modifier une valeur.

#### Avec `docker-compose.yml` (recommandé dans Inception)

> Un fichier docker-compose.yml est un fichier de configuration au format YAML qui permet de définir, configurer et lancer plusieurs conteneurs Docker en une seule commande (docker-compose up).

Une manière simple et lisible consiste à déclarer les variables directement dans la section `environment` du fichier `docker-compose.yml` (*-> voir plus loin pour la réalisation d'un fichier `docker-compose.yml`*) :

```yaml
services:
  mariadb:
    build: ./srcs/requirements/mariadb
    environment:
      DB_NAME: wordpress
      DB_USER: wp_user
      DB_USER_PASS: wp_pass
      DB_ROOT_PASS: rootpass
```

Ces variables seront injectées dans le conteneur **au moment de son exécution** et pourront être utilisées dans des scripts comme `entrypoint.sh`.

#### Avec un fichier `.env` et `docker-compose.tml`

Il est également possible de stocker les variables dans un fichier `.env` situé à la racine du projet :

```env
DB_NAME=wordpress
DB_USER=wp_user
DB_USER_PASS=wp_pass
DB_ROOT_PASS=rootpass
```

Par défaut, `docker-compose` lit automatiquement ce fichier `.env` **s’il se trouve dans le même dossier que le `docker-compose.yml`**.
Il est alors possible de référencer ces variables dans `docker-compose.yml` :

```yaml
services:
  mariadb:
    build: ./srcs/requirements/mariadb
    environment:
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_USER_PASS: ${DB_USER_PASS}
      DB_ROOT_PASS: ${DB_ROOT_PASS}
```

#### Recommandation (projet Inception)

> Dans le cadre du projet **Inception**, il est **recommandé d’utiliser le fichier `docker-compose.yml` avec des variables définies directement dans un fichier `.env`**.


### SCRIPT POUR CONFIGURER MARIADB

Voici le script utilisé (placé dans le répertoire `tools` du répertoire `mariadb`).
Ce script est exécuté automatiquement au démarrage du conteneur MariaDB.
Il initialise la base de données, crée l’utilisateur, la base de donnée `wordpress`, et applique les bonnes permissions à partir des **variables d’environnement** fournies.

#### Contenu du script

```bash
#!/bin/bash

set -e

: "${MDB_NAME:?Variable d'environnement MDB_NAME manquante}"
: "${MDB_USER:?Variable d'environnement MDB_USER manquante}"
: "${MDB_USER_PASS:?Variable d'environnement MDB_USER_PASS manquante}"
: "${MDB_ROOT_PASS:?Variable d'environnement MDB_ROOT_PASS manquante}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "📦 Initializing database..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

mysqld_safe --skip-networking &

for i in {30..0}; do
  if mysqladmin ping &>/dev/null; then
    break
  fi
  echo -n "."
  sleep 1
done
if [ "$i" = 0 ]; then
  echo "❌ Failed to start MariaDB."
  exit 1
fi

echo "🛠 Initial configuration..."
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS \${MDB_NAME}\;"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS \${MDB_USER}\@'%' IDENTIFIED BY '${MDB_USER_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON \${MDB_NAME}\.* TO \${MDB_USER}\@'%';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p"${MDB_ROOT_PASS}" shutdown

echo "✅ MariaDB starts..."
exec mysqld_safe
```

#### Explication du script

* `#!/bin/bash` : indique que le script doit être interprété par Bash.
* `set -e` : le script s'arrête immédiatement si une commande échoue. Cela évite d’exécuter la suite du script avec une base mal configurée.

```bash
: "${MDB_NAME:?Variable d'environnement MDB_NAME manquante}"
: "${MDB_USER:?Variable d'environnement MDB_USER manquante}"
: "${MDB_USER_PASS:?Variable d'environnement MDB_USER_PASS manquante}"
: "${MDB_ROOT_PASS:?Variable d'environnement MDB_ROOT_PASS manquante}"
```

* Vérifie que les **quatre variables d’environnement** sont bien définies (pas obligatoire mais bonne pratique).
* Si l'une d'elles est absente, le conteneur **échoue immédiatement** au démarrage avec un message clair.

```bash
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
```

* Crée le dossier `/run/mysqld` si nécessaire (utilisé pour le fichier socket Unix, un fichier spécial qui permet à un client de se connecter).
* Change le propriétaire pour l’utilisateur `mysql`, comme requis par MariaDB.

```bash
if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi
```

* Teste si la base système (`mysql`) existe.
* Si ce n’est **pas le cas** (premier démarrage), elle est initialisée avec `mariadb-install-db`.

```bash
mysqld_safe --skip-networking &
```

* Démarre MariaDB **en arrière-plan**, sans ouvrir le port réseau.
* Le symbole `&` en bash (et en shell en général) lance la commande en arrière-plan.
* Le mode `--skip-networking` garantit qu’aucune connexion externe n'est possible durant l'init (ela empêche un client malveillant ou mal configuré d’envoyer une requête avant que la base ne soit prête).

>  `mysqld_safe` vs `mysqld` : quelles différences ?
> 
> `mysqld` est le vrai binaire du serveur MariaDB (daemon)
> Il gère : Les connexions client, les requêtes SQL, les fichiers de données.
>
> `mysqld_safe` est un wrapper sûr autour de mysqld
> C’est un script Bash (souvent dans /usr/bin/mysqld_safe).
> Il sert à :
> préparer le répertoire socket (/run/mysqld)appliquer les bons droits utilisateur,
> lire les fichiers de config (/etc/my.cnf, /etc/mysql/my.cnf),
> lancer mysqld avec les bons arguments,
> relancer automatiquement mysqld s’il plante,
> rediriger les logs correctement vers stderr/stdout.

```bash
for i in {30..0}; do
  if mysqladmin ping &>/dev/null; then
    break
  fi
  echo -n "."
  sleep 1
done
if [ "$i" = 0 ]; then
  echo "❌ Failed to start MariaDB."
  exit 1
fi
```

* Attend que MariaDB soit **opérationnel** (ping OK).
* `mysqladmin` est est un outil en ligne de commande fourni avec MariaDB/MySQL qui sert à administrer un serveur de base de données (le démarrer, l'arrêter, vérifier son état, etc.).
* `mysqladmin ping` n'a rien à voir avec le ping réseau: Le ping ici tente de se connecter au serveur MariaDB via le socket, envoie une requête légère, attends une réponse (qu'on envoie dans `&>/dev/null` pour ne pas l'afficher), renvoie un code de sortie (0 si OK, 1 si échec).
* Timeout de 30 secondes.
* Affiche une erreur et quitte si le serveur ne répond pas.

```bash
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS \`${MDB_USER}\`@'%' IDENTIFIED BY '${MDB_USER_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO \`${MDB_USER}\`@'%';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
```

* Crée la base de données si elle n’existe pas.
* Crée un utilisateur avec mot de passe et accès total à cette base.
* Définit le mot de passe root (si absent au départ).
* Applique les privilèges avec `FLUSH PRIVILEGES`.

* `mariadb` est le **client en ligne de commande** de MariaDB
* `-u` spécifie l'utilisateur
* `-p` spécifie le mot de passe (attention: pas d'espace entre -p et le mot de passe)
* `-e` signifie : exécute cette commande SQL et quitte le shell MariaDB interactif (mode non interactif).
* par convention, les commandes MariaDB sont en majuscule (mais ça fonctionne sans)


```bash
mysqladmin -u root -p"${MDB_ROOT_PASS}" shutdown
```

* Cette commande arrête proprement le serveur MariaDB lancé temporairement en arrière-plan pendant la phase de configuration initiale.

```bash
echo "✅ MariaDB starts..."
exec mysqld_safe
```

* Lance `mysqld_safe` **en mode foreground** avec `exec` : exec remplace le processus courant (ici : le script shell) par le processus mysqld_safe, sans créer un nouveau processus enfant (ce qui le remplace comme **PID 1**).
* Il prend la place du script.
* Permet au conteneur de rester actif tant que MariaDB tourne.

### TESTER LE CONTENEUR MARIADB

A ce stade, il est possible de tester le conteneur MariaDB.
Pour cela, il faut se placer dans le répertoire contenant le `Dockerfile` et tapper les commandes suivantes :

#### construire l'image :

```bash
docker build -t mariadb .
```

- `-t` sert à donner un nom à l'image

#### lancer le docker :

```bash
docker run -d \
  --name mariadb_test \
  -e MDB_NAME=wordpress \
  -e MDB_USER=wp_user \
  -e MDB_USER_PASS=wp_pass \
  -e MDB_ROOT_PASS=rootpass \
  mariadb
```

- `-d` lance en arrière-plan (détaché)
- `--name` donne un nom au conteneur
- `-e VARIABLE=valeur` permet de transmettre une variable d'environnement au lancement du docker
- `mariadb` est le nom de l'image utilisée (celle créée précédemment)

#### consulter les logs :

```bash
docker logs -f mariadb_test
```

- `-f` permet d'afficher les nouvelles lignes en direct s'il y en a

#### entrer dans le conteneur :

```bash
docker exec -it mariadb_test bash
```

- `-it` mode interactif avec pseudo terminal
- `mariadb_test` nom du conteneur
- `bash` lance un shell bash à l'intérieur

#### une fois dans le shell du conteneur, se connecter :

```bash
mariadb -u root -p"$MDB_ROOT_PASS"
```

- `-u` spécifie l'utilisateur
- `-p` permet d'entrer le mot de passe

#### une fois connecté au shell MariaDB, vérifier que la base de donnée `wordpress` existe :

```mariadb
SHOW DATABASES
```

Cette commande affiche le tableau avec les databases présentes. Elle doit afficher le nom de la base de données créée ainsi que les bases de données présentes par défaut :

```text
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| wordpress          |  ← si `MDB_NAME=wordpress`
+--------------------+
```

### DOCKER-COMPOSE

Maintenant que nous avons deux conteneurs, nous pouvons realiser notre premier fichier `docker-compose.yml`.

#### Qu'est-ce que `docker compose` ?

Docker Compose permet de lancer plusieurs conteneurs Docker en même temps, en définissant leur configuration (image, commandes, ports, variables, réseau, volumes partagés, etc.) dans un seul fichier `docker-compose.yml`.
Il simplifie l’orchestration des services en les connectant automatiquement sur un réseau commun et en gérant leur ordre de démarrage.

#### Structure d’un fichier `docker-compose.yml`

Un fichier `docker-compose.yml` définit la configuration de plusieurs services Docker dans une seule application.
Il se compose généralement des sections suivantes :

* **`services`** : liste les conteneurs à lancer (ex. : `nginx`, `wordpress`, `mariadb`, etc.).
* **`build` / `image`** : indique le chemin du `Dockerfile` ou l’image Docker à utiliser.
* **`ports`** : expose les ports du conteneur vers l’extérieur.
* **`environment`** : définit les variables d’environnement du service.
* **`volumes`** : permet de monter des fichiers ou dossiers entre l’hôte et le conteneur.
* **`networks`** : configure les réseaux pour permettre aux services de communiquer entre eux.

Grâce à `docker-compose`, tous ces services peuvent être démarrés et orchestrés ensemble avec une simple commande :

```bash
docker compose up
```

Et ils pourront être stoppés avec la commande :

```bash
docker compose down
```

#### Règles de syntaxe YAML pour Docker Compose

##### 1. **Clé suivie de deux-points**

Chaque **clé** est suivie d’un `:` puis d’un espace :

```yaml
services:
  mariadb:
    image: mariadb:latest
```

##### 2. **Indentation obligatoire (espaces, pas de tabulations)**

* L’indentation se fait uniquement avec des **espaces** (pas de tabulations)
* La **norme courante** est 2 espaces, mais 4 est accepté aussi.

```yaml
services:
  mariadb:
    image: mariadb
```

##### 3. **Les listes commencent par `-`**

Pour déclarer une **liste d’éléments** :

```yaml
ports:
  - "80:80"
  - "443:443"
```

Chaque `-` doit être aligné, **avec au moins un espace après**.


##### 4. **Les valeurs peuvent être :**

* Des chaînes (généralement sans guillemets, sauf si caractères spéciaux)
* Des booléens (`true`, `false`)
* Des entiers
* Des objets imbriqués

Exemples :

```yaml
restart: always
environment:
  WP_DEBUG: "true"
  SITE_NAME: "Mon site perso"
```

##### 5. **Les chaînes contenant des caractères spéciaux doivent être entre guillemets**

Notamment si elles contiennent `:`, `#`, ou commencent par `*`, `&`, `@`, etc.

```yaml
command: "npm run dev:watch"
```

#### Les variables d'environnement

Précédemment, nous avions lancé le conteneur MariaDB avec la commande suivante afin de lui transmettre directement les variables d’environnement :

```bash
docker run -e DB_NAME=wordpress \
           -e DB_USER=wp_user \
           -e DB_USER_PASS=wp_pass \
           -e DB_ROOT_PASS=rootpass \
           nom_de_l_image
```

Nous allons simplifier les choses en écrivant les variables d’environnement dans un fichier `.env` situé dans le même dossier que le fichier `docker-compose.yml` :

```env
DB_NAME=wordpress
DB_USER=wp_user
DB_USER_PASS=wp_pass
DB_ROOT_PASS=rootpass
```

Nous pourrons ainsi spécifier dans notre `docker-compose.yml` le fichier à utiliser pour récupérer automatiquement les variables d’environnement.

#### Creation de notre premier `docker-compose.yml`

A la racine du dossier `srcs/` de notre projet, nous allons creer un fichier `docker-compose.yml` temporaire pour tester le build et l'execution de nos deux conteneurs Nginx et MariaDB.

```yaml
services:
  mariadb:
    build: requirements/mariadb
    container_name: mariadb
    env_file: .env
    expose:
      - "3306"
    networks:
      - inception

  nginx:
    build: requirements/nginx
    container_name: nginx
    env_file: .env
    ports:
      - "443:443"
    networks:
      - inception

networks:
  inception:
    driver: bridge
```

#### Explications

Ce fichier permet de définir et lancer plusieurs conteneurs Docker avec une seule commande (`docker-compose up`).
Il définit ici deux services : **MariaDB** et **Nginx**, ainsi que les volumes et réseaux nécessaires.

##### Services

```yaml
services:
```

*Section principale définissant les conteneurs à créer.*

* `mariadb`

```yaml
  mariadb:
```

*Nom du service (aussi utilisé comme hostname dans le réseau Docker).*

```yaml
    build: requirements/mariadb
```

*Indique à Docker de construire l’image à partir du Dockerfile situé dans `requirements/mariadb`.*

```yaml
    container_name: mariadb
```

*Nom explicite donné au conteneur (sinon Docker en génère un automatiquement).*

```yaml
    env_file: .env
```

*Charge les variables d’environnement depuis le fichier `.env` (ex : `MDB_NAME`, `MDB_ROOT_PASS`, etc.).*

```yaml
    expose:
      - "3306"
```

*Indique que le port 3306 (port MySQL) est exposé **aux autres conteneurs** sur le réseau Docker.
Ce n’est **pas exposé à l’extérieur** de l’hôte (à la différence de `ports`).*

```yaml
    networks:
      - inception
```

*Connecte le service au réseau Docker nommé `inception` pour communiquer avec les autres services.*

##### `nginx`

```yaml
  nginx:
```

*Nom du service pour le serveur web.*

```yaml
    build: requirements/nginx
```

*Construit l’image à partir du Dockerfile dans `requirements/nginx`.*

```yaml
    container_name: nginx
```

*Nom explicite pour le conteneur.*

```yaml
    env_file: .env
```

*Charge les variables d’environnement nécessaires à Nginx (par exemple le domaine).*

```yaml
    ports:
      - "443:443"
```

*Expose le port HTTPS 443 **de l’hôte vers le conteneur** pour que le site soit accessible via navigateur.*
*Cela signifie : redirige le port 443 de la machine hôte vers le port 443 du conteneur.*
En Docker, un conteneur est isolé de l'extérieur. Pour le rendre accessible depuis l’hôte (et donc le navigateur ou d'autres services externes), il faut publier un port.

```yaml
    networks:
      - inception
```

*Connecte Nginx au réseau Docker `inception`, ce qui permet par exemple d’accéder à `mariadb` via le hostname `mariadb`.*

##### Réseau

Chaque conteneur lancé avec Docker Compose est connecté par défaut à un réseau isolé.
En définissant un réseau personnalisé (ici `inception`), tous les services y sont connectés et peuvent communiquer entre eux par leur nom de service (comme mariadb, nginx, wordpress…).

```yaml
networks:
  inception:
    driver: bridge
```

*Crée un réseau personnalisé de type `bridge` pour que les conteneurs puissent **se reconnaître entre eux par leur nom de service**.*

Ce réseau est de type `bridge`, le plus courant pour les réseaux internes.
Grâce à cela, dans le fichier de configuration WordPress ou Nginx, on peut définir mariadb comme adresse de la base de données, au lieu de chercher une IP.
Cela simplifie énormément l’interconnexion entre les services dans un environnement multi-conteneurs.

#### Tester le `docker-compose.yml`

Pour lancer l'exécution du `docker-compose`, placez-vous dans le répertoire contenant le fichier, puis tapez la commande suivante :

```bash
docker compose up
```

> Cette commande fait plusieurs choses importantes :
>
> 1. **Construit les images Docker** (si elles ne sont pas déjà présentes ou si le `Dockerfile` a changé), en se basant sur les instructions de chaque service défini dans le fichier `docker-compose.yml`.
>
> 2. **Crée les conteneurs** nécessaires, en utilisant ces images.
>
> 3. **Crée les réseaux et volumes** définis dans le fichier `docker-compose.yml` (s’ils n’existent pas déjà).
>
> 4. **Lance tous les conteneurs en parallèle**, en respectant les dépendances (`depends_on`) et les configurations (ports, variables d’environnement, volumes…).
>
> Par défaut, elle affiche les **logs de tous les conteneurs en temps réel** dans le terminal.
> Pour la lancer en arrière-plan (mode détaché), on peut utiliser :
>
> ```bash
> docker compose up -d
> ```
> 
> Cela permet de continuer à utiliser le terminal tout en laissant les conteneurs tourner en arrière-plan.

Ouvrez ensuite un navigateur internet et entrez dans la barre d'adresse :

```text
https://localhost
```

Le navigateur devrait renvoyer une erreur **403 Forbidden**, ce qui est **normal à ce stade** : Nginx tente d'accéder à WordPress, qui n'est pas encore installé (comme prévu dans sa configuration).

Vous pouvez également vous connecter au conteneur MariaDB avec la commande :

```bash
docker exec -it mariadb bash
```

Puis, connectez-vous au serveur MariaDB avec les identifiants définis dans votre fichier `.env` :

```bash
mariadb -u<nom_utilisateur> -p<mot_de_passe_utilisateur>
```

Une fois connecté, la commande suivante affichera la liste des bases de données (dont la base `wordpress`, si tout s’est bien déroulé) :

```sql
SHOW DATABASES;
```

---

## DOCKER WORDPRESS

WordPress est un système de gestion de contenu (CMS – Content Management System) open source, largement utilisé pour créer et administrer des sites web, des blogs ou même des boutiques en ligne.
Écrit en PHP et utilisant une base de données MySQL/MariaDB, il permet à des utilisateurs sans compétences en développement de publier du contenu facilement via une interface web intuitive.

Dans le cadre du projet Inception, ce conteneur permet d’héberger un site WordPress fonctionnel, configuré automatiquement au démarrage, et connecté au conteneur MariaDB pour la gestion des données.
L'installation est faite à l’aide de la ligne de commande `wp-cli`, ce qui permet une configuration rapide et sans intervention manuelle.

### FICHIER DE CONFIGURATION PHP-FPM (`www.conf`)

Comme pour MariaDB ou Nginx, nous allons commencer par creer un fichier de configuration PHP-FPM `www.conf` pour wordpress, que nous placerons dans le dossier `conf`.

PHP-FPM signifie PHP FastCGI Process Manager.
C’est une interface entre un serveur web (comme NGINX) et le moteur PHP.
Il permet d’exécuter des scripts PHP de manière performante, flexible, et sécurisée.

Les serveurs comme NGINX ne savent pas exécuter directement du PHP.
Ils transmettent donc les requêtes PHP à un service externe — ici, PHP-FPM — qui se charge de :
- lancer des processus PHP
- exécuter le code PHP (comme index.php)
- renvoyer le résultat (HTML) à NGINX pour affichage

#### Fonctionnement de PHP-FPM :
- Le serveur NGINX reçoit une requête vers un fichier .php
- Il la redirige via fastcgi_pass vers PHP-FPM
- PHP-FPM fait tourner le code PHP avec les bonnes variables d’environnement, les fichiers, etc.
- Il renvoie le résultat à NGINX, qui l’affiche au navigateur

> PHP-FPM (FastCGI Process Manager) est un service qui permet d’exécuter le code PHP à la place de NGINX.
> Il agit comme une passerelle entre le serveur web et le moteur PHP, en lançant des processus PHP configurables à la demande.
> Dans ce projet, PHP-FPM est utilisé pour traiter les requêtes envoyées au site WordPress de manière performante et sécurisée.

#### Le fichier `www.conf`

```conf
[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
clear_env = no
```

#### Explications

Le fichier de configuration PHP-FPM (`www.conf`) configure **PHP-FPM**, le gestionnaire de processus FastCGI utilisé pour exécuter les scripts PHP dans le conteneur WordPress.
Voici une explication des directives utilisées :

```ini
[www]
```

Déclare un nouveau *pool* de processus nommé `www`. Chaque pool est une instance indépendante de PHP-FPM.

> Chaque fichier de configuration commence par un nom de pool entre crochets, ici [www].
> Il permet de distinguer plusieurs groupes de processus si nécessaire (non utile pour Inception, mais bon à savoir).
> Un pool est un groupe indépendant de processus PHP-FPM qui gère les requêtes PHP.
> Chaque pool fonctionne comme une "unité de traitement" avec sa propre configuration et ses propres processus.
> Chaque pool peut :
> - écouter sur un port ou un socket différent
> - utiliser un utilisateur/groupe système différent
> - avoir sa propre stratégie de gestion de charge (nombre de processus, etc.)
> - charger un fichier php.ini différent
> - être isolé pour des raisons de sécurité ou performance
> Autrement dit : un pool = un ensemble de workers PHP qui tournent sous certaines règles.

```ini
user = www-data
group = www-data
```

Spécifie l’utilisateur et le groupe Unix sous lesquels s’exécuteront les processus PHP.
`www-data` est l’utilisateur standard pour les services web (NGINX, PHP).

```ini
listen = 0.0.0.0:9000
```

Indique que PHP-FPM écoutera les connexions FastCGI sur le port TCP 9000.
Cela permet à NGINX de communiquer avec PHP-FPM via le réseau interne Docker (`fastcgi_pass wordpress:9000;`).

```ini
listen.owner = www-data
listen.group = www-data
```

Définit les droits d’accès au socket ou au port.
Ici, même si on utilise un port TCP, cette configuration est conservée pour rester cohérente ou dans le cas d’un passage à un socket Unix.

```ini
pm = dynamic
```

Active la gestion dynamique des processus.
PHP-FPM ajustera automatiquement le nombre de processus enfants en fonction de la charge du serveur.

> Puisque le paramètre `pm` est défini sur `dynamic`, nous devons obligatoirement définir les paramètres suivants :
> `pm.max_children`, `pm.start_servers`, `pm.min_spare_servers`, `pm.max_spare_servers`.
> Si nous avions utilisé `pm = static`, seul le paramètre `pm.max_children` aurait été obligatoire.

```ini
pm.max_children = 5
```

Nombre maximal de processus enfants autorisés.
Cela limite l’utilisation mémoire dans un conteneur léger.

```ini
pm.start_servers = 2
```

Nombre de processus lancés au démarrage du service.

```ini
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

Nombre minimal et maximal de processus inactifs que PHP-FPM doit garder prêts à traiter les requêtes.
Permet d’éviter les délais de démarrage lors d’un pic de charge.

```ini
clear_env = no
```

Permet à PHP-FPM d’hériter des variables d’environnement.
C’est **essentiel** dans le contexte Docker, car WordPress utilise ces variables (définies dans le `.env`) pour sa configuration automatique via WP-CLI.

### COMPOSANTS NECESSAIRES A L'EXECUTION DE WORPRESS

Avant de créer le `Dockerfile`, faisons un point sur les composants à installer pour faire fonctionner Woorpress :

Le conteneur WordPress repose sur une image de base Debian minimale.
Il est nécessaire d'y installer manuellement PHP, les extensions requises, ainsi que des outils système complémentaires pour que WordPress puisse fonctionner correctement.
Voici la liste des paquets à installer dans le `Dockerfile` :

#### PHP et son interpréteur

* `php`
  Installe le moteur PHP ainsi que le binaire principal (`php`).
  C’est la base pour exécuter tout code WordPress, qui repose entièrement sur PHP.

  > PHP est un langage de programmation côté serveur principalement utilisé pour créer des sites web dynamiques, comme WordPress, en générant du HTML en réponse aux requêtes HTTP.

* `php-fpm`
  Installe **PHP-FPM** (FastCGI Process Manager), un gestionnaire de processus permettant à un serveur web comme **NGINX** de déléguer l’exécution des scripts PHP à un service dédié via le protocole FastCGI.
  Obligatoire pour séparer les rôles entre conteneurs (NGINX ↔ WordPress).

#### Extensions PHP obligatoires pour WordPress

* `php-mysql`
  Cette extension permet à PHP d’interagir avec une base de données MySQL ou MariaDB via les interfaces MySQLi (améliorée) et PDO_MySQL (orientée objet). WordPress utilise ces interfaces pour établir une connexion avec la base de données, exécuter des requêtes SQL, récupérer les articles, les utilisateurs, les paramètres du site, etc.
  Sans cette extension, aucune connexion à la base de données ne serait possible, ce qui empêcherait complètement WordPress de fonctionner (le site afficherait une erreur critique dès le chargement).
  C’est l’une des extensions absolument indispensables pour toute installation WordPress.

* `php-curl`
  Permet à WordPress d’effectuer des **requêtes HTTP depuis le serveur**, ce qui est indispensable pour installer des extensions, interagir avec des API, ou télécharger des fichiers.

* `php-gd`
  Bibliothèque de manipulation d’images. Nécessaire pour **générer des vignettes, redimensionner des images** dans la médiathèque WordPress, etc.

* `php-mbstring`
  Gère les chaînes multioctets (UTF-8, Unicode). Indispensable pour **la compatibilité avec les langues internationales** et de nombreux plugins.

* `php-xml`
  Permet de **lire et écrire des fichiers XML**, notamment pour la gestion des flux RSS, des éditeurs, et des APIs internes.

* `php-xmlrpc`
  Supporte les **requêtes distantes XML-RPC**, utilisées par l’API historique de WordPress. Encore utilisé par certains clients mobiles, éditeurs distants ou plugins.

* `php-soap`
  Permet les communications via le protocole **SOAP**, utilisé par certains plugins tiers ou services d’import/export.

* `php-zip`
  Permet la **lecture et l’extraction d’archives ZIP**, indispensable pour l'installation de plugins, thèmes ou mises à jour via l’interface WordPress.

* `php-intl`
  Fournit des fonctions de **localisation, tri, et mise en forme des dates et chaînes** selon la langue. Requis pour la prise en charge de WordPress en français et d'autres langues.

* `php-opcache`
  Améliore les performances de PHP en **mémorisant le code compilé**. Fortement recommandé pour tout site WordPress, même en développement.

### # Outils complémentaires

* `curl`
  Utilisé pour télécharger **WP-CLI** et WordPress. Outil en ligne de commande plus polyvalent que `wget`.

* `mariadb-client`
  Permet de tester ou diagnostiquer manuellement la connexion à la base de données depuis le conteneur WordPress. Utile pendant le développement, mais pas strictement requis à l’exécution.

### WP-CLI

Le sujet Inception **interdit toute configuration manuelle post-déploiement**. Or, une installation WordPress classique nécessite de :

1. Créer manuellement le fichier `wp-config.php` (avec les infos de la base de données)
2. Lancer le setup via un navigateur web
3. Entrer les identifiants admin, nom du site, URL, etc.
4. Créer un utilisateur supplémentaire (facultatif)

Ces étapes nécessitent une interface web et une interaction humaine, **ce qui est incompatible avec un déploiement automatisé dans un conteneur**.

En plus d'installer `php` (et ses dépendances) et `wordpress`, nous allons donc devoir installer **WP-CLI**, un outil en ligne de commande permettant de gérer une installation WordPress de façon automatisée, sans passer par l’interface web.
Une fois installé comme exécutable dans `/usr/local/bin`, il peut être utilisé via la simple commande `wp`.

WP-CLI permet d’automatiser :

* La création du fichier `wp-config.php` :

  ```bash
  wp config create --dbname="$MDB_NAME" --dbuser="$MDB_USER" --dbpass="$MDB_USER_PASS" --dbhost="mariadb"
  ```

* L'installation complète de WordPress :

  ```bash
  wp core install --url="$DOMAIN_NAME" --title="$WEBSITE_TITLE" --admin_user="$WP_ADMIN_LOGIN" ...
  ```

* La création d’un compte utilisateur secondaire :

  ```bash
  wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" --role=author ...
  ```

* La configuration de Redis ou d’autres paramètres via :

  ```bash
  wp config set WP_REDIS_HOST redis
  ```

> WP-CLI est un composant **clé** pour automatiser toute l’installation de WordPress dans un environnement Docker, comme exigé dans le projet Inception.
> Il remplace toutes les étapes interactives du setup WordPress par des **commandes exécutables dans un script**, ce qui garantit un déploiement cohérent, rapide et sans intervention manuelle.

### DOCKERFILE WORDPRESS

#### Contenu du fichier

```conf
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

RUN curl -o /var/www/wordpress.tar.gz https://fr.wordpress.org/wordpress-6.8.2-fr_FR.tar.gz && \
    tar -xzf /var/www/wordpress.tar.gz -C /var/www && \
    rm /var/www/wordpress.tar.gz && \
    chown -R www-data:www-data /var/www/wordpress

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

EXPOSE 9000

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /var/www/wordpress

ENTRYPOINT [ "/entrypoint.sh" ]
```

#### Explications

```dockerfile
FROM debian:11.11
```

Définit l’image de base. Ici, une image Debian stable (version 11.11) est utilisée pour sa compatibilité avec PHP 7.4, requis par de nombreux plugins WordPress.

```dockerfile
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
```

Met à jour les paquets et installe :

* **PHP** et son interpréteur PHP-FPM
* Toutes les **extensions nécessaires à WordPress** : base de données (`php-mysql`), gestion du texte (`php-mbstring`), manipulation d'images (`php-gd`), gestion XML/RSS (`php-xml`), SOAP/XML-RPC (`php-soap`, `php-xmlrpc`), fichiers ZIP (`php-zip`), internationalisation (`php-intl`), et performances (`php-opcache`)
* Le **client MariaDB** pour tester la connexion à la base
* **curl**, utilisé pour télécharger WordPress et WP-CLI

Enfin, le cache des paquets est nettoyé pour alléger l’image.

```dockerfile
RUN mkdir -p /run/php
```

Cette commande crée manuellement le répertoire `/run/php`, qui est nécessaire au fonctionnement de PHP-FPM. En effet, lors de son démarrage, PHP-FPM cherche à créer un socket Unix (fichier spécial de communication inter-processus) dans ce dossier, par défaut à l’emplacement suivant : `/run/php/php7.4-fpm.sock`.
Si ce dossier n’existe pas, le service PHP-FPM échoue au démarrage.
Créer ce dossier préventivement garantit la compatibilité et évite toute erreur au démarrage de PHP-FPM, surtout dans un conteneur léger où beaucoup de répertoires ne sont pas créés automatiquement.

```dockerfile
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
```

Copie le fichier de configuration `www.conf` dans le dossier de configuration de PHP-FPM.
Ce fichier définit :

* le port d'écoute (9000)
* l’utilisateur (`www-data`)
* la stratégie de gestion des processus (`pm = dynamic`, etc.)
* le transfert des variables d’environnement (`clear_env = no`)

```dockerfile
RUN curl -o /var/www/wordpress.tar.gz https://fr.wordpress.org/wordpress-6.8.2-fr_FR.tar.gz && \
    tar -xzf /var/www/wordpress.tar.gz -C /var/www && \
    rm /var/www/wordpress.tar.gz && \
    chown -R www-data:www-data /var/www/wordpress
```

Télécharge l’archive WordPress officielle en français (version 6.8.2), l’extrait dans `/var/www`, puis supprime l’archive.
Les fichiers sont ensuite attribués à l’utilisateur `www-data` pour permettre à PHP-FPM d’y accéder en lecture/écriture.

```dockerfile
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
```

Télécharge WP-CLI (outil en ligne de commande pour gérer WordPress), lui donne les droits d’exécution, et le déplace dans `/usr/local/bin` pour pouvoir l’appeler simplement avec `wp`.

```dockerfile
EXPOSE 9000
```

Indique que le conteneur écoute sur le port **9000**, utilisé par **PHP-FPM** pour recevoir les requêtes FastCGI du conteneur NGINX.

```dockerfile
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```

Copie le script `entrypoint.sh` dans le conteneur et le rend exécutable.
Ce script initialise WordPress automatiquement au démarrage, en utilisant WP-CLI (`wp config create`, `wp core install`, etc.).

```dockerfile
WORKDIR /var/www/wordpress
```

Fixe le répertoire de travail pour les instructions suivantes et pour le conteneur au runtime.
Cela permet notamment d'exécuter `wp` sans avoir à spécifier `--path`.

```dockerfile
ENTRYPOINT [ "/entrypoint.sh" ]
```

Définit le point d’entrée du conteneur : le script `entrypoint.sh` sera exécuté automatiquement au lancement, pour configurer et lancer WordPress.

### LE SCRIPT `entrypoint.sh`

Dans un conteneur Docker, le script `entrypoint.sh` agit comme **le point de départ** de l’exécution.
C’est lui qui est appelé automatiquement au lancement du conteneur (grâce à la directive `ENTRYPOINT` dans le `Dockerfile`).

#### Rôle du script

Dans le cadre du projet Inception, ce script permet de **préparer et lancer automatiquement WordPress** dès le démarrage du conteneur, sans aucune intervention manuelle.

Concrètement, il va :

1. Vérifier si WordPress est déjà configuré (ex : si `wp-config.php` existe)
2. Si ce n’est pas le cas :
   * Générer un fichier `wp-config.php` avec les bonnes variables d’environnement
   * Installer WordPress (`wp core install`) avec les identifiants admin, l’URL, le titre du site, etc.
   * Créer un utilisateur secondaire
   * Appliquer éventuellement d’autres réglages (comme Redis pour les bonus)
3. Démarrer le service PHP-FPM en mode **foreground** (`-F`) pour que le conteneur reste actif

#### Pourquoi ne pas faire ça dans le Dockerfile ?

Parce que le `Dockerfile` est **exécuté à la construction de l’image**, et que WordPress **doit être configuré dynamiquement à chaque exécution du conteneur**, en fonction :

* des **variables d’environnement** (`MDB_NAME`, `WP_ADMIN_LOGIN`, etc.)
* de l’état de la base de données (vide ou non)
* ou même du volume partagé (le `wp-config.php` peut déjà exister)

Seul un **script exécuté au runtime** (au démarrage du conteneur) peut gérer cette logique conditionnelle.

#### Variables d'environnement

Afin de configurer `worpdress` nous allons devoir ajouter certaines variables d'environnement dans notre fichier `.env` :

* `DOMAIN_NAME`
  Le nome de domaine : <login>.42.fr comme exigé par le sujet

* `WEBSITE_TITLE`
  Le nom du site

* `WP_ADMIN_LOGIN`
  Le login de l'administrateur du site

* `WP_ADMIN_PASS`
  Le mot de passe administrateur

* `WP_ADMIN_EMAIL`
  Le mail de l'administrateur

* `WP_USER_LOGIN`
  Le login d'utilisateur

* `WP_USER_PASS`
  Le mot de passe de l'utilisateur

```env
# MariaDB Configuration
MDB_NAME=inception
MDB_USER=<votre_nom_d_utilisateur>
MDB_ROOT_PASS=<password>
MDB_USER_PASS=<password>

# WordPress Configuration
DOMAIN_NAME=<login>.42.fr
WEBSITE_TITLE=Inception
WP_ADMIN_LOGIN=<votre_nom_d_admin>
WP_ADMIN_EMAIL=<votre_mail_admin>
WP_ADMIN_PASS=<password>
WP_USER_LOGIN=<votre_nom_d_utilisateur>
WP_USER_EMAIL=<votre_mail_utilisateur>
WP_USER_PASS=<password>
```

#### Le script

```bash
#!/bin/bash

until mysqladmin ping -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" --silent; do
  # Afficher un message toutes les 2 secondes pendant l'attente
  echo "Waiting for MariaDB to be ready..."
  sleep 2
done

if [ ! -f wp-config.php ]; then
	echo "Creating wp-config.php..."

	wp config create \
		--dbname="$MDB_NAME" \
		--dbuser="$MDB_USER" \
		--dbpass="$MDB_USER_PASS"\
		--dbhost="mariadb" \
		--path=/var/www/wordpress \
		--allow-root

	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WEBSITE_TITLE" \
		--admin_user="$WP_ADMIN_LOGIN" \
		--admin_password="$WP_ADMIN_PASS" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	echo "Creating wp user..."

	wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$WP_USER_PASS" \
		--allow-root

	echo "WordPress installtion ended."

else
	echo "WordPress is already configured."
fi

echo "Launching PHP-FPM..."
exec /usr/sbin/php-fpm7.4 -F
```

#### Explications

```bash
#!/bin/bash
```

Indique que le script doit être interprété avec Bash.

```bash
if [ ! -f wp-config.php ]; then
```

Teste si le fichier `wp-config.php` n’existe pas encore. Si c’est le cas, cela signifie que WordPress n’est pas encore configuré

```bash
until mysqladmin ping -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" --silent; do
  echo "Waiting for MariaDB to be ready..."
  sleep 2
done
```

Avant de lancer l'installation de WordPress avec WP-CLI, on vérifie que le service MariaDB est bien opérationnel.
On utilise `mysqladmin ping` pour tester la connexion à la base en boucle.
Tant que la base de données n'est pas disponible (le conteneur MariaDB démarre souvent plus lentement), le script attend et affiche un message toutes les 2 secondes.
Cela garantit que WordPress ne tente pas de se connecter trop tôt à MariaDB, ce qui entrainerait une erreur d'installation.

```bash
    wp config create \
        --dbname="$MDB_NAME" \
        --dbuser="$MDB_USER" \
        --dbpass="$MDB_USER_PASS" \
        --dbhost="mariadb" \
        --path=/var/www/wordpress \
        --allow-root
```

Utilise `wp-cli` pour générer un fichier `wp-config.php` à partir des variables d’environnement définies dans le `.env`.
`--allow-root` est requis car `wp-cli` est exécuté avec les droits root dans le conteneur.
Le fichier est généré dans `/var/www/wordpress`.

```bash
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="$WEBSITE_TITLE" \
        --admin_user="$WP_ADMIN_LOGIN" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
```

Lance l’installation de WordPress avec les informations du site (URL, titre) et les identifiants de l’administrateur principal.
L’option `--skip-email` désactive l’envoi d’un mail de confirmation (inutile dans ce contexte).

```bash
    wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --allow-root
```

Crée un second utilisateur WordPress avec le rôle `author`, utile pour les tests ou démontrer l’accès multi-utilisateur.

```bash
exec /usr/sbin/php-fpm7.4 -F
```

Lance PHP-FPM en mode **foreground** (`-F`) pour que le conteneur reste actif.
Le `exec` remplace le processus shell actuel par PHP-FPM, comme le recommande Docker.

---

## FINALISER LE FICHIER `docker-compose.yml`

Maintenant que nous avons nos trois `Dockerfile`, nous pouvons compléter le `docker-compose.yml` pour intégrer le conteneur `wordpress`.

Mais avant cela, nous devons aborder deux nouveaux concepts de `docker compose` :
- les volumes
- les `depends_on`
- les `restart`

### VOLUMES : PERSISTANCE DES DONNEES

Dans Docker, un **volume** est un espace de stockage indépendant du cycle de vie des conteneurs.
Il permet de **conserver des données même si un conteneur est supprimé ou reconstruit**, en les stockant sur la machine hôte.
Dans le cadre du projet Inception, l'utilisation de volumes est **obligatoire** pour assurer la **persistance des données de MariaDB** (les bases de données) et de **WordPress** (les fichiers, plugins, images uploadées, etc.).

Les volumes sont déclarés dans la section `volumes:` du fichier `docker-compose.yml`.
Pour respecter les contraintes du sujet, ils doivent utiliser le **type `none`** et être **montés sur des dossiers locaux situés dans `~/data`**, via l’option `device`.

> Dans Inception, le sujet impose que les volumes ne soient **ni anonymes, ni purement nommés**, mais qu’ils soient **explicitement liés à un répertoire local sur la machine hôte**, situé dans `~/data`.
>
> Pour cela, on utilise le **driver `local`** avec l’option `driver_opts` :
>
> - `type: none` indique que le volume **n’utilise aucun système de fichiers spécial** (comme tmpfs ou nfs).
> - `device: ~/data/<service>` précise **le chemin exact sur le système hôte** à monter dans le conteneur.
> - `o: bind` signifie qu’il s’agit d’un **montage de type "bind"**, qui relie directement le dossier local au dossier interne du conteneur.
>
> Ce mécanisme permet de **visualiser et manipuler les données directement sur la machine**, tout en respectant les exigences du sujet (un dossier par service dans `~/data/`).

Puisque les données vont être sauvegardées en local sur notre machine hôte, il nous faut créer les dossiers nécessaires sur la machine hôte :

```bash
mkdir -p ~/data/worpress ~/data/mariadb
```

> 📝 **Note importante :**
>
> La commande suivante permet d’arrêter tous les conteneurs lancés avec `docker compose`, et de supprimer les volumes Docker associés :
>
> ```bash
> docker compose down -v
> ```
>
> Cependant, dans le cadre du projet **Inception**, les volumes ne sont **pas de vrais volumes Docker**, mais des **dossiers locaux liés par un bind mount** (comme `~/data/mariadb`).
>
> ⚠️ Cela signifie que **le contenu de ces dossiers n’est pas supprimé** par la commande `docker compose down -v`.
>
> Pour réinitialiser complètement l’environnement (bases de données, fichiers WordPress…), il faut aussi **supprimer manuellement** les données locales :
>
> ```bash
> sudo rm -rf ~/data/mariadb/* ~/data/wordpress/*
> ```

### GERER L'ORDRE DE DEMARRAGE AVEC `depends_on`

Dans un environnement multi-conteneurs, il est essentiel que certains services soient démarrés **avant** d'autres.
Par exemple, WordPress doit pouvoir se connecter à MariaDB au lancement.
La directive `depends_on` permet de définir ces **relations de dépendance** dans le fichier `docker-compose.yml`.

Lorsqu’un service A dépend d’un service B (`depends_on: - B`), Docker veillera à **lancer B avant A**, mais ne garantit pas que B soit **entièrement prêt** (ex. : que MariaDB accepte déjà les connexions).
Pour cela, des mécanismes comme les `healthcheck` ou des scripts d’attente dans le `entrypoint.sh` peuvent être utilisés si besoin.
Dans Inception, `depends_on` et les précautions prises dans les scripts sont suffisants pour assurer un lancement structuré des services.

### POLITIQUE DE REDEMARRAGE AVEC `restart`

Le sujet de **Inception** nous dit explicitement que les conteneurs doivent redémarre en cas de crash.
Pour cela nous allons utiliser la directive `restart` et lui donner la valeur `unless-stopped`, ce qui veut dire que le conteneur redémarrera automatiquement s'il s'arrête sauf si nous l'avons arrêté nous-même manuellement (avec `docker stop` par exemple).

> L'option `restart` permet de définir le comportement de redémarrage automatique des conteneurs.
> Les valeurs possibles sont :
> 
> * `no` *(ou valeur par défaut)* :
>   Le conteneur ne redémarre pas automatiquement.
> * `always` :
>   Le conteneur redémarre systématiquement, même s’il a été arrêté manuellement.
> * `on-failure` :
>   Le conteneur redémarre uniquement en cas d’échec (code de sortie différent de `0`).
> * `on-failure:N` :
>   Même comportement que `on-failure`, mais limite le nombre de redémarrages à `N`.
> * `unless-stopped` :
>   Le conteneur redémarre automatiquement **sauf** s’il a été arrêté manuellement.
> 
> Cette option est ignorée si vous utilisez `docker compose run`, mais elle fonctionne avec `docker compose up`.

### LE FICHIER FINAL

```yaml
services:
  mariadb:
    build: requirements/mariadb
    container_name: mariadb
    env_file: .env
    restart: unless-stopped
    volumes:
      - mariadb:/var/lib/mysql
    expose:
      - "3306"
    networks:
      - inception

  wordpress:
    build: requirements/wordpress
    container_name: wordpress
    env_file: .env
    restart: unless-stopped
    depends_on:
      - mariadb
    volumes:
      - wordpress:/var/www/wordpress
    expose:
      - "9000"
    networks:
      - inception

  nginx:
    build: requirements/nginx
    container_name: nginx
    env_file: .env
    restart: unless-stopped
    depends_on:
      - wordpress
    ports:
      - "443:443"
    volumes:
      - wordpress:/var/www/wordpress
    networks:
      - inception

volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      device: ~/data/mariadb
      o: bind

  wordpress:
    driver: local
    driver_opts:
      type: none
      device: ~/data/wordpress
      o: bind

networks:
  inception:
    driver: bridge
```

### EXPLICATIONS

Ce fichier définit les trois services principaux du projet Inception : **MariaDB**, **WordPress** et **Nginx**, ainsi que les volumes et le réseau nécessaires à leur bon fonctionnement.

#### `services:`

Contient la définition des trois conteneurs que Docker Compose va construire et orchestrer.

* `mariadb`

```yaml
mariadb:
  build: requirements/mariadb
  container_name: mariadb
  env_file: .env
  restart: unless-stopped
  volumes:
    - mariadb:/var/lib/mysql
  expose:
    - "3306"
  networks:
    - inception
```

* `build`: indique le chemin vers le `Dockerfile` de MariaDB.
* `container_name`: nom fixe du conteneur, facilitant les appels réseau (ex: `db_host = mariadb`)
* `env_file`: charge les variables d’environnement depuis le fichier `.env`
* `volumes`: monte un volume pour **persister les données MySQL** dans `~/data/mariadb` :
  Dans le conteneur, les fichiers de base de données sont écrits dans `/var/lib/mysql`.
  Sur la machine hôte, ces fichiers sont stockés dans le dossier `~/data/mariadb`, comme précisé plus loin dans le bloc `volumes`.
  Les deux emplacements sont **liés en temps réel** : toute écriture dans `/var/lib/mysql` sera immédiatement visible dans `~/data/mariadb`.
* `expose`: rend le port 3306 **disponible pour les autres services Docker** (mais pas exposé à l’extérieur).
* `networks`: rattache le conteneur au réseau interne `inception`.

* `wordpress`

```yaml
wordpress:
  build: requirements/wordpress
  container_name: wordpress
  env_file: .env
  restart: unless-stopped
  depends_on:
    - mariadb
  volumes:
    - wordpress:/var/www/wordpress
  expose:
    - "9000"
  networks:
    - inception
```

* `build`: chemin vers le `Dockerfile` WordPress (PHP-FPM).
* `container_name`: nom fixe du conteneur.
* `env_file`: charge les variables nécessaires à l’installation (BDD, comptes, etc.).
* `depends_on`: attend que `mariadb` soit **démarré** (ne garantit pas qu’il soit **prêt**).
* `volumes`: monte le dossier WordPress, partagé avec Nginx, pour **persister plugins et uploads**.
* `expose`: rend le port PHP-FPM 9000 disponible pour Nginx.
* `networks`: rattache le conteneur au réseau `inception`.

* `nginx`

```yaml
nginx:
  build: requirements/nginx
  container_name: nginx
  env_file: .env
  depends_on:
    - wordpress
  ports:
    - "443:443"
  volumes:
    - wordpress:/var/www/wordpress
  networks:
    - inception
```

* `build`: chemin vers le `Dockerfile` Nginx.
* `container_name`: nom du conteneur frontal.
* `env_file`: accessible si tu veux passer des variables à la config Nginx.
* `depends_on`: s’assure que `wordpress` est lancé **avant** `nginx`.
* `ports`: redirige le port HTTPS 443 de l’hôte vers le conteneur (accès navigateur).
  (La syntaxe utilisée est : <port_hôte>:<port_conteneur>)
* `volumes`: partage le code WordPress pour que Nginx serve les fichiers statiques.
* `networks`: même réseau que les autres services.

#### `volumes:`

Définit les volumes montés dans chaque conteneur pour **préserver les données** et respecter les règles d’Inception.

```yaml
volumes:
  mariadb:
    driver: local
    driver_opts:
      type: none
      device: ~/data/mariadb
      o: bind

  wordpress:
    driver: local
    driver_opts:
      type: none
      device: ~/data/wordpress
      o: bind
```

* `type: none`: n'utilise pas de FS spécial (ni tmpfs, ni nfs).
* `device`: chemin absolu sur la machine hôte (dans `~/data`).
* `o: bind`: fait un lien direct entre ce dossier et le conteneur.
* Cela permet de **manipuler les données WordPress et MariaDB même depuis la machine hôte**.

#### `networks:`

Déclare le réseau interne `inception`, utilisé pour que les conteneurs puissent se **communiquer directement** par leur nom.

```yaml
networks:
  inception:
    driver: bridge
```

* `bridge`: réseau Docker classique, adapté aux communications internes entre services.

### LES COMMANDES COURANTES POUR DOCKER COMPOSE

* `docker compose up`
  Construit les images (si besoin) et démarre tous les services définis dans le `docker-compose.yml`.

* `docker compose up --build`
  Force la reconstruction des images avant de démarrer les services.

* `docker compose up -d`
  Lance les services en **mode détaché** (en arrière-plan).

* `docker compose down`
  Arrête tous les services et supprime les conteneurs, réseaux et fichiers temporaires.
  Les **volumes persistants** (comme les données MySQL) ne sont **pas supprimés**.

* `docker compose down -v`
  Supprime également les **volumes liés aux services**. Attention : les données seront alors perdues.

* `docker compose ps`
  Affiche l’état des conteneurs gérés par Docker Compose.

* `docker compose stop`
  Arrête les conteneurs sans les supprimer (peut être relancé avec `start`).

* `docker compose start`
  Redémarre les conteneurs précédemment arrêtés.

* `docker compose restart`
  Redémarre tous les services. Utile pour appliquer des modifications de configuration.

* `docker compose logs`
  Affiche les logs de tous les services.

* `docker compose logs -f`
  Affiche les logs en temps réel (**follow**).

* `docker compose exec <service> <commande>`
  Exécute une commande dans un conteneur déjà en cours d’exécution (ex : `bash`, `mysql`, etc.).

* `docker compose rm`
  Supprime les conteneurs arrêtés manuellement (sans passer par `down`).

---

## TESTS

Le projet étant bientôt terminé, il est temps de tester si tout fonctionne correctement.
Voici comment vérifier que notre environnement Docker Compose fonctionne correctement, que WordPress est opérationnel et que les données sont bien persistantes.

### 1. LANCER `docker compose`

Depuis le répertoire racine du projet, lancez :

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d
```

Cela démarre tous les conteneurs (WordPress, MariaDB, etc.) en arrière-plan.

Vous pouvez vérifier qu'ils tournent avec :

```bash
docker ps
```

Les trois conteneurs nginx, MariaDB et wordpress doivent apparaître dans la liste.

### 2. OUVRIR WORDPRESS DANS LE NAVIGATEUR

Une fois les conteneurs démarrés, ouvrez votre navigateur et allez sur :

```
https://localhost
```

Vous devriez voir la page d’accueil de WordPress avec l’article de bienvenue.

### 3. TESTER LA PERSISTANCE DES DONNEES

#### a. Créer une nouvelle page dans WordPress

1. Connectez-vous à l’interface d’administration (en utilisant l'identifiant et le mot de passe défini pour l'administrateur wordpress dans le fichier `.env`):

   ```
   https://localhost/wp-admin
   ```

3. Allez dans **Pages > Ajouter**

4. Créez une page appelée **"Test Persistance"** et publiez-la

#### b. Redémarrer la VM hôte (et pas seulement Docker)

1. Stoppez docker avec la commande suivante (qui stoppe les conteneurs et supprime les images sans supprimez les volumes) :
   
   ```bash
	docker compose stop
   ```
   
3. Éteignez totalement la machine virtuelle (VM)
4. Redémarrez-la
5. Relancez les conteneurs :

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d
```

Le `-f` sert à spécifier le chemin du fichier `docker-compose.yml`. Il serait inutile si nous nous trouvions dans le répertoire contenant le fichier.

#### c. Vérifier que la page existe toujours

Retournez sur `https://localhost`, puis allez dans **Pages**.
Vous devriez voir **"Test Persistance"** toujours présente. Si ce n'est pas le cas, c'est qu'il y a un problème avec les volumes.

### 4. Vérifier la présence de la page dans la base de données MariaDB

Vous pouvez accéder directement à la base MariaDB pour voir si la page est bien enregistrée :

#### a. Entrer dans le conteneur MariaDB

```bash
docker exec -it mariadb bash
```

#### b. Se connecter à MariaDB

```bash
mariadb -u<VOTRE_UTILISATEUR> -p<VOTRE_MOT_DE_PASSE>
```

> Remplacez `<VOTRE_UTILISATEUR>` et <VOTRE_MOT_DE_PASSE> par les valeurs de `MDB_USER` et `MDB_USER_PASS` dans votre `.env`.

#### c. Interroger la base

```sql
USE inception;
SELECT ID, post_title FROM wp_posts;
```

Vous devriez voir la page **"Test Persistance"** dans les résultats.

Si tous ces tests passent, votre installation est fonctionnelle, persistante, et bien connectée entre les services WordPress et MariaDB.

---

## MAKEFILE ET DERNIERES TOUCHES

Maintenant que le projet fonctionne, il nous manque quelques détails à finaliser.

### NOM DE DOMAINE

Pour le moment, nous accédons à wordpress dans le navigateur par :

```
https://localhost
```

Or le sujet exige que nous puissions aussi y accéder par notre nom de domaine (`<votre_login>.42.fr`).
Pour que cela fonctionne en local, il faut déclarer ce nom de domaine dans le DNS de la machine, en l’associant à `127.0.0.1` (l’adresse de loopback).
Il faut donc éditer le fichier `/etc/hosts` et y ajouter la ligne suivante :

```
127.0.0.1 <votre_login>.42.fr
```

> Remplacez `<votre_login>` par votre vrai identifiant 42 (ex : `jdupont.42.fr`).

Cette redirection ne fonctionne que sur **votre machine locale**, elle n’est pas publique.

### MAKEFILE

Le sujet n'est pas très explicite au sujet du Makefile. Mais nous pouvons assumer qu'il doit contenir au minimum :

- une règle pour **lancer les conteneurs**
- une autre pour **les arrêter sans supprimer les volumes**, afin de préserver la persistance des données

#### Makefile minimum

Un Makefile minimum pourrait se contenter de :

```Makefile
all:
	docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d

clean:
	docker compose -f srcs/docker-compose.yml down --rmi all
```

> L'option `--rmi all` permet de détruire les images.

#### Makefile complet

Pour ma part, j'ai ajouté quelques règles à mon Makefile afin de :

- Vérifier que le fichier `.env` est bien présent lors de l'éxecution de la commande `make`
- Vérifier que chacune des  variables d'environnement nécessaires au projet sont bien existantes et non nulles (ce qui me permet au passage de supprimer les vérifications de variables dans les scripts)
- Vérifier que les dossiers `~/data/wordpress` et `~/data/mariadb` existent (nécessaires pour la persistances des données) ou les créer lors de l'éxécution si ce n'est pas le cas
- Vérifier que le DOMAIN_NAME soit bien présent dans le fichier `/etc/hosts` ou bien ajouter la ligne nécesaire au fichier si ce n'est pas le cas

Enfin j'ai ajouté les règles :

- `reset` qui stoppe les conteneurs, supprime les images et supprime les volumes docker ainsi que les répertoires `~/data/wordpress` et `~/data/mariadb` sur la machine hôte (entraînant la fin de la persistance des données)
- `down` qui stoppe les conteneurs sans détruire les images

```bash
SHELL := /bin/bash
COMPOSE_PATH := srcs/docker-compose.yml
ENV_FILE := srcs/.env
REQUIRED_VARS := MDB_NAME \
                 MDB_USER \
                 MDB_ROOT_PASS \
                 MDB_USER_PASS \
                 DOMAIN_NAME \
                 WEBSITE_TITLE \
                 WP_ADMIN_LOGIN \
                 WP_ADMIN_EMAIL \
                 WP_ADMIN_PASS \
                 WP_USER_LOGIN \
                 WP_USER_EMAIL \
                 WP_USER_PASS

all: check_vars setup_dirs setup_hosts up

# Check if .env file exists in srcs/
check_env:
	@echo "Checking if $(ENV_FILE) exists..."
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "❌ Error: $(ENV_FILE) file not found. Please create it before running make."; \
		exit 1; \
	else \
		echo "✅ $(ENV_FILE) file found."; \
	fi

check_vars: check_env
	@echo "Checking required environment variables..."
	@set -a; . $(ENV_FILE); set +a; \
	for var in $(REQUIRED_VARS); do \
		val=$${!var}; \
		if [ -z "$$val" ]; then \
			echo "❌ Error: Environment variable '$$var' is not set or empty in $(ENV_FILE)"; \
			exit 1; \
		else \
			echo "✅ $$var"; \
		fi; \
	done

# Create ~/data/wordpress and ~/data/mariadb if they don't exist
setup_dirs:
	@echo "Checking ~/data/wordpress and ~/data/mariadb directories..."
	@if [ ! -d "$$HOME/data/wordpress" ]; then \
		echo "Creating $$HOME/data/wordpress directory"; \
		mkdir -p "$$HOME/data/wordpress"; \
	fi
	@if [ ! -d "$$HOME/data/mariadb" ]; then \
		echo "Creating $$HOME/data/mariadb directory"; \
		mkdir -p "$$HOME/data/mariadb"; \
	fi

# Add 127.0.0.1 DOMAIN_NAME to /etc/hosts if missing
setup_hosts:
	@DOMAIN_NAME=$$(grep '^DOMAIN_NAME=' $(ENV_FILE) | cut -d= -f2); \
	echo "Checking /etc/hosts entry for $$DOMAIN_NAME..."; \
	if ! grep -q "127.0.0.1 $$DOMAIN_NAME" /etc/hosts; then \
		echo "Adding '127.0.0.1 $$DOMAIN_NAME' to /etc/hosts (sudo required)"; \
		echo "127.0.0.1 $$DOMAIN_NAME" | sudo tee -a /etc/hosts > /dev/null; \
	else \
		echo "✅ /etc/hosts already contains the entry"; \
	fi

# Run docker compose up using the config in srcs/
up:
	@echo "🐳 Starting docker compose using $(COMPOSE_PATH)..."
	@docker compose --env-file $(ENV_FILE) -f $(COMPOSE_PATH) up -d

# Stop containers and without removing images or deleting volumes
down:
	@echo "🛑 Stopping containers without removing images (data preserved)..."
	@docker compose -f srcs/docker-compose.yml down

# Stop containers and remove images without deleting volumes
clean:
	@echo "🛑 Stopping containers and removing images (data preserved)..."
	@docker compose -f srcs/docker-compose.yml down --rmi all

# Full reset: stop, remove containers & volumes, delete local data
reset:
	@echo "⚠️  WARNING: This will stop containers, remove volumes, and delete local data in ~/data"
	@read -p "Are you sure you want to continue? [y/N] " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "❌ Reset aborted."; \
		exit 1; \
	fi
	@echo "Proceeding with full reset..."
	@docker compose -f srcs/docker-compose.yml down -v --rmi all
	@echo "Deleting local data directories..."
	sudo rm -rf $$HOME/data/wordpress $$HOME/data/mariadb

re: clean all
```

### NOMMER CORRECTEMENT LES IMAGES

Le sujet impose que chaque image construite ait un nom explicite, correspondant au service (par exemple `mariadb` pour le service MariaDB).
Or, si on ne précise rien dans le fichier `docker-compose.yml`, Docker nomme les images automatiquement avec des préfixes et suffixes (par exemple `srcs-mariadb`), ce qui ne respecte pas cette contrainte.

Nous allons donc modifier notre `docker-compose.yml` pour spécifier un nom d’image explicite.

#### Utilisation de la clé `image`

Jusqu’à présent, dans notre `docker-compose.yml`, nous écrivions simplement :

```yaml
services:
  mariadb:
    build: requirements/mariadb
```

Cela fonctionne, mais ne permet pas de contrôler le nom de l’image construite.
Pour y remédier, nous allons :

1. Remplacer la valeur directe de `build` par un bloc `build:` avec la clé `context`, pointant sur le répertoire de build.
2. Ajouter la clé `image:` (en dehors du bloc `build`) pour définir explicitement le nom de l’image.

Exemple :

```yaml
services:
  mariadb:
    build:
      context: requirements/mariadb
    image: mariadb
```

#### Problème avec les noms d’image "officiels"

Si nous utilisons un nom d’image générique comme `mariadb`, `nginx`, ou `wordpress`, Docker va **chercher une image existante sur Docker Hub**, ce qui est interdit par le sujet.

Même si nous avons bien un `Dockerfile` dans `requirements/mariadb`, Docker ignorera la construction et tentera de récupérer l’image officielle.

#### Solution : ajouter un *tag*

Pour éviter cela, il suffit **d’ajouter un tag** au nom de l’image.
Un tag est un suffixe après un deux-points `:` qui identifie une version personnalisée.
Cela empêche Docker de confondre votre image avec une image officielle.

Par exemple :

```yaml
services:
  mariadb:
    build:
      context: requirements/mariadb
    image: mariadb:inception42
```

Dès lors, Docker ne trouvera pas d’image `mariadb:inception42` sur Docker Hub, et construira bien la notre à partir du `Dockerfile`.

### DOCKERIGNORE

Lorsque Docker construit une image à partir d’un contexte (`build.context`), **il copie l’ensemble des fichiers du répertoire source** pour les envoyer au démon Docker.
Cela peut inclure des fichiers inutiles (comme `.env`, des logs, des fichiers temporaires, le dossier `.git`, ou même des secrets), ce qui peut :

* ralentir considérablement le build
* **poser des risques de sécurité** si des données sensibles sont accidentellement copiées dans l’image

Pour éviter cela, il est indispensable de créer un fichier `.dockerignore` dans **chaque dossier contenant un `Dockerfile`** (typiquement : `requirements/nginx/`, `requirements/mariadb/`, `requirements/wordpress/`).

Ce fichier fonctionne exactement comme un `.gitignore` : chaque ligne indique un chemin ou un motif à ignorer.

Pour ma part, jai créé le même `.dockerignore` pour chacune des images :

```
.git         # Ne pas envoyer l’historique Git
.gitignore   # Fichier inutile pour le build
.vscode      # Dossier de configuration de l’éditeur (Visual Studio Code)
*.swp        # Fichiers temporaires de Vim
*.log        # Fichiers de logs
*.tmp        # Fichiers temporaires divers
*.bak        # Sauvegardes automatiques
.env         # Fichier contenant les variables d’environnement sensibles
secrets/     # Répertoire contenant les mots de passe ou informations critiques
```

> Important : même si nous copions manuellement certains fichiers via `COPY` dans notre `Dockerfile`, ils **doivent quand même être accessibles dans le contexte**.
> Un fichier ignoré dans `.dockerignore` **ne pourra pas être copié**, sauf s’il est explicitement **hors du dossier ignoré**.
