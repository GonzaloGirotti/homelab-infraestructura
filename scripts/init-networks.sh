#!/usr/bin/env bash
set -eo pipefail

NETWORK_NAME="proxy-net"

echo "🔍 Verificando existencia de la red Docker '${NETWORK_NAME}'..."

if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    echo "⚙️  Creando red Docker externa tipo bridge: '${NETWORK_NAME}'..."
    docker network create "${NETWORK_NAME}"
    echo "✅ Red '${NETWORK_NAME}' creada con éxito."
else
    echo "ℹ️  La red '${NETWORK_NAME}' ya existe. Omitiendo creación."
fi

echo "🚀 Infraestructura de red lista para el despliegue de los stacks."
