# mustafa

Instaladores de VPN reunidos en un solo repo.

- `setup.sh` — instalador principal, de titlan/full, "Script Mod Modified By Prince", 24-1-22. Pide un dominio y luego instala los servicios de abajo.
- `install/ssh-vpn.sh` — SSH / OpenVPN
- `websocket-python/websocket.sh` — WebSocket Python
- `install/sstp.sh` — SSTP
- `install/wg.sh` — WireGuard
- `install/ssr.sh` — Shadowsocks-R
- `install/shadowsocksobfs.sh` — Shadowsocks OBFS
- `install/ins-vt.sh` — V2Ray (Vmess TLS en 8443 interno, detras de HAProxy en 443)
- `install/ipsec.sh` — L2TP/IPSEC
- `install/stunnel.sh` — Stunnel4 en 127.0.0.1:8444 interno, detras de HAProxy en 443, hacia SSH
- `install/haproxy.sh` — HAProxy en 443, reparte por SNI: V2Ray y Stunnel4
- `install/ssl.sh` — reemplazado por Stunnel4, solo redirige a stunnel.sh

Los 8 instaladores de servicios vienen de syapik96/aws (rama main), que es la fuente que usa setup.sh.

Uso: correr setup.sh como root en un VPS limpio, con un dominio ya apuntado al servidor.
