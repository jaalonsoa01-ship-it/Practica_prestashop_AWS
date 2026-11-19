#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]; then echo "Error: Ejecuta este script con sudo (sudo $0)"; exit 1; fi
# Cargar variables de entorno
source "$(dirname "$0")/.env"

echo "=== 1. Actualizando repositorios ==="
apt-get update && apt-get upgrade -y

echo "=== 2. Instalando Apache y MySQL Server ==="
apt-get install -y apache2 mysql-server unzip curl wget git

# Configurar contraseña de root en MySQL y crear base de datos
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';"
mysql -uroot -p"${DB_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -p"${DB_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -uroot -p"${DB_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -uroot -p"${DB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

echo "=== 3. Instalando PHP y extensiones requeridas por PrestaShop ==="
apt-get install -y php libapache2-mod-php php-mysql php-curl php-gd php-intl \
    php-mbstring php-xml php-zip php-bcmath php-imagick php-soap php-cli

# Detectar versión instalada de PHP para modificar el php.ini correcto
PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_INI="/etc/php/${PHP_VER}/apache2/php.ini"

echo "=== 4. Ajustando directivas en ${PHP_INI} ==="
sed -i "s/^memory_limit = .*/memory_limit = 256M/" "$PHP_INI"
sed -i "s/^;*max_input_vars = .*/max_input_vars = 5000/" "$PHP_INI"
sed -i "s/^post_max_size = .*/post_max_size = 128M/" "$PHP_INI"
sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 128M/" "$PHP_INI"
sed -i "s/^;*date.timezone =.*/date.timezone = Europa\/Madrid/" "$PHP_INI"

echo "=== 5. Instalando phpMyAdmin de forma desatendida ==="
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password ${DB_ROOT_PASS}" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${DB_ROOT_PASS}" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password ${DB_ROOT_PASS}" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
apt-get install -y phpmyadmin

echo "=== 6. Copiando configuración de VirtualHost y activando módulos Apache ==="
cp "$(dirname "$0")/../conf/000-default.conf" /etc/apache2/sites-available/000-default.conf
a2enmod rewrite headers ssl
systemctl restart apache2

echo "=== 7. Descargando PhpPsInfo para verificación ==="
wget -q https://raw.githubusercontent.com/PrestaShop/php-ps-info/master/phppsinfo.php -O /var/www/html/phppsinfo.php
chown www-data:www-data /var/www/html/phppsinfo.php
echo "=== Pila LAMP instalada y configurada correctamente ==="

