#!/usr/bin/env bash
set -eo pipefail

echo "=================================================="
echo "  Inicializando entorno de Homelab y Permisos"
echo "=================================================="

DATA_DIRS=(
  "/opt/homelab/data/npm/data"
  "/opt/homelab/data/npm/letsencrypt"
  "/opt/homelab/data/prometheus"
  "/opt/homelab/data/grafana"
  "/opt/homelab/data/uptime-kuma"
)

echo "1. Creando estructura de directorios en /opt/homelab/data..."
for dir in "${DATA_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    sudo mkdir -p "$dir"
    echo "  [+] Creado: $dir"
  else
    echo "  [.] Existe: $dir"
  fi
done

echo ""
echo "2. Aplicando propiedad de usuarios (UID/GID) requeridos..."
# Prometheus: usuario 'nobody' (UID 65534)
sudo chown -R 65534:65534 /opt/homelab/data/prometheus
echo "  [✓] Prometheus chown -> 65534:65534"

# Grafana: usuario 'grafana' (UID 472)
sudo chown -R 472:472 /opt/homelab/data/grafana
echo "  [✓] Grafana chown -> 472:472"

sudo chmod -R 775 /opt/homelab/data/prometheus
sudo chmod -R 775 /opt/homelab/data/grafana

echo ""
echo "3. Verificando red Docker..."
if ! docker network inspect proxy-net >/dev/null 2>&1; then
  docker network create proxy-net
  echo "  [✓] Red 'proxy-net' creada."
else
  echo "  [.] Red 'proxy-net' ya existe."
fi

echo ""
echo "✅ Entorno listo. Ahora puedes ejecutar 'docker compose up -d' sin errores de permisos."
