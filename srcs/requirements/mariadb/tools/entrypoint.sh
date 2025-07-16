#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure required environment variables are defined
: "${SQL_DATABASE:?environment variable SQL_DATABASE is mandatory}"
: "${SQL_USER:?environment variable SQL_USER is mandatory}"
: "${SQL_PASSWORD:?environment variable SQL_PASSWORD is mandatory}"
: "${SQL_ROOT_PASSWORD:?environment variable SQL_ROOT_PASSWORD is mandatory}"

# Prepare the socket directory (required in some Debian-based containers)
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Initialize the database if it hasn't been initialized yet
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --ldata=/var/lib/mysql > /dev/null
fi

# Start MariaDB temporarily in the background without networking
echo "Starting MariaDB temporarily..."
mysqld_safe --skip-networking &
pid="$!"

# Wait for MariaDB to become ready
for i in {30..0}; do
  if mysqladmin ping &>/dev/null; then
    break
  fi
  echo -n "."
  sleep 1
done

# If MariaDB didn't start in time, exit with error
if [ "$i" = 0 ]; then
  echo "❌ Failed to start MariaDB."
  exit 1
fi

# Execute SQL setup: create database, user, grant privileges, set root password
echo "🛠 Setting up database and user access..."
mysql -u root -p"${SQL_ROOT_PASSWORD}" <<-EOSQL
  CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
  CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';
  GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
  FLUSH PRIVILEGES;
EOSQL

# Shutdown temporary MariaDB instance
mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown

# Start MariaDB in the foreground for Docker (replaces current process)
echo "✅ Starting MariaDB in production mode..."
exec mysqld_safe
