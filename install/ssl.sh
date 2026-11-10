#!/bin/bash
# Instalador de SSL con Let's Encrypt (Certbot)
# Para usar con los servicios de este repo (V2Ray, Trojan, etc.)
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

echo -e "${yellow}Solicitando certificado para $domain...${NC}"
if [ -n "$email" ]; then
    certbot certonly --standalone --agree-tos --non-interactive --email "$email" -d "$domain"
else
    certbot certonly --standalone --agree-tos --non-interactive --register-unsafely-without-email -d "$domain"
fi

if [ ! -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
    echo -e "${red}No se pudo obtener el certificado. Revisa que el dominio apunte a este VPS y que el puerto 80 este libre.${NC}"
    exit 1
fi

echo -e "${green}Certificado instalado:${NC}"
echo "  /etc/letsencrypt/live/$domain/fullchain.pem"
echo "  /etc/letsencrypt/live/$domain/privkey.pem"
echo ""
echo "Para V2Ray, copia o usa esas rutas en tu configuracion."
echo "Renovacion automatica: certbot renew (ya viene con un timer en Debian/Ubuntu)."
