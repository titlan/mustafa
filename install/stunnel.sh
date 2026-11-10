#!/bin/bash
# Instalador de Stunnel4 detras de HAProxy
# Arquitectura con HAProxy en 443:
#   Cliente --TLS 443--> HAProxy (por SNI) --> Stunnel4 127.0.0.1:8444 --plano--> SSH 127.0.0.1:22
# Stunnel4 ya NO escucha en 443 directo, escucha en 8444 interno.
# Si lo corres sin HAProxy, cambia accept a 443 en /etc/stunnel/stunnel.conf.
# Certificado: /etc/v2ray/v2ray.crt y /etc/v2ray/v2ray.key
# Uso: sudo bash install/stunnel.sh

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
NC='\e[0m'

if [ "${EUID}" -ne 0 ]; then
    echo -e "${red}Necesitas correr este script como root${NC}"
    exit 1
fi

if [ ! -f /etc/v2ray/v2ray.crt ] || [ ! -f /etc/v2ray/v2ray.key ]; then
    echo -e "${red}No encontre /etc/v2ray/v2ray.crt y /etc/v2ray/v2ray.key${NC}"
    echo "Primero genera el certificado (install/ssl.sh o ins-vt.sh) y vuelve a correr este script."
    exit 1
fi

echo -e "${yellow}Instalando Stunnel4...${NC}"
apt-get update -y
apt-get install -y stunnel4

cat > /etc/stunnel/stunnel.conf << 'STUNNEL'
cert = /etc/v2ray/v2ray.crt
key = /etc/v2ray/v2ray.key
foreground = no
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ssh-8444]
accept = 127.0.0.1:8444
connect = 127.0.0.1:22
STUNNEL

mkdir -p /var/run/stunnel4 /var/log/stunnel4
chown -R stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4 2>/dev/null || true

sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
grep -q '^ENABLED=1' /etc/default/stunnel4 || echo 'ENABLED=1' >> /etc/default/stunnel4

systemctl enable stunnel4
systemctl restart stunnel4

echo -e "${green}Stunnel4 escuchando en 127.0.0.1:8444, reenviando a SSH en 127.0.0.1:22${NC}"
echo "HAProxy en 443 lo alcanza por SNI. Sin HAProxy, cambia accept a 443 en /etc/stunnel/stunnel.conf."
