# mustafa

Instaladores de VPN reunidos en un solo repo.

- `setup.sh` — instalador principal, de titlan/full, "Script Mod Modified By Prince", 24-1-22. Pide un dominio y luego instala los servicios de abajo.
- `install/ssh-vpn.sh` — SSH / OpenVPN
- `websocket-python/websocket.sh` — WebSocket Python
- `install/sstp.sh` — SSTP
- `install/wg.sh` — WireGuard
- `install/ssr.sh` — Shadowsocks-R
- `install/shadowsocksobfs.sh` — Shadowsocks OBFS
- `install/ins-vt.sh` — V2Ray
- `install/ipsec.sh` — L2TP/IPSEC

Los 8 instaladores de servicios vienen de syapik96/aws (rama main), que es la fuente que usa setup.sh.

Uso: correr setup.sh como root en un VPS limpio, con un dominio ya apuntado al servidor.
