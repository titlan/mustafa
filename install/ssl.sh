#!/bin/bash
# Instalador de SSL compartido con V2Ray en el puerto 443
# Idea: el puerto 443 lo atiende SOLO V2Ray (Vmess TLS).
# Certbot solo usa el puerto 80, brevemente, para validar el dominio,
# y deja el certificado en el mismo lugar que usa V2Ray:
#   /etc/v2ray/v2ray.crt  y  /etc/v2ray/v2ray.key
# Asi no hay otro servidor peleando por el 443.
# Uso: sudo bash install/ssl.sh
# Requisito: el dominio ya debe apuntar a la IP de este VPS

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
NC='\e[0m'

if [ "${EUID}" -ne 0 ]; then
    echo -e "${red}Necesitas correr este script como root${NC}"
    exit 1
fi

read -rp "Dominio (ej. vpn.tu-dominio.com): " domain
if [ -z "$domain" ]; then
    echo -e "${red}Dominio vacio, saliendo${NC}"
    exit 1
fi

read -rp "Email para Let's Encrypt (opcional, Enter para omitir): " email

echo -e "${yellow}Instalando Certbot...${NC}"
apt-get update -y
apt-get install -y certbot

# Hook que copia el certificado renovado a donde lo espera V2Ray
# y reinicia V2Ray para que tome el nuevo certificado.
mkdir -p /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/v2ray-443.sh << 'HOOK'
#!/bin/bash
# $RENEWED_LINEAGE es el directorio del certificado renovado
mkdir -p /etc/v2ray
cp "$RENEWED_LINEAGE/fullchain.pem" /etc/v2ray/v2ray.crt
cp "$RENEWED_LINEAGE/privkey.pem" /etc/v2ray/v2ray.key
chmod 600 /etc/v2ray/v2ray.key
if systemctl is-active --quiet v2ray; then
    systemctl restart v2ray
fi
HOOK
chmod +x /etc/letsencrypt/renewal-hooks/deploy/v2ray-443.sh

echo -e "${yellow}Solicitando certificado para $domain (validacion por puerto 80, el 443 queda para V2Ray)...${NC}"
if [ -n "$email" ]; then
    certbot certonly --standalone --agree-tos --non-interactive --email "$email" -d "$domain" --deploy-hook /etc/letsencrypt/renewal-hooks/deploy/v2ray-443.sh
else
    certbot certonly --standalone --agree-tos --non-interactive --register-unsafely-without-email -d "$domain" --deploy-hook /etc/letsencrypt/renewal-hooks/deploy/v2ray-443.sh
fi

if [ ! -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
    echo -e "${red}No se pudo obtener el certificado. Revisa que el dominio apunte a este VPS y que el puerto 80 este libre.${NC}"
    exit 1
fi

# Compartir el certificado con V2Ray en el mismo puerto 443
mkdir -p /etc/v2ray
cp "/etc/letsencrypt/live/$domain/fullchain.pem" /etc/v2ray/v2ray.crt
cp "/etc/letsencrypt/live/$domain/privkey.pem" /etc/v2ray/v2ray.key
chmod 600 /etc/v2ray/v2ray.key

if systemctl is-active --quiet v2ray; then
    systemctl restart v2ray
    echo -e "${green}V2Ray reiniciado con el nuevo certificado en el puerto 443.${NC}"
fi

echo -e "${green}SSL compartido con V2Ray en el puerto 443:${NC}"
echo "  Certbot: /etc/letsencrypt/live/$domain/fullchain.pem"
echo "  V2Ray:   /etc/v2ray/v2ray.crt  y  /etc/v2ray/v2ray.key"
echo "  V2Ray Vmess TLS: 443"
echo "  Renovacion: certbot renew copia el nuevo cert a /etc/v2ray y reinicia V2Ray."
