#!/bin/bash
# Instalador de Stunnel4 como frente TLS en el puerto 443 para V2Ray
# Arquitectura:
#   Cliente --TLS 443--> Stunnel4 --plano 127.0.0.1:8443--> V2Ray Vmess (ws, sin TLS)
# Asi el 443 lo escucha SOLO Stunnel4, y V2Ray queda detras, sin pelear por el puerto.
# El certificado es el mismo que ya usa V2Ray: /etc/v2ray/v2ray.crt y /etc/v2ray/v2ray.key
# Si aun no tienes certificado, corre primero install/ssl.sh (Certbot) o el
# instalador de V2Ray, que ya lo genera con acme.sh en esa ruta.
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

# Parar V2Ray en 443 si aun esta ahi, para liberar el puerto para Stunnel4
# (ins-vt.sh actualizado ya pone Vmess en 8443 interno, sin TLS)
systemctl stop v2ray 2>/dev/null || true

cat > /etc/stunnel/stunnel.conf << 'STUNNEL'
cert = /etc/v2ray/v2ray.crt
key = /etc/v2ray/v2ray.key
foreground = no
pid = /var/run/stunnel4/stunnel.pid
output = /var/log/stunnel4/stunnel.log
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[v2ray-443]
accept = 443
connect = 127.0.0.1:8443
STUNNEL

mkdir -p /var/run/stunnel4 /var/log/stunnel4
chown -R stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4 2>/dev/null || true

sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
grep -q '^ENABLED=1' /etc/default/stunnel4 || echo 'ENABLED=1' >> /etc/default/stunnel4

systemctl enable stunnel4
systemctl restart stunnel4
systemctl start v2ray 2>/dev/null || systemctl restart v2ray 2>/dev/null || true

echo -e "${green}Stunnel4 escuchando en 443, reenviando a V2Ray en 127.0.0.1:8443${NC}"
echo "  Cliente TLS 443 -> Stunnel4 -> V2Ray Vmess ws plano en 8443"
ss -tlnp 2>/dev/null | grep -E ':443|:8443' || netstat -tlnp 2>/dev/null | grep -E ':443|:8443' || true
