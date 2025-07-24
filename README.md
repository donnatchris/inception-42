# PROJECT INCEPTION FOR 42
Par chdonnat (Christophe Donnat from 42 Perpignan, France)

[🇫🇷 Version française](README.fr.md)

## AIM OF THE PROJECT:

The goal of the Inception project is to set up a secure and functional Docker-based infrastructure by containerizing several services (like Nginx, WordPress, and MariaDB) and orchestrating them with docker-compose.
It helps you learn about containerization, networking, volumes, and service dependencies in a real-world deployment environment.

### BONUS PART

I have completed two bonus features for this project:

* **Adminer**: a graphical interface for managing databases.
* **Static Site**: I converted the Obsidian vault I created while learning C++ into a complete static website using Quartz.

## SOME COMMANDS YOU CAN USE:

### Commands from the Makefile

* Launch the entire project:

  ```bash
  make
  ```

* Stop and remove the containers (without deleting the data):

  ```bash
  make clear
  ```

* Reset everything (containers and data):

  ```bash
  make reset
  ```

### After running `make`, you can access the following in your web browser:

* Visit the WordPress site:
  [https://localhost](https://localhost)

* Access the WordPress admin panel:
  [https://localhost/wp-admin](https://localhost/wp-admin)

* View the static site (you can learn C++ from it!):
  [https://localhost/static/](https://localhost/static/)

* Open Adminer (graphical database manager):
  [https://localhost/adminer/](https://localhost/adminer/)

## ARCHITECTURE

For this project, I followed the architecture provided in the subject.
The only difference is that I do not use a `secrets/` directory — all passwords and credentials are stored in the `.env` file instead.

---

# COMPLETE TUTORIAL

## SOME DEFINITIONS

### 🐳 **Docker**

**Docker** is a tool that allows you to run applications in isolated and reproducible environments called *containers*.
Instead of manually installing each dependency on the host system, Docker bundles all the necessary elements (code, libraries, configuration) into a self-contained and portable unit.

> *Docker can be compared to a fully equipped kitchen in a box: wherever it is deployed, it allows you to prepare the exact same dish with the same tools.*
> Thus, an application runs reliably, regardless of the environment.

### 📦 **Docker Image**

A **Docker image** is a kind of **ready-to-use recipe**: it contains all the files needed to create a container, including the file system, libraries, application code, and initialization commands.
Images are **immutable**, which makes them reliable, reproducible, and easily shareable.

### 🧱 **Docker Container**

A **container** is an **active instance of an image**. It is an isolated process that runs the application defined by the image.

> *If the image represents the recipe, the container is the dish actually prepared.*
> Each container can be started, stopped, deleted, or recreated at will, without impacting the system or other containers.

### 🧩 **Docker Compose**

**Docker Compose** is a tool for **defining and running multiple Docker containers with a single command**, using a `docker-compose.yml` file.
This file describes the necessary services (e.g., a web server, a database), their configuration, their network connections, and shared volumes.
Once configured, the entire stack can be launched with:

```bash
docker compose up
```

> *It's like giving a chef a complete menu to prepare, where each dish has its own utensils, ingredients, and timing.*

---

## NGINX DOCKER

Nginx is a high-performance, lightweight web server designed to efficiently handle a large number of concurrent connections.
In the Inception project, it is used to receive HTTPS requests from clients and forward them, depending on the case:
- either directly (for static files like HTML or CSS),
- or to a background service like PHP-FPM (to run WordPress).
It is the entry point of the website, the component that interfaces between the outside world and the project's internal services.

To create the Nginx docker, you first need to create a configuration file for Nginx, then a Dockerfile that will create the docker from a Debian or Alpine image.

### NGINX CONFIGURATION FILE `nginx.conf`

An Nginx configuration file consists of blocks followed by curly braces `{}` containing instructions. Each instruction consists of its name, a space, then its argument(s) separated by spaces if there are several, ending with a semicolon `;`. Some blocks will be contained within a "parent" block.

Minimal example of `nginx.conf`:

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

#### `events {}` Block

It configures how Nginx handles network connections (e.g., how many concurrent connections can be processed). For a simple configuration or use in Docker, this block can be left empty: `events {}`

#### `http {}` Block

It defines all directives related to the HTTP protocol: the web servers Nginx will manage, logs, content types, etc.

It can contain the following directives:

* `access_log` Determines where access logs are redirected. We give it the argument `/proc/self/fd/1`, which is a special path in Linux allowing a process (like Nginx) to write directly to its standard output (stdout). Docker automatically captures stdout and stderr from each container, allowing access to Nginx logs with a simple command: `docker logs <container_name>`

* `error_log` Same for error logs, which are redirected to the error output with the argument `/proc/self/fd/2`

* `include` Used to include the content of another file in the main Nginx configuration file. We pass it the argument `/etc/nginx/mime.types` to load **MIME** types (associations between file extensions and their content type, like .html → text/html or .png → image/png), which is essential for serving static files.

* `default_type` Defines the default MIME type if none is found. We give it the argument `application/octet-stream`, which means it is a generic binary file (which will most often trigger a download by the client).

The `http` block also contains the `server` block(s) (only one for the needs of Inception).

#### `server {}` Block

This block defines a virtual server, i.e., a web server instance that Nginx will manage. It must be placed inside an `http` block.

It can contain the following directives:

* `listen` Defines the port on which the server will listen for requests. For a classic HTTP server, we use `listen 80;`. For an HTTPS server (as in Inception), we use `listen 443 ssl;`. If the Nginx configuration only contains `listen 443 ssl;`, then the server only responds to HTTPS requests. Any attempt to connect via HTTP (port 80) will fail. For a smooth experience, you can add a second server block that listens on port 80 and redirects to HTTPS:

```nginx
server {
    listen 80;
    server_name localhost <your_login>.42.fr;
    return 301 https://$host$request_uri;
}
```

* `server_name` Specifies the domain names or IP addresses that this server will accept. Example: `server_name localhost;` or `server_name ${DOMAIN_NAME} localhost;` if using an environment variable in Docker (the domain name for Inception will be "<your_login>.42.fr").

* `root` Indicates the path to the site's root folder, i.e., where the files to be served are located. Example: `root /var/www/wordpress;`. This path corresponds to the volume mounted in the Nginx container to access WordPress files. In the Inception project, WordPress runs in its own container (wordpress), but the Nginx container also needs to access WordPress's static files to serve them (HTML, CSS, images, PHP files to be passed to PHP-FPM, etc.). *→ See the paragraph on volumes below*.

* `index` Specifies the default file(s) to search for when a user accesses a directory. Example: `index index.php index.html index.htm;`.

* `ssl_certificate` and `ssl_certificate_key` Mandatory if SSL is enabled with `listen 443 ssl;`. These directives specify the path to the SSL certificate and its private key. Example:

  ```
  ssl_certificate     /etc/ssl/certs/nginx.crt;
  ssl_certificate_key /etc/ssl/private/nginx.key;
  ```

* `ssl_protocols` Allows choosing the authorized TLS versions. Example: `ssl_protocols TLSv1.2 TLSv1.3;` (recommended for security).

> **Note: SSL, TLS, and HTTPS**
>
> The term **SSL** (*Secure Sockets Layer*) is commonly used, but it is technically outdated: today, we actually use **TLS** (*Transport Layer Security*), a more modern and secure version of the protocol.
>
> Despite this, the word **“SSL” remains widely used** in documentation, tools (like `ssl_certificate`), and configurations, even when talking about TLS.
>
> When a web server uses SSL/TLS, it encrypts communications with the client. This ensures:
>
> * the **confidentiality** of exchanges (no one can read the data),
> * the **authenticity** of the server (via the certificate),
> * the **integrity** of the exchanged data.
>
> This is what differentiates:
>
> * **HTTP**: communication in clear text, not secure
> * **HTTPS**: **encrypted** and **secure** communication via SSL/TLS
>
> To enable HTTPS on an Nginx server, you need:
>
> * a **certificate** (`.crt`)
> * a **private key** (`.key`)
> * and the `listen 443 ssl;` directive in the `server {}` block
>
> In the Inception project, we use self-signed certificates, created automatically when building the Nginx container.
> This will be done in the Dockerfile, using the `openssl` command.
> These certificates are not validated by a certification authority: they are only intended for local or educational use.
> The browser will display a security alert, which is normal.

The `server` block can also contain `location` blocks that define the behavior for certain URLs (like `/`, or all URLs ending in `.php`, etc.).

#### `location {}` Blocks

A `location` block allows you to define a **specific behavior for one or more URLs**. It is written inside a `server` block and starts with a pattern (path or regular expression) followed by curly braces containing directives.

There can be several `location` blocks, each corresponding to a specific case.

Here are the most used in Inception:

* `location / {}`
  This block applies to the **root of the site** (all requests that do not match anything more specific).
  Example:

  ```nginx
  location / {
      try_files $uri $uri/ =404;
  }
  ```

This means: "first try to serve the file as is (`$uri`), then as a directory (`$uri/`), and if nothing is found, return a 404 error". This directive is essential to prevent Nginx from trying to interpret non-existent paths.

* `location ~ \.php$ {}`

This block redirects all requests for PHP files to PHP-FPM (FastCGI), which runs in a separate container (here: `wordpress`). It allows Nginx to **delegate the execution of PHP scripts** to the correct service.

#### The `location ~ \.php$ {}` block in detail


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

Explanation of the directives:

* `fastcgi_split_path_info` Splits the path of the PHP file and the rest of the URL.
  Example: `/index.php/xyz` → file: `index.php`, path_info: `/xyz`

* `fastcgi_pass` Indicates where to send the request: here to the `wordpress` container on port `9000`, where PHP-FPM is running.

* `fastcgi_index` Defines the default file to execute if no file is specified in the URL (e.g., `/admin/` → `index.php`).

* `include fastcgi_params` Includes a standard file containing the environment variables necessary for FastCGI (e.g., `REQUEST_METHOD`, `SCRIPT_NAME`, etc.).

* `fastcgi_param SCRIPT_FILENAME` Specifies the full path of the PHP file to be executed, by combining the `document_root` and the name of the requested PHP file.

* `fastcgi_param PATH_INFO` Transmits to PHP the part of the URL located **after** the `.php` file, useful for some frameworks.

> The `fastcgi_pass`, `include fastcgi_params`, and `fastcgi_param SCRIPT_FILENAME` directives are **essential** for running PHP with Nginx. The others are **strongly recommended** for maximum compatibility.


### DOCKERFILE

A `Dockerfile` is a text file that contains **all the instructions needed to build a Docker image**.
Each instruction is read line by line and executed in order, to create an image that will serve as the basis for a container.

A `Dockerfile` can contain different directives, the most common being:

* `FROM`
  Specifies the **base image** on which to build. This image will be downloaded from Docker Hub.
  
* `LABEL`
  Adds **descriptive information** (metadata) to the image, such as the author or a description.

* `RUN`
  Executes a command **at the time of image construction** (e.g., installing packages). You can chain several commands in the same `RUN` line by separating them with `&&`, which allows creating a lighter image than one created from a Dockerfile containing multiple `RUN` lines.

* `COPY`
  Copies a file or folder **from the local build context** to the image's file system (from the host machine or VM to the container).
  Example:

* `EXPOSE`
  Indicates **the port on which the container will listen** once launched. This is **informative** (it does not publish the port automatically).

* `CMD`
  Defines the **default command** to be executed when the container starts.

* `ENTRYPOINT`
  Very similar to `CMD` but defines a program to be executed instead of a command.

For better readability, you can break long lines with line breaks preceded by the `\` character.

Example:

```dockerfile
FROM nginx:alpine
LABEL maintainer="your_login@student.42.fr"
COPY ./html /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### BASIC COMMANDS FOR USING A DOCKERFILE

Here are the most common commands:

* `docker build`
  Used to create a Docker image from a Dockerfile.

  ```bash
  docker build -t image_name .
  ```

  * `-t` is used to give a name to the image (example: `nginx42`)
  * `.` indicates the build context: the folder containing the `Dockerfile` (so you must be in the Dockerfile's directory to run this command)

* `docker images`
  Displays the list of locally available Docker images.

  ```bash
  docker images
  ```
  
* `docker run`
  Used to launch a container from an image.

  ```bash
  docker run -d -p 8080:80 --name my_container image_name
  ```

  * `-d` runs the container in the background ("detached" mode)
  * `-p` publishes the container's port to the host machine's port (`host:container`)
  * `--name` gives a custom name to the container

* `docker ps`
  Displays running containers.

  ```bash
  docker ps
  ```
  
* `docker logs`
  Displays the logs of a container (useful if `access_log` is redirected to `stdout` in Nginx).

  ```bash
  docker logs my_container
  ```

* `docker stop`
  Stops a running container.

  ```bash
  docker stop my_container
  ```

* `docker rm`
  Removes a stopped container.

  ```bash
  docker rm my_container
  ```

* `docker rmi`
  Removes a Docker image.

  ```bash
  docker rmi image_name
  ```

* `docker system prune -a -f`
  Removes everything unused by Docker:
  * stopped containers
  * unused volumes (optional, see below)
  * unused networks
  * images not used by an active container


  ```bash
  docker system prune -a -f
  ```

  * `-a` (or `--all`) removes all unused images, even those that are not "dangling" (untagged). Without `-a`, only "dangling" images are removed.
  * `-f` forces deletion without asking for confirmation.


Perfect, here is an **explanation written for your README**, in your style, which explains **step by step the logic** that led to the writing of this `Dockerfile`. We keep the pedagogical and progressive tone, with references to concepts seen previously.


### BUILDING THE NGINX DOCKERFILE

Now that we have seen the main directives of a `Dockerfile`, we can understand step by step the construction of the Nginx image for the Inception project.

Here is the file used:

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

We start from a minimal Debian image (`11.11`). We could also have used `bookworm`, but here we use a specific version to avoid future differences.

#### *`RUN ...`*

This instruction chains several commands in a single line, separated by `&&`, for readability and optimization reasons (to avoid unnecessary layers in the image).

Here is what each part does:

* `apt-get update`
  Updates the list of available packages.

* `apt-get install -y nginx curl openssl procps`
  Installs:

  * `nginx`: the web server
  * `curl`: HTTP testing tool (optional but useful)
  * `openssl`: to generate a self-signed SSL certificate
  * `procps`: for tools like `ps` (optional but useful for debugging)

* `apt-get clean && rm -rf /var/lib/apt/lists/*`
  Cleans up unnecessary files after installation to reduce the image size.

* `mkdir -p /etc/ssl/certs` and `/etc/ssl/private`
  Creates the folders that will contain the SSL certificate and the private key.

* `openssl req -x509 ...`
  Generates a **self-signed SSL certificate**, valid for one year (`365 days`).
  This certificate will be used by Nginx to enable **HTTPS**.

> Generating a self-signed SSL certificate with `openssl`
>
> In the Inception project, we need an SSL certificate to enable HTTPS in Nginx.
> Rather than using a certificate signed by an authority (like Let's Encrypt), we generate a **self-signed certificate** during the container build.
>
> The following command is used in the `Dockerfile`:
>
> ```dockerfile
> openssl req -x509 -nodes -days 365 \
>   -out /etc/ssl/certs/nginx.crt \
>   -keyout /etc/ssl/private/nginx.key \
>   -subj "/C=FR/ST=Occitanie/L=Perpignan/O=42/OU=42/CN=chdonnat.42.fr"
> ```
>
> This command allows to:
>
> * Generate a **self-signed certificate** (`-x509`) without going through an external authority
> * **Not encrypt** the private key (`-nodes`) — essential in Docker, to avoid any password entry
> * Define a **validity period** of 365 days (`-days 365`)
> * Specify the output paths for the certificate and the key (`-out`, `-keyout`)
> * Provide all **identity information** directly online with the `-subj` option
>
> This certificate and its key are then used in the Nginx configuration to enable HTTPS:
>
> ```nginx
> ssl_certificate     /etc/ssl/certs/nginx.crt;
> ssl_certificate_key /etc/ssl/private/nginx.key;
> ```

* `mkdir -p /var/run/nginx`
  Creates the necessary folder for Nginx to write its PID. Nginx needs a place to store its PID (Process ID) file when it starts. By default, this file is: `/var/run/nginx.pid`. But the file can only be created if the directory exists, and this folder does not necessarily exist by default (as in a minimal Debian container). If the folder does not exist and Nginx tries to write to it, the server will fail to start.

* `mkdir -p /var/www/wordpress` and `/var/www/html`
  Creates the directories where the WordPress site files and possibly a static welcome page will be stored (for testing, for example).
  These folders also correspond to the **shared volumes** between Nginx and other containers (like WordPress).

#### *`COPY`*

* `COPY conf/nginx.conf /etc/nginx/nginx.conf`
  Copies the custom Nginx configuration file into the image, at the location expected by Nginx.

* `COPY conf/index.html /var/www/html/index.html`
  Copies a default static home page (useful for testing that the server works even without WordPress).


#### *`EXPOSE 443`*

Indicates that the server is listening on the **HTTPS port** (443). This does not publish the port by itself, but **documents** that this container is designed to receive SSL connections.

#### *`CMD ["nginx", "-g", "daemon off;"]`*

Starts Nginx in **non-daemonized** mode, which is essential in a Docker container (otherwise the main process exits immediately and the container stops).

> Why use `daemon off;` with Nginx in Docker?
> 
> When you run a Docker container, it waits for a main process to run as "PID 1".
> This process becomes the "master process" of the container.
> If this process terminates, the container stops immediately.
>
> The PID 1 in a container plays a special role:
> * It is the parent of all other processes.
> * It must remain active as long as the container is running.
> * It must capture signals (like SIGTERM) to allow a clean shutdown.
>
> If the PID 1 process terminates (or goes into the background), Docker considers the container finished, and stops it.
>
> The `-g` option allows passing a global configuration directive directly on the command line, without modifying the `nginx.conf` file.
>
> `daemon off;` disables daemon mode (background) so that Nginx remains in the foreground as the main process (PID 1) of the container.


---


## MARIADB DOCKER

MariaDB is a relational database management system (RDBMS), compatible with MySQL.
It is used by WordPress to store all the dynamic data of the site: users, posts, settings, comments, etc.


In the Inception project, MariaDB functions as a standalone service (in its own container) to which WordPress connects via a hostname (mariadb) and a set of credentials (database, username, password).


To create the MariaDB docker, you must first create a configuration file for MariaDB, then a Dockerfile that will create the docker from a Debian or Alpine image, and finally an initialization script.

### MARIADB CONFIGURATION FILE

The MariaDB configuration file allows you to define the database server parameters at startup: ports, log file names, connection limits, database locations, encoding, etc.


In the context of Inception, this file is generally little modified. We usually just create an SQL initialization file (executed on first launch) to create the database, the user, and define their rights.

#### How to name it and where to place it

MariaDB reads its configuration from several files, in a well-defined order. The main file is usually located at `/etc/mysql/my.cnf`.
But it also automatically includes **all files ending in `.cnf`** present in the `/etc/mysql/conf.d/` folder.

This is why, in the Inception project, we can name the configuration file: `50-server.cnf`.
This name follows an **alphabetical order convention** to ensure that the file is read **after the default files**, without having to modify the main `my.cnf` file.

You will need to ensure that the Dockerfile copies the configuration file into the MariaDB container in the `/etc/mysql/conf.d/50-server.cnf` folder.

> The name `50-server.cnf` is recommended because it is explicit, respects conventions, and allows you to modify only what is necessary without touching the system files.

#### Content of a `50-server.cnf` configuration file

A MariaDB configuration file is structured in two parts:

* **Blocks (or sections)**
  Each block is indicated in square brackets, like `[mysqld]` or `[client]`.
  Each block applies to a specific part of the MariaDB ecosystem:

  * `[mysqld]`: options for the MariaDB server itself
  * `[mysql]`: options for the `mysql` client (the command-line interface)
  * `[client]`: options for all clients (including `mysqldump`, `mysqladmin`, etc.)

* **Directives**
  Inside each block, we write lines in the form `key = value` to define the parameters to be applied.

#### Example of structure used in Inception:

```ini
[mysqld]
datadir = /var/lib/mysql
socket  = /run/mysqld/mysqld.sock
bind_address = 0.0.0.0
port = 3306
user = mysql
```

> The `[mysqld]` block is the only mandatory one in the context of the Inception project, as it is the one that configures the **behavior of the MariaDB server** at startup.
> The `[client]` and `[mysql]` blocks are optional, but useful if you want to interact with the database from the command line inside the container.

#### Explanation of the directives

* `datadir = /var/lib/mysql`
  Specifies the directory where the **database data** is stored.
  This is also where the Docker volume will be mounted to persist the data.
  *-> See the paragraph on volumes below.*

* `socket = /run/mysqld/mysqld.sock`
  Defines the path of the **UNIX socket file** used for local connections (useful for tools like `mysql` on the command line in the container).

* `bind_address = 0.0.0.0`
  Allows MariaDB to listen on **all network interfaces** of the container.
  ➤ This allows **WordPress (in another container)** to connect to it.

* `port = 3306`
  Defines the port used by MariaDB (3306 is the standard port).

* `user = mysql`
  Indicates the Linux system user under which MariaDB runs.
  By default in Docker, the `mysql` user is already configured.

### MARIADB DOCKERFILE

For the MariaDB Dockerfile, we can keep things simple. We must use a `debian` or `alpine` image as required by the subject, install `mariadb-server`, copy the previously created configuration file into the docker, expose port 3306 as required in the subject.

However, when MariaDB starts for the first time, it initializes an empty data directory (`/var/lib/mysql`) and configures the system database.
At this point, if no password or configuration is set, no custom database or user exists yet, and root access may be passwordless – which is dangerous in production.
This is why, in an automated deployment (as in a Docker container), it is essential to provide the following variables from the start to:

* Create a custom database
  `DB_NAME`: allows you to tell MariaDB which database to create automatically (e.g. wordpress)
  Without this variable, it would have to be done manually after launch

* Create a user with a password
  `DB_USER` and `DB_USER_PASS`: allow you to create a dedicated user
  to connect to the database without using the `root` account
  **Good security practice:** each application (e.g. WordPress) must have its own user

* Protect the root account
  `DB_ROOT_PASS`: sets a secure password for the MariaDB root user
  Without this, root might not have a password, which poses a critical risk

We will therefore have to create a script (`entrypoint.sh` which we will save in the `tools` directory) to be executed when the MariaDB container is launched in order to configure all this (exactly as if we were typing commands in the container after its launch).

The Dockerfile will therefore also have to copy this script into the container, give execution rights to this script, then execute the script.

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

>  Why ENTRYPOINT and not CMD?
> Because ENTRYPOINT allows replacing the main process of the container (PID 1) with a script or program, which is ideal for running our initialization script.

### DOCKER AND ENVIRONMENT VARIABLES

#### Passing environment variables to a Docker container

**Environment variables** allow you to pass dynamic information to a container, such as credentials, a password, or a database name.
There are several ways to define them, depending on the tool used.

#### On the command line with `docker run -e`

When using `docker run` directly (without `docker-compose`), it is possible to pass the variables one by one with the `-e` option:

```bash
docker run -e DB_NAME=wordpress \
           -e DB_USER=wp_user \
           -e DB_USER_PASS=wp_pass \
           -e DB_ROOT_PASS=rootpass \
           image_name
```

#### With a `.env` file and `docker run --env-file`

The variables can also be stored in a `.env` file and injected into the container via the `--env-file` option:

```bash
docker run --env-file .env image_name
```

#### With the `ENV` instruction in the `Dockerfile`

It is also possible to define variables directly in the `Dockerfile`:

```dockerfile
ENV DB_NAME=wordpress
ENV DB_USER=wp_user
ENV DB_USER_PASS=wp_pass
ENV DB_ROOT_PASS=rootpass
```

However, this method makes the values **static and fixed in the image**. The image must be rebuilt if you want to modify a value.

#### With `docker-compose.yml` (recommended in Inception)

> A docker-compose.yml file is a configuration file in YAML format that allows you to define, configure and launch several Docker containers in a single command (docker-compose up).

A simple and readable way is to declare the variables directly in the `environment` section of the `docker-compose.yml` file (*-> see below for the creation of a `docker-compose.yml` file*):

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

These variables will be injected into the container **at the time of its execution** and can be used in scripts like `entrypoint.sh`.

#### With a `.env` file and `docker-compose.yml`

It is also possible to store the variables in a `.env` file located at the root of the project:

```env
DB_NAME=wordpress
DB_USER=wp_user
DB_USER_PASS=wp_pass
DB_ROOT_PASS=rootpass
```

By default, `docker-compose` automatically reads this `.env` file **if it is in the same folder as the `docker-compose.yml`**.
It is then possible to reference these variables in `docker-compose.yml`:

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

#### Recommendation (Inception project)

> In the context of the **Inception** project, it is **recommended to use the `docker-compose.yml` file with variables defined directly in a `.env` file**.


### SCRIPT TO CONFIGURE MARIADB

Here is the script used (placed in the `tools` directory of the `mariadb` directory).
This script is executed automatically when the MariaDB container starts.
It initializes the database, creates the user, the `wordpress` database, and applies the correct permissions from the provided **environment variables**.

#### Script content

```bash
#!/bin/bash

set -e

: "${MDB_NAME:?MDB_NAME environment variable missing}"
: "${MDB_USER:?MDB_USER environment variable missing}"
: "${MDB_USER_PASS:?MDB_USER_PASS environment variable missing}"
: "${MDB_ROOT_PASS:?MDB_ROOT_PASS environment variable missing}"

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

#### Script explanation

* `#!/bin/bash`: indicates that the script should be interpreted by Bash.
* `set -e`: the script stops immediately if a command fails. This avoids executing the rest of the script with a badly configured database.

```bash
: "${MDB_NAME:?MDB_NAME environment variable missing}"
: "${MDB_USER:?MDB_USER environment variable missing}"
: "${MDB_USER_PASS:?MDB_USER_PASS environment variable missing}"
: "${MDB_ROOT_PASS:?MDB_ROOT_PASS environment variable missing}"
```

* Checks that the **four environment variables** are well defined (not mandatory but good practice).
* If one of them is missing, the container **fails immediately** on startup with a clear message.

```bash
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
```

* Creates the `/run/mysqld` folder if necessary (used for the Unix socket file, a special file that allows a client to connect).
* Changes the owner to the `mysql` user, as required by MariaDB.

```bash
if [ ! -d /var/lib/mysql/mysql ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi
```

* Tests if the system database (`mysql`) exists.
* If this is **not the case** (first start), it is initialized with `mariadb-install-db`.

```bash
mysqld_safe --skip-networking &
```

* Starts MariaDB **in the background**, without opening the network port.
* The `&` symbol in bash (and in shell in general) launches the command in the background.
* The `--skip-networking` mode ensures that no external connection is possible during initialization (this prevents a malicious or misconfigured client from sending a request before the database is ready).

>  `mysqld_safe` vs `mysqld`: what are the differences?
> 
> `mysqld` is the real binary of the MariaDB server (daemon)
> It manages: Client connections, SQL queries, data files.
>
> `mysqld_safe` is a safe wrapper around mysqld
> It is a Bash script (often in /usr/bin/mysqld_safe).
> It is used to:
> prepare the socket directory (/run/mysqld)apply the correct user rights,
> read the config files (/etc/my.cnf, /etc/mysql/my.cnf),
> launch mysqld with the correct arguments,
> automatically restart mysqld if it crashes,
> redirect logs correctly to stderr/stdout.

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

* Waits for MariaDB to be **operational** (ping OK).
* `mysqladmin` is a command-line tool provided with MariaDB/MySQL that is used to administer a database server (start it, stop it, check its status, etc.).
* `mysqladmin ping` has nothing to do with network ping: The ping here tries to connect to the MariaDB server via the socket, sends a light request, waits for a response (which we send to `&>/dev/null` so as not to display it), returns an exit code (0 if OK, 1 if failure).
* 30-second timeout.
* Displays an error and exits if the server does not respond.

```bash
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS \`${MDB_USER}\`@'%' IDENTIFIED BY '${MDB_USER_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO \`${MDB_USER}\`@'%';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
```

* Creates the database if it does not exist.
* Creates a user with a password and full access to this database.
* Sets the root password (if absent at the start).
* Applies the privileges with `FLUSH PRIVILEGES`.

* `mariadb` is the **command-line client** of MariaDB
* `-u` specifies the user
* `-p` specifies the password (note: no space between -p and the password)
* `-e` means: execute this SQL command and exit the interactive MariaDB shell (non-interactive mode).
* by convention, MariaDB commands are in uppercase (but it works without)


```bash
mysqladmin -u root -p"${MDB_ROOT_PASS}" shutdown
```

* This command cleanly stops the MariaDB server temporarily launched in the background during the initial configuration phase.

```bash
echo "✅ MariaDB starts..."
exec mysqld_safe
```

* Launches `mysqld_safe` **in foreground mode** with `exec`: exec replaces the current process (here: the shell script) with the mysqld_safe process, without creating a new child process (which replaces it as **PID 1**).
* It takes the place of the script.
* Allows the container to remain active as long as MariaDB is running.

### TESTING THE MARIADB CONTAINER

At this stage, it is possible to test the MariaDB container.
To do this, you must go to the directory containing the `Dockerfile` and type the following commands:

#### build the image:

```bash
docker build -t mariadb .
```

- `-t` is used to give a name to the image

#### launch the docker:

```bash
docker run -d \
  --name mariadb_test \
  -e MDB_NAME=wordpress \
  -e MDB_USER=wp_user \
  -e MDB_USER_PASS=wp_pass \
  -e MDB_ROOT_PASS=rootpass \
  mariadb
```

- `-d` launches in the background (detached)
- `--name` gives a name to the container
- `-e VARIABLE=value` allows passing an environment variable when launching the docker
- `mariadb` is the name of the image used (the one created previously)

#### view the logs:

```bash
docker logs -f mariadb_test
```

- `-f` allows displaying new lines live if there are any

#### enter the container:

```bash
docker exec -it mariadb_test bash
```

- `-it` interactive mode with pseudo-terminal
- `mariadb_test` container name
- `bash` launches a bash shell inside

#### once in the container's shell, connect:

```bash
mariadb -u root -p"$MDB_ROOT_PASS"
```

- `-u` specifies the user
- `-p` allows entering the password

#### once connected to the MariaDB shell, check that the `wordpress` database exists:

```mariadb
SHOW DATABASES
```

This command displays the table with the present databases. It should display the name of the created database as well as the default databases:

```text
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| wordpress          |  ← if `MDB_NAME=wordpress`
+--------------------+
```

### DOCKER-COMPOSE

Now that we have two containers, we can create our first `docker-compose.yml` file.

#### What is `docker compose`?

Docker Compose allows you to launch several Docker containers at the same time, by defining their configuration (image, commands, ports, variables, network, shared volumes, etc.) in a single `docker-compose.yml` file.
It simplifies the orchestration of services by automatically connecting them on a common network and managing their startup order.

#### Structure of a `docker-compose.yml` file

A `docker-compose.yml` file defines the configuration of several Docker services in a single application.
It generally consists of the following sections:

* **`services`**: lists the containers to be launched (e.g., `nginx`, `wordpress`, `mariadb`, etc.).
* **`build` / `image`**: indicates the path of the `Dockerfile` or the Docker image to use.
* **`ports`**: exposes the container's ports to the outside.
* **`environment`**: defines the service's environment variables.
* **`volumes`**: allows mounting files or folders between the host and the container.
* **`networks`**: configures networks to allow services to communicate with each other.

Thanks to `docker-compose`, all these services can be started and orchestrated together with a simple command:

```bash
docker compose up
```

And they can be stopped with the command:

```bash
docker compose down
```

#### YAML syntax rules for Docker Compose

##### 1. **Key followed by a colon**

Each **key** is followed by a `:` then a space:

```yaml
services:
  mariadb:
    image: mariadb:latest
```

##### 2. **Mandatory indentation (spaces, no tabs)**

* Indentation is done only with **spaces** (no tabs)
* The **current standard** is 2 spaces, but 4 is also accepted.

```yaml
services:
  mariadb:
    image: mariadb
```

##### 3. **Lists start with `-`**

To declare a **list of items**:

```yaml
ports:
  - "80:80"
  - "443:443"
```

Each `-` must be aligned, **with at least one space after**.


##### 4. **Values can be:**

* Strings (usually without quotes, unless special characters)
* Booleans (`true`, `false`)
* Integers
* Nested objects

Examples:

```yaml
restart: always
environment:
  WP_DEBUG: "true"
  SITE_NAME: "My personal site"
```

##### 5. **Strings containing special characters must be in quotes**

Especially if they contain `:`, `#`, or start with `*`, `&`, `@`, etc.

```yaml
command: "npm run dev:watch"
```

#### Environment variables

Previously, we launched the MariaDB container with the following command to pass it the environment variables directly:

```bash
docker run -e DB_NAME=wordpress \
           -e DB_USER=wp_user \
           -e DB_USER_PASS=wp_pass \
           -e DB_ROOT_PASS=rootpass \
           image_name
```

We will simplify things by writing the environment variables in a `.env` file located in the same folder as the `docker-compose.yml` file:

```env
DB_NAME=wordpress
DB_USER=wp_user
DB_USER_PASS=wp_pass
DB_ROOT_PASS=rootpass
```

We can then specify in our `docker-compose.yml` the file to use to automatically retrieve the environment variables.

#### Creating our first `docker-compose.yml`

At the root of the `srcs/` folder of our project, we will create a temporary `docker-compose.yml` file to test the build and execution of our two Nginx and MariaDB containers.

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

#### Explanations

This file allows you to define and launch several Docker containers with a single command (`docker-compose up`).
It defines two services here: **MariaDB** and **Nginx**, as well as the necessary volumes and networks.

##### Services

```yaml
services:
```

*Main section defining the containers to be created.*

* `mariadb`

```yaml
  mariadb:
```

*Name of the service (also used as hostname in the Docker network).*

```yaml
    build: requirements/mariadb
```

*Tells Docker to build the image from the Dockerfile located in `requirements/mariadb`.*

```yaml
    container_name: mariadb
```

*Explicit name given to the container (otherwise Docker generates one automatically).*

```yaml
    env_file: .env
```

*Loads environment variables from the `.env` file (e.g., `MDB_NAME`, `MDB_ROOT_PASS`, etc.).*

```yaml
    expose:
      - "3306"
```

*Indicates that port 3306 (MySQL port) is exposed **to other containers** on the Docker network.
It is **not exposed to the outside** of the host (unlike `ports`).*

```yaml
    networks:
      - inception
```

*Connects the service to the Docker network named `inception` to communicate with other services.*

##### `nginx`

```yaml
  nginx:
```

*Name of the service for the web server.*

```yaml
    build: requirements/nginx
```

*Builds the image from the Dockerfile in `requirements/nginx`.*

```yaml
    container_name: nginx
```

*Explicit name for the container.*

```yaml
    env_file: .env
```

*Loads the environment variables necessary for Nginx (for example the domain).*

```yaml
    ports:
      - "443:443"
```

*Exposes the HTTPS port 443 **from the host to the container** so that the site is accessible via a browser.*
*This means: redirect port 443 of the host machine to port 443 of the container.*
In Docker, a container is isolated from the outside. To make it accessible from the host (and therefore the browser or other external services), you must publish a port.

```yaml
    networks:
      - inception
```

*Connects Nginx to the `inception` Docker network, which allows, for example, to access `mariadb` via the hostname `mariadb`.*

##### Network

Each container launched with Docker Compose is connected by default to an isolated network.
By defining a custom network (here `inception`), all services are connected to it and can communicate with each other by their service name (like mariadb, nginx, wordpress…).

```yaml
networks:
  inception:
    driver: bridge
```

*Creates a custom `bridge` type network so that containers can **recognize each other by their service name**.*

This network is of type `bridge`, the most common for internal networks.
Thanks to this, in the WordPress or Nginx configuration file, we can define mariadb as the database address, instead of looking for an IP.
This greatly simplifies the interconnection between services in a multi-container environment.

#### Testing the `docker-compose.yml`

To launch the execution of the `docker-compose`, place yourself in the directory containing the file, then type the following command:

```bash
docker compose up
```

> This command does several important things:
>
> 1. **Builds the Docker images** (if they are not already present or if the `Dockerfile` has changed), based on the instructions of each service defined in the `docker-compose.yml` file.
>
> 2. **Creates the necessary containers**, using these images.
>
> 3. **Creates the networks and volumes** defined in the `docker-compose.yml` file (if they do not already exist).
>
> 4. **Launches all containers in parallel**, respecting dependencies (`depends_on`) and configurations (ports, environment variables, volumes…).
>
> By default, it displays the **logs of all containers in real time** in the terminal.
> To launch it in the background (detached mode), you can use:
>
> ```bash
> docker compose up -d
> ```
> 
> This allows you to continue using the terminal while leaving the containers running in the background.

Then open a web browser and enter in the address bar:

```text
https://localhost
```

The browser should return a **403 Forbidden** error, which is **normal at this stage**: Nginx is trying to access WordPress, which is not yet installed (as planned in its configuration).

You can also connect to the MariaDB container with the command:

```bash
docker exec -it mariadb bash
```

Then, connect to the MariaDB server with the credentials defined in your `.env` file:

```bash
mariadb -u<username> -p<user_password>
```

Once connected, the following command will display the list of databases (including the `wordpress` database, if everything went well):

```sql
SHOW DATABASES;
```

---

## WORDPRESS DOCKER

WordPress is an open-source Content Management System (CMS), widely used to create and manage websites, blogs, or even online stores.
Written in PHP and using a MySQL/MariaDB database, it allows users without development skills to easily publish content via an intuitive web interface.

In the context of the Inception project, this container allows hosting a functional WordPress site, automatically configured at startup, and connected to the MariaDB container for data management.
The installation is done using the `wp-cli` command line, which allows for quick configuration without manual intervention.

### PHP-FPM CONFIGURATION FILE (`www.conf`)

As with MariaDB or Nginx, we will start by creating a PHP-FPM configuration file `www.conf` for wordpress, which we will place in the `conf` folder.

PHP-FPM means PHP FastCGI Process Manager.
It is an interface between a web server (like NGINX) and the PHP engine.
It allows executing PHP scripts in a performant, flexible, and secure way.

Servers like NGINX do not know how to execute PHP directly.
They therefore transmit PHP requests to an external service — here, PHP-FPM — which is responsible for:
- launching PHP processes
- executing PHP code (like index.php)
- returning the result (HTML) to NGINX for display

#### How PHP-FPM works:
- The NGINX server receives a request for a .php file
- It redirects it via fastcgi_pass to PHP-FPM
- PHP-FPM runs the PHP code with the correct environment variables, files, etc.
- It returns the result to NGINX, which displays it in the browser

> PHP-FPM (FastCGI Process Manager) is a service that allows executing PHP code instead of NGINX.
> It acts as a gateway between the web server and the PHP engine, by launching configurable PHP processes on demand.
> In this project, PHP-FPM is used to process requests sent to the WordPress site in a performant and secure way.

#### The `www.conf` file

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

#### Explanations

The PHP-FPM configuration file (`www.conf`) configures **PHP-FPM**, the FastCGI process manager used to execute PHP scripts in the WordPress container.
Here is an explanation of the directives used:

```ini
[www]
```

Declares a new process *pool* named `www`. Each pool is an independent instance of PHP-FPM.

> Each configuration file begins with a pool name in square brackets, here [www].
> It allows distinguishing several groups of processes if necessary (not useful for Inception, but good to know).
> A pool is an independent group of PHP-FPM processes that manages PHP requests.
> Each pool functions as a "processing unit" with its own configuration and its own processes.
> Each pool can:
> - listen on a different port or socket
> - use a different system user/group
> - have its own load management strategy (number of processes, etc.)
> - load a different php.ini file
> - be isolated for security or performance reasons
> In other words: a pool = a set of PHP workers that run under certain rules.

```ini
user = www-data
group = www-data
```

Specifies the Unix user and group under which the PHP processes will run.
`www-data` is the standard user for web services (NGINX, PHP).

```ini
listen = 0.0.0.0:9000
```

Indicates that PHP-FPM will listen for FastCGI connections on TCP port 9000.
This allows NGINX to communicate with PHP-FPM via the internal Docker network (`fastcgi_pass wordpress:9000;`).

```ini
listen.owner = www-data
listen.group = www-data
```

Defines the access rights to the socket or port.
Here, even if we use a TCP port, this configuration is kept to remain consistent or in the case of a switch to a Unix socket.

```ini
pm = dynamic
```

Enables dynamic process management.
PHP-FPM will automatically adjust the number of child processes based on the server load.

> Since the `pm` parameter is set to `dynamic`, we must define the following parameters:
> `pm.max_children`, `pm.start_servers`, `pm.min_spare_servers`, `pm.max_spare_servers`.
> If we had used `pm = static`, only the `pm.max_children` parameter would have been mandatory.

```ini
pm.max_children = 5
```

Maximum number of child processes allowed.
This limits memory usage in a lightweight container.

```ini
pm.start_servers = 2
```

Number of processes launched at service startup.

```ini
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

Minimum and maximum number of idle processes that PHP-FPM must keep ready to process requests.
Helps avoid startup delays during a load spike.

```ini
clear_env = no
```

Allows PHP-FPM to inherit environment variables.
This is **essential** in the Docker context, as WordPress uses these variables (defined in the `.env`) for its automatic configuration via WP-CLI.

### COMPONENTS NEEDED TO RUN WORDPRESS

Before creating the `Dockerfile`, let's review the components to install to make WordPress work:

The WordPress container is based on a minimal Debian base image.
It is necessary to manually install PHP, the required extensions, as well as complementary system tools for WordPress to function correctly.
Here is the list of packages to install in the `Dockerfile`:

#### PHP and its interpreter

* `php`
  Installs the PHP engine as well as the main binary (`php`).
  This is the basis for executing any WordPress code, which relies entirely on PHP.

  > PHP is a server-side programming language mainly used to create dynamic websites, like WordPress, by generating HTML in response to HTTP requests.

* `php-fpm`
  Installs **PHP-FPM** (FastCGI Process Manager), a process manager allowing a web server like **NGINX** to delegate the execution of PHP scripts to a dedicated service via the FastCGI protocol.
  Mandatory to separate roles between containers (NGINX ↔ WordPress).

#### Mandatory PHP extensions for WordPress

* `php-mysql`
  This extension allows PHP to interact with a MySQL or MariaDB database via the MySQLi (improved) and PDO_MySQL (object-oriented) interfaces. WordPress uses these interfaces to establish a connection with the database, execute SQL queries, retrieve posts, users, site settings, etc.
  Without this extension, no connection to the database would be possible, which would completely prevent WordPress from functioning (the site would display a critical error upon loading).
  It is one of the absolutely essential extensions for any WordPress installation.

* `php-curl`
  Allows WordPress to make **HTTP requests from the server**, which is essential for installing extensions, interacting with APIs, or downloading files.

* `php-gd`
  Image manipulation library. Necessary for **generating thumbnails, resizing images** in the WordPress media library, etc.

* `php-mbstring`
  Manages multibyte strings (UTF-8, Unicode). Essential for **compatibility with international languages** and many plugins.

* `php-xml`
  Allows **reading and writing XML files**, especially for managing RSS feeds, editors, and internal APIs.

* `php-xmlrpc`
  Supports **XML-RPC remote requests**, used by the historical WordPress API. Still used by some mobile clients, remote editors, or plugins.

* `php-soap`
  Allows communications via the **SOAP** protocol, used by some third-party plugins or import/export services.

* `php-zip`
  Allows **reading and extracting ZIP archives**, essential for installing plugins, themes, or updates via the WordPress interface.

* `php-intl`
  Provides functions for **localization, sorting, and formatting of dates and strings** according to the language. Required for supporting WordPress in French and other languages.

* `php-opcache`
  Improves PHP performance by **caching compiled code**. Strongly recommended for any WordPress site, even in development.

### # Complementary tools

* `curl`
  Used to download **WP-CLI** and WordPress. A more versatile command-line tool than `wget`.

* `mariadb-client`
  Allows manually testing or diagnosing the connection to the database from the WordPress container. Useful during development, but not strictly required at runtime.

### WP-CLI

The Inception subject **prohibits any manual post-deployment configuration**. However, a classic WordPress installation requires:

1. Manually creating the `wp-config.php` file (with the database information)
2. Launching the setup via a web browser
3. Entering the admin credentials, site name, URL, etc.
4. Creating an additional user (optional)

These steps require a web interface and human interaction, **which is incompatible with an automated deployment in a container**.

In addition to installing `php` (and its dependencies) and `wordpress`, we will therefore have to install **WP-CLI**, a command-line tool for managing a WordPress installation in an automated way, without going through the web interface.
Once installed as an executable in `/usr/local/bin`, it can be used via the simple command `wp`.

WP-CLI allows automating:

* The creation of the `wp-config.php` file:

  ```bash
  wp config create --dbname="$MDB_NAME" --dbuser="$MDB_USER" --dbpass="$MDB_USER_PASS" --dbhost="mariadb"
  ```

* The complete installation of WordPress:

  ```bash
  wp core install --url="$DOMAIN_NAME" --title="$WEBSITE_TITLE" --admin_user="$WP_ADMIN_LOGIN" ...
  ```

* The creation of a secondary user account:

  ```bash
  wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" --role=author ...
  ```

* The configuration of Redis or other settings via:

  ```bash
  wp config set WP_REDIS_HOST redis
  ```

> WP-CLI is a **key** component for automating the entire WordPress installation in a Docker environment, as required in the Inception project.
> It replaces all interactive steps of the WordPress setup with **executable commands in a script**, which ensures a consistent, fast, and manual-intervention-free deployment.

### WORDPRESS DOCKERFILE

#### File content

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

#### Explanations

```dockerfile
FROM debian:11.11
```

Defines the base image. Here, a stable Debian image (version 11.11) is used for its compatibility with PHP 7.4, required by many WordPress plugins.

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

Updates packages and installs:

* **PHP** and its PHP-FPM interpreter
* All **extensions necessary for WordPress**: database (`php-mysql`), text management (`php-mbstring`), image manipulation (`php-gd`), XML/RSS management (`php-xml`), SOAP/XML-RPC (`php-soap`, `php-xmlrpc`), ZIP files (`php-zip`), internationalization (`php-intl`), and performance (`php-opcache`)
* The **MariaDB client** to test the connection to the database
* **curl**, used to download WordPress and WP-CLI

Finally, the package cache is cleaned to lighten the image.

```dockerfile
RUN mkdir -p /run/php
```

This command manually creates the `/run/php` directory, which is necessary for the operation of PHP-FPM. Indeed, when it starts, PHP-FPM tries to create a Unix socket (a special inter-process communication file) in this folder, by default at the following location: `/run/php/php7.4-fpm.sock`.
If this folder does not exist, the PHP-FPM service fails to start.
Creating this folder preventively ensures compatibility and avoids any error at PHP-FPM startup, especially in a lightweight container where many directories are not created automatically.

```dockerfile
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
```

Copies the `www.conf` configuration file into the PHP-FPM configuration folder.
This file defines:

* the listening port (9000)
* the user (`www-data`)
* the process management strategy (`pm = dynamic`, etc.)
* the transfer of environment variables (`clear_env = no`)

```dockerfile
RUN curl -o /var/www/wordpress.tar.gz https://fr.wordpress.org/wordpress-6.8.2-fr_FR.tar.gz && \
    tar -xzf /var/www/wordpress.tar.gz -C /var/www && \
    rm /var/www/wordpress.tar.gz && \
    chown -R www-data:www-data /var/www/wordpress
```

Downloads the official French WordPress archive (version 6.8.2), extracts it to `/var/www`, then deletes the archive.
The files are then assigned to the `www-data` user to allow PHP-FPM to access them in read/write.

```dockerfile
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
```

Downloads WP-CLI (command-line tool for managing WordPress), gives it execution rights, and moves it to `/usr/local/bin` to be able to call it simply with `wp`.

```dockerfile
EXPOSE 9000
```

Indicates that the container is listening on port **9000**, used by **PHP-FPM** to receive FastCGI requests from the NGINX container.

```dockerfile
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```

Copies the `entrypoint.sh` script into the container and makes it executable.
This script automatically initializes WordPress at startup, using WP-CLI (`wp config create`, `wp core install`, etc.).

```dockerfile
WORKDIR /var/www/wordpress
```

Sets the working directory for the following instructions and for the container at runtime.
This allows, in particular, to run `wp` without having to specify `--path`.

```dockerfile
ENTRYPOINT [ "/entrypoint.sh" ]
```

Defines the entry point of the container: the `entrypoint.sh` script will be executed automatically at launch, to configure and launch WordPress.

### THE `entrypoint.sh` SCRIPT

In a Docker container, the `entrypoint.sh` script acts as **the starting point** of execution.
It is the one that is called automatically when the container is launched (thanks to the `ENTRYPOINT` directive in the `Dockerfile`).

#### Role of the script

In the context of the Inception project, this script allows **automatically preparing and launching WordPress** as soon as the container starts, without any manual intervention.

Concretely, it will:

1. Check if WordPress is already configured (e.g., if `wp-config.php` exists)
2. If not:
   * Generate a `wp-config.php` file with the correct environment variables
   * Install WordPress (`wp core install`) with the admin credentials, URL, site title, etc.
   * Create a secondary user
   * Possibly apply other settings (like Redis for bonuses)
3. Start the PHP-FPM service in **foreground** mode (`-F`) so that the container remains active

#### Why not do this in the Dockerfile?

Because the `Dockerfile` is **executed when the image is built**, and WordPress **must be configured dynamically each time the container is run**, depending on:

* the **environment variables** (`MDB_NAME`, `WP_ADMIN_LOGIN`, etc.)
* the state of the database (empty or not)
* or even the shared volume (the `wp-config.php` may already exist)

Only a **script executed at runtime** (at container startup) can handle this conditional logic.

#### Environment variables

In order to configure `wordpress` we will have to add certain environment variables to our `.env` file:

* `DOMAIN_NAME`
  The domain name: <login>.42.fr as required by the subject

* `WEBSITE_TITLE`
  The name of the site

* `WP_ADMIN_LOGIN`
  The site administrator's login

* `WP_ADMIN_PASS`
  The administrator password

* `WP_ADMIN_EMAIL`
  The administrator's email

* `WP_USER_LOGIN`
  The user's login

* `WP_USER_EMAIL`
  The user's email

* `WP_USER_PASS`
  The user's password

```env
# MariaDB Configuration
MDB_NAME=inception
MDB_USER=<your_username>
MDB_ROOT_PASS=<password>
MDB_USER_PASS=<password>

# WordPress Configuration
DOMAIN_NAME=<login>.42.fr
WEBSITE_TITLE=Inception
WP_ADMIN_LOGIN=<your_admin_name>
WP_ADMIN_EMAIL=<your_admin_email>
WP_ADMIN_PASS=<password>
WP_USER_LOGIN=<your_username>
WP_USER_EMAIL=<your_user_email>
WP_USER_PASS=<password>
```

#### The script

```bash
#!/bin/bash

until mysqladmin ping -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" --silent; do
  # Display a message every 2 seconds while waiting
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

#### Explanations

```bash
#!/bin/bash
```

Indicates that the script should be interpreted with Bash.

```bash
if [ ! -f wp-config.php ]; then
```

Tests if the `wp-config.php` file does not yet exist. If so, it means that WordPress is not yet configured.

```bash
until mysqladmin ping -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" --silent; do
  echo "Waiting for MariaDB to be ready..."
  sleep 2
done
```

Before starting the WordPress installation with WP-CLI, we check that the MariaDB service is operational.
We use `mysqladmin ping` to test the connection to the database in a loop.
As long as the database is not available (the MariaDB container often starts more slowly), the script waits and displays a message every 2 seconds.
This ensures that WordPress does not try to connect to MariaDB too early, which would lead to an installation error.

```bash
    wp config create \
        --dbname="$MDB_NAME" \
        --dbuser="$MDB_USER" \
        --dbpass="$MDB_USER_PASS"\
        --dbhost="mariadb" \
        --path=/var/www/wordpress \
        --allow-root
```

Uses `wp-cli` to generate a `wp-config.php` file from the environment variables defined in the `.env`.
`--allow-root` is required because `wp-cli` is executed with root rights in the container.
The file is generated in `/var/www/wordpress`.

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

Launches the WordPress installation with the site information (URL, title) and the main administrator's credentials.
The `--skip-email` option disables sending a confirmation email (useless in this context).

```bash
    wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS" \
        --allow-root
```

Creates a second WordPress user with the `author` role, useful for testing or demonstrating multi-user access.

```bash
exec /usr/sbin/php-fpm7.4 -F
```

Launches PHP-FPM in **foreground** mode (`-F`) so that the container remains active.
The `exec` replaces the current shell process with PHP-FPM, as recommended by Docker.

---

## FINALIZE THE `docker-compose.yml` FILE

Now that we have our three `Dockerfile`s, we can complete the `docker-compose.yml` to integrate the `wordpress` container.

But before that, we need to address two new `docker compose` concepts:
- volumes
- `depends_on`
- `restart`

### VOLUMES: DATA PERSISTENCE

In Docker, a **volume** is a storage space independent of the container lifecycle.
It allows **preserving data even if a container is deleted or rebuilt**, by storing it on the host machine.
In the context of the Inception project, the use of volumes is **mandatory** to ensure the **persistence of MariaDB data** (the databases) and **WordPress** (files, plugins, uploaded images, etc.).

Volumes are declared in the `volumes:` section of the `docker-compose.yml` file.
To comply with the subject's constraints, they must use the **`none` type** and be **mounted on local folders located in `~/data`**, via the `device` option.

> In Inception, the subject requires that volumes be **neither anonymous nor purely named**, but that they be **explicitly linked to a local directory on the host machine**, located in `~/data`.
>
> To do this, we use the **`local` driver** with the `driver_opts` option:
>
> - `type: none` indicates that the volume **uses no special file system** (like tmpfs or nfs).
> - `device: ~/data/<service>` specifies **the exact path on the host system** to mount in the container.
> - `o: bind` means that it is a **"bind" type mount**, which directly links the local folder to the container's internal folder.
>
> This mechanism allows **visualizing and manipulating data directly on the machine**, while respecting the subject's requirements (one folder per service in `~/data/`).

Since the data will be saved locally on our host machine, we need to create the necessary folders on the host machine:

```bash
mkdir -p ~/data/wordpress ~/data/mariadb
```

> 📝 **Important note:**
>
> The following command allows stopping all containers launched with `docker compose`, and deleting the associated Docker volumes:
>
> ```bash
> docker compose down -v
> ```
>
> However, in the context of the **Inception** project, the volumes are **not real Docker volumes**, but **local folders linked by a bind mount** (like `~/data/mariadb`).
>
> ⚠️ This means that **the content of these folders is not deleted** by the `docker compose down -v` command.
>
> To completely reset the environment (databases, WordPress files…), you must also **manually delete** the local data:
>
> ```bash
> sudo rm -rf ~/data/mariadb/* ~/data/wordpress/*
> ```

### MANAGING STARTUP ORDER WITH `depends_on`

In a multi-container environment, it is essential that some services be started **before** others.
For example, WordPress must be able to connect to MariaDB at launch.
The `depends_on` directive allows defining these **dependency relationships** in the `docker-compose.yml` file.

When a service A depends on a service B (`depends_on: - B`), Docker will ensure to **launch B before A**, but does not guarantee that B is **fully ready** (e.g., that MariaDB already accepts connections).
For this, mechanisms like `healthcheck` or waiting scripts in the `entrypoint.sh` can be used if needed.
In Inception, `depends_on` and the precautions taken in the scripts are sufficient to ensure a structured launch of the services.

### RESTART POLICY WITH `restart`

The **Inception** subject explicitly tells us that the containers must restart in case of a crash.
For this we will use the `restart` directive and give it the value `unless-stopped`, which means that the container will restart automatically if it stops unless we have stopped it ourselves manually (with `docker stop` for example).

> The `restart` option allows defining the automatic restart behavior of containers.
> Possible values are:
> 
> * `no` *(or default value)*:
>   The container does not restart automatically.
> * `always`:
>   The container restarts systematically, even if it has been stopped manually.
> * `on-failure`:
>   The container restarts only in case of failure (exit code different from `0`).
> * `on-failure:N`:
>   Same behavior as `on-failure`, but limits the number of restarts to `N`.
> * `unless-stopped`:
>   The container restarts automatically **unless** it has been stopped manually.
> 
> This option is ignored if you use `docker compose run`, but it works with `docker compose up`.

### THE FINAL FILE

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
  wordpress:
    driver: local
    driver_opts:
      type: none
      device: ~/data/wordpress
```
