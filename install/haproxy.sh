#!/bin/bash
# Instalador de HAProxy en el puerto 443, compartido por V2Ray y Stunnel4
# Arquitectura:
#   Cliente --TLS 443--> HAProxy (reparte por SNI)
#     SNI v2ray.tu-dominio.com  --> V2Ray TLS 127.0.0.1:8443
#     SNI ssh.tu-dominio.com    --> Stunnel4 TLS 127.0.0.1:8444 --> SSH 127.0.0.1:22
# Solo HAProxy escucha en 443. V2Ray y Stunnel4 escuchan en puertos internos.
# Requisito: los dos dominios deben ser DISTINTOS, si no HAProxy no los puede
# distinguir por SNI. Ambos deben apuntar a la IP de este VPS.
# Uso: sudo bash install/haproxy.sh

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
NC='\e[0m'

if [ "${EUID}" -ne 0 ]; then
    echo -e "${red}Necesitas correr este script como root${NC}"
    exit 1
fi

read -rp "Dominio para V2Ray (ej. vpn.tu-dominio.com): " v2ray_domain
read -rp "Dominio para Stunnel/SSH (ej. ssh.tu-dominio.com): " stunnel_domain
if [ -z "$v2ray_domain" ] || [ -z "$stunnel_domain" ]; then
    echo -e "${red}Falta un dominio, saliendo${NC}"
    exit 1
fi
if [ "$v2ray_domain" = "$stunnel_domain" ]; then
    echo -e "${red}Los dos dominios deben ser distintos para que HAProxy los distinga por SNI.${NC}"
    exit 1
fi

echo -e "${yellow}Instalando HAProxy...${NC}"
apt-get update -y
apt-get install -y haproxy

# Liberar el 443 si Stunnel4 o V2Ray lo estaban usando directo
systemctl stop stunnel4 2>/dev/null || true

cat > /etc/haproxy/haproxy.cfg << HAPROXY
global
    log /dev/log local0
    maxconn 4096

defaults
    log global
    mode tcp
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend https-443
    bind :443
    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }

    use_backend v2ray if { req.ssl_sni -i $v2ray_domain }
    use_backend stunnel if { req.ssl_sni -i $stunnel_domain }
    default_backend v2ray

backend v2ray
    mode tcp
    server v2ray 127.0.0.1:8443 check

backend stunnel
    mode tcp
    server stunnel 127.0.0.1:8444 check
HAPROXY

haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl enable haproxy
systemctl restart haproxy
systemctl start stunnel4 2>/dev/null || true
systemctl start v2ray 2>/dev/null || true

echo -e "${green}HAProxy escuchando en 443:${NC}"
echo "  $v2ray_domain  -> V2Ray TLS 127.0.0.1:8443"
echo "  $stunnel_domain -> Stunnel4 TLS 127.0.0.1:8444 -> SSH 127.0.0.1:22"
