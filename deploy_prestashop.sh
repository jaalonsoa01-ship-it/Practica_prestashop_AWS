#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]; then echo "Error: Ejecuta este script con sudo (sudo $0)"; exit 1; fi
source "$(dirname "$0")/.env"

# Determinar el dominio completo con puerto si estamos en VirtualBox NAT
if [ -n "$HTTPS_PORT" ]; then
    FULL_DOMAIN="${DOMAIN}:${HTTPS_PORT}"
else
    FULL_DOMAIN="${DOMAIN}"
fi

echo "=== 1. Descargando PrestaShop ${PS_VERSION} ==="
cd /tmp
wget -q "https://github.com/PrestaShop/PrestaShop/releases/download/${PS_VERSION}/prestashop_${PS_VERSION}.zip" -O prestashop.zip



echo "=== 2. Extrayendo archivos en ${PS_DIR} ==="
rm -f "${PS_DIR}/index.html"
unzip -q prestashop.zip -d /tmp/ps_extract
unzip -q /tmp/ps_extract/prestashop.zip -d "${PS_DIR}"
rm -rf /tmp/prestashop.zip /tmp/ps_extract

chown -R www-data:www-data "${PS_DIR}"
chmod -R 755 "${PS_DIR}"

echo "=== 3. Ejecutando instalación de PrestaShop por CLI ==="
sudo -u www-data php "${PS_DIR}/install/index_cli.php" \
    --domain="${FULL_DOMAIN}" \
    --db_server="${DB_HOST}" \
    --db_name="${DB_NAME}" \
    --db_user="${DB_USER}" \
    --db_password="${DB_PASS}" \
    --prefix="ps_" \
    --name="${PS_SHOP_NAME}" \
    --country="${PS_COUNTRY}" \
    --language="${PS_LANGUAGE}" \
    --firstname="${PS_FIRSTNAME}" \
    --lastname="${PS_LASTNAME}" \
    --email="${PS_EMAIL}" \
    --password="${PS_PASSWD}" \
    --ssl=1

echo "=== 4. Limpiando carpeta de instalación y renombrando admin ==="
rm -rf "${PS_DIR}/install"
mv "${PS_DIR}/admin" "${PS_DIR}/${PS_FOLDER_ADMIN}"
chown -R www-data:www-data "${PS_DIR}"

systemctl restart apache2

echo "================================================================="
echo " ¡Despliegue completado con éxito!"
echo " Tienda Front-Office: https://${FULL_DOMAIN}"
echo " Panel Back-Office:   https://${FULL_DOMAIN}/${PS_FOLDER_ADMIN}"
echo " Verificación PHP:    https://${FULL_DOMAIN}/phppsinfo.php"
echo "================================================================="