#!/bin/bash
# SSL reemplazado por Stunnel4 en este repo.
# El puerto 443 ahora lo escucha Stunnel4 y lo reenvia a V2Ray en 127.0.0.1:8443.
# Este archivo solo redirige al instalador de Stunnel4.
echo "SSL ahora es Stunnel4 en el puerto 443. Instalando stunnel..."
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$DIR/stunnel.sh" ]; then
    bash "$DIR/stunnel.sh"
else
    echo "No encontre stunnel.sh junto a este archivo. Baja el repo completo."
    exit 1
fi
