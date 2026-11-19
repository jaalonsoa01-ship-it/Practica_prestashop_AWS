#!/bin/bash
set -e
if [ "$EUID" -ne 0 ]; then echo "Error: Ejecuta este script con sudo (sudo $0)"; exit 1; fi
source "$(dirname "$0")/.env"

echo "=== 1. Instalando Certbot y plugin DNS para DuckDNS ==="
apt-get update
apt-get install -y certbot python3-pip
pip3 install --break-system-packages certbot-dns-duckdns

echo "=== 2. Configurando credenciales de DuckDNS ==="
cat << CRED > /root/duckdns.ini
dns_duckdns_token = ${DUCKDNS_TOKEN}
CRED
chmod 600 /root/duckdns.ini

echo "=== 3. Solicitando certificado SSL/TLS a Let's Encrypt (Validación DNS-01) ==="
certbot certonly \
    --non-interactive \
    --agree-tos \
    --email "${CERTBOT_EMAIL}" \
    --authenticator dns-duckdns \
    --dns-duckdns-credentials /root/duckdns.ini \
    --dns-duckdns-propagation-seconds 60 \
    -d "${DOMAIN}"

echo "=== 4. Configurando VirtualHost SSL en Apache ==="
cat << VHOST > /etc/apache2/sites-available/default-ssl.conf
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerName ${DOMAIN}
        ServerAdmin ${CERTBOT_EMAIL}
        DocumentRoot ${PS_DIR}

        <Directory ${PS_DIR}>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        SSLEngine on
        SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
</IfModule>
VHOST

a2ensite default-ssl.conf
systemctl reload apache2

echo "=== Certificado SSL configurado correctamente para https://${DOMAIN} ==="