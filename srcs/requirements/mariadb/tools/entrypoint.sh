#!/bin/bash

set -e

: "${MDB_NAME:?Variable d'environnement MDB_NAME manquante}"
: "${MDB_USER:?Variable d'environnement MDB_USER manquante}"
: "${MDB_USER_PASS:?Variable d'environnement MDB_USER_PASS manquante}"
: "${MDB_ROOT_PASS:?Variable d'environnement MDB_ROOT_PASS manquante}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initializing database..."
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
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS \`${MDB_NAME}\`;"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS \`${MDB_USER}\`@'%' IDENTIFIED BY '${MDB_USER_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON \`${MDB_NAME}\`.* TO \`${MDB_USER}\`@'%';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MDB_ROOT_PASS}';"
mariadb -u root -p"${MDB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p"${MDB_ROOT_PASS}" shutdown

echo "✅ MariaDB starts..."
exec mysqld_safe
