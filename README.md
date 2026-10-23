# 🖥️ Enterprise-Grade Homelab Infrastructure

[![Linux](https://img.shields.io/badge/OS-Ubuntu%20Server%2022.04%2F24.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/server)
[![Docker](https://img.shields.io/badge/Container-Docker%20%7C%20Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Reverse Proxy](https://img.shields.io/badge/Reverse%20Proxy-Nginx%20Proxy%20Manager-009639?logo=nginx&logoColor=white)](https://nginxproxymanager.com/)
[![Observability](https://img.shields.io/badge/Metrics-Prometheus%20%2B%20Grafana-F46800?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Uptime Monitoring](https://img.shields.io/badge/Availability-Uptime%20Kuma-2AF598?logo=statuspage&logoColor=white)](https://github.com/louislam/uptime-kuma)
[![Security](https://img.shields.io/badge/Security-Zero%20Trust%20%7C%20Firewalld%20%7C%20TLS-critical)](#-seguridad-y-perímetro)

Infraestructura autoalojada (*Self-Hosted*) diseñada e implementada bajo estándares modernos de la industria SysAdmin y DevOps. Este entorno reproduce una arquitectura productiva de microservicios, segmentación de red L4/L7, terminación TLS centralizada, observabilidad *White-box* & *Black-box*, y políticas de acceso seguro Zero Trust.

---

## 📐 Topología y Arquitectura del Sistema

El tráfico de red sigue un modelo de proxy inverso con zonas de aislamiento mediante puentes de red virtuales Docker (*Bridge Networks*). Los servicios no exponen puertos arbitrarios al exterior de la VM anfitriona; el tráfico entrante L7 es filtrado y enrutado centralizadamente por el reverse proxy.

```
                    ┌────────────────────────────────────────────────────────┐
                    │                   Red Local / Clientes                  │
                    └───────────────────────────┬────────────────────────────┘
                                                │ HTTPS (TCP 443) / HTTP (TCP 80)
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ Host: Ubuntu Server                                                                        │
│ Firewall (Firewalld): 22 (SSH Clave ED25519), 80 (HTTP), 443 (HTTPS), 81 (NPM Admin)       │
│                                                                                            │
│   ┌────────────────────────────────────────────────────────────────────────────────────┐   │
│   │ Docker Network: proxy-net (Driver: bridge)                                         │   │
│   │                                                                                    │   │
│   │   ┌───────────────────────────────┐                                                │   │
│   │   │     Nginx Proxy Manager       │ ◄─── Terminación TLS (*.homelab.local)         │   │
│   │   │   (Reverse Proxy / Gateway)   │ ◄─── Enrutamiento de subdominios               │   │
│   │   └──────────────┬────────────────┘                                                │   │
│   │                  │                                                                 │   │
│   │         ┌────────┴────────────────────────┬────────────────────────┐               │   │
│   │         ▼ (HTTP Interno)                  ▼ (HTTP Interno)         ▼               │   │
│   │   ┌──────────────┐                 ┌──────────────┐         ┌──────────────┐       │   │
│   │   │ Grafana      │                 │ Prometheus   │         │ Uptime Kuma  │       │   │
│   │   │ (Port 3000)  │                 │ (Port 9090)  │         │ (Port 3001)  │       │   │
│   │   └──────┬───────┘                 └──────▲───────┘         └──────────────┘       │   │
│   │          │ Consultas PromQL               │ Métricas TSDB          ▲               │   │
│   │          └────────────────────────────────┘                        │ Healthchecks  │   │
│   │                                                                    │ & Heartbeats  │   │
│   └────────────────────────────────────────────────────────────────────┼───────────────┘   │
│                                                                        │                   │
│   ┌────────────────────────────────────────────────────────────────────┼───────────────┐   │
│   │ Docker Network: monitoring-internal (Driver: bridge)               │                   │   │
│   │                                                                    │                   │   │
│   │   ┌───────────────────────────────┐   ┌────────────────────────────┴──┐                │   │
│   │   │ Node Exporter                 │   │ cAdvisor                      │                │   │
│   │   │ (Métricas OS / Hardware)      │   │ (Métricas Docker Runtime)     │                │   │
│   │   │ Port 9100                     │   │ Port 8080                     │                │   │
│   │   └──────────────▲────────────────┘   └──────────────▲────────────────┘                │   │
│   │                  │                                   │                                 │   │
│   └──────────────────┼───────────────────────────────────┼─────────────────────────────────┘   │
│                      │                                   │                                     │
│               [ /proc, /sys ]                     [ docker.sock ]                              │
│                      │                                   │                                     │
│   ═══════════════════╧═══════════════════════════════════╧═════════════════════════════════   │
│   Núcleo del Sistema Operativo & Hardware del Servidor                                        │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Estructura del Repositorio e Inmutabilidad

Siguiendo el principio de **desacoplamiento de estado**, el sistema operativo base es completamente descartable. Todo el estado persistente y los manifiestos de despliegue residen de forma jerárquica en `/opt/homelab`:

```text
/opt/homelab/
├── compose/
│   ├── core/
│   │   ├── .env.example             # Variables de entorno modelo para Core
│   │   └── docker-compose.yml       # Nginx Proxy Manager + persistencia SQLite/Certs
│   └── monitoring/
│       ├── .env.example             # Variables de entorno modelo para Grafana/Prometheus
│       ├── docker-compose.yml       # Prometheus, Grafana, Node Exporter, cAdvisor, Uptime Kuma
│       └── prometheus/
│           └── prometheus.yml       # Configuración de scrape targets e intervalos
├── scripts/
│   └── setup-environment.sh         # Automatización de directorios, permisos UID/GID y proxy-net
└── data/                            # Volúmenes persistentes (Excluidos de Git, integrados a DRP)
    ├── npm/
    │   ├── data/
    │   └── letsencrypt/
    ├── prometheus/
    ├── grafana/
    └── uptime-kuma/
```

---

## 🚀 Componentes del Ecosistema

### 1. Núcleo de Enrutamiento y Proxy (Core)
* **Nginx Proxy Manager (NPM):** Punto de entrada L7 para todo el tráfico web del clúster. 
  * Manejo de certificados TLS/SSL comodín (*Wildcard*).
  * Cabeceras de seguridad HTTP, soporte nativo de WebSockets y mitigación de exploits comunes.
  * Resolución de nombres interna mediante red Docker `proxy-net`.

### 2. Pila de Observabilidad y Telemetría (Monitoring)
La monitorización se divide en dos paradigmas complementarios:

* **Observabilidad White-box (Métricas Internas):**
  * **Prometheus:** Servidor de base de datos de series temporales (TSDB) que recopila métricas cada 15s de los exportadores configurados.
  * **Node Exporter:** Monitoreo a nivel de kernel y host (utilización de CPU, saturación de RAM, I/O de disco, métricas de red `netstat`, carga de sistema).
  * **cAdvisor:** Monitoreo del daemon de Docker para extraer métricas de límites de recursos, consumo de memoria y uso de CPU por contenedor individual.
  * **Grafana:** Visualización centralizada mediante cuadros de mando interactivos aprovisionados automáticamente.
* **Observabilidad Black-box (Disponibilidad Externa):**
  * **Uptime Kuma:** Monitorización sintética de latencia, estados HTTP/HTTPS, expiración de certificados TLS y soporte de monitores tipo *Dead Man's Switch* (Push/Heartbeat) para tareas periódicas programadas.

---

## 🛡️ Seguridad y Perímetro (*Hardening*)

1. **Firewall Perimetral (Firewalld):**
   * Puertos expuestos estrictamente necesarios:
     * `22/tcp`: SSH limitado exclusivamente a autenticación por llave criptográfica pública (`ed25519`). Autenticación por contraseña deshabilitada.
     * `80/tcp` y `443/tcp`: Ingress de tráfico para el proxy inverso.
     * `81/tcp`: Panel de administración web de NPM (restringido a red local de gestión).
2. **Aislamiento de Contenedores:**
   * Los contenedores internos (Prometheus, cAdvisor, Node Exporter) no exponen puertos al exterior en el host (`0.0.0.0`), interactuando únicamente a través de la red privada `proxy-net` o la red local de monitorización.
3. **Control de Acceso y DNS Local:**
   * Resolución de dominios privados bajo la zona `.homelab.local` mediante mapeo estático y filtrado de cabeceras Host para mitigar ataques de *DNS Rebinding*.

---

## 📦 Puesta en Marcha (Deployment)

### Requisitos Previos
* Ubuntu Server (20.04 LTS o superior).
* Docker Engine (>= 24.0) y Docker Compose Plugin (>= 2.20).
* Llave SSH aprovisionada en el servidor.
* Permisos de superusuario (`sudo`).

---

### 1. Clonación del Repositorio en `/opt/homelab`
Por convención de administración de sistemas, el proyecto debe ubicarse en `/opt/homelab` para coincidir exactamente con los montajes de volúmenes persistentes y rutas declaradas en los manifiestos de Compose.

```bash
# 1. Asignar propiedad a tu usuario sobre /opt (ejecutar una sola vez)
sudo chown -R $USER:$USER /opt

# 2. Clonar el repositorio directamente en /opt/homelab
git clone https://github.com/GonzaloGirotti/homelab-infraestructura.git /opt/homelab

# 3. Ingresar al directorio raíz del proyecto
cd /opt/homelab
```

---

### 2. Inicialización de Permisos y Red Docker
Ejecutar el script de aprovisionamiento para crear los directorios persistentes en `/opt/homelab/data`, asignar los identificadores de usuario requeridos (`UID 65534` para Prometheus y `UID 472` para Grafana) y garantizar la existencia de la red Docker externa `proxy-net`:

```bash
chmod +x scripts/setup-environment.sh
./scripts/setup-environment.sh
```

---

### 3. Configuración de Variables de Entorno
Generar los archivos `.env` a partir de las plantillas provistas:

```bash
# Configurar Core
cp compose/core/.env.example compose/core/.env

# Configurar Monitoring
cp compose/monitoring/.env.example compose/monitoring/.env
```

---

### 4. Despliegue de Servicios con Docker Compose

#### A. Levantar la Capa Core (Nginx Proxy Manager)
```bash
cd /opt/homelab/compose/core
docker compose up -d
```

#### B. Levantar la Pila de Monitorización (Observabilidad)
```bash
cd /opt/homelab/compose/monitoring
docker compose up -d
```

Validar el estado de los servicios:
```bash
docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"
```

---

## 🌐 Configuración en Nginx Proxy Manager (NPM)

Una vez levantado el stack, acceder a la interfaz gráfica de administración en:
`TUIPLOCAL:81`

Credenciales iniciales por defecto:
* **Email:** `admin@example.com`
* **Password:** `changeme`
*(El sistema solicitará actualizar nombre, correo y contraseña tras el primer inicio de sesión).*

---

### 1. Creación del Certificado TLS Wildcard (`*.homelab.local`)

Para asegurar el clúster bajo HTTPS con terminación TLS única para todos los subdominios:

#### Opción A: Certificado Comodín Autofirmado / CA Local (Entornos Offline o Privados)
Si utilizas tu propia Autoridad Certificadora (CA) o certificados generados localmente (ej. OpenSSL / mkcert):
1. Ir a **SSL Certificates** > **Add SSL Certificate** > **Custom**.
2. **Name:** `Wildcard Homelab (*.homelab.local)`.
3. Subir la **Certificate Key** (`.key`) y el **Certificate** (`.crt` o `.pem` con la cadena completa).
4. Hacer clic en **Save**.

#### Opción B: Let's Encrypt con DNS Challenge (Dominio Público / Split-DNS)
Si gestionas un dominio público a través de un proveedor DNS (Cloudflare, DuckDNS, etc.):
1. Ir a **SSL Certificates** > **Add SSL Certificate** > **Let's Encrypt**.
2. **Domain Names:** `*.tudominio.com` y `tudominio.com`.
3. Marcar **Use a DNS Challenge**.
4. Seleccionar el **DNS Provider** correspondiente (ej. Cloudflare) y completar el API Token.
5. Aceptar los términos de servicio y guardar.

---

### 2. Creación de Proxy Hosts con Aislamiento L7

Gracias a la red Docker compartida `proxy-net`, Nginx Proxy Manager se comunica con los contenedores por su nombre interno de servicio en texto plano (HTTP), aplicando la terminación TLS de cara a los clientes.

Ir a **Hosts** > **Proxy Hosts** > **Add Proxy Host** y configurar cada servicio:

#### A. Grafana
* **Pestaña Details:**
  * **Domain Names:** `grafana.homelab.local`
  * **Scheme:** `http`
  * **Forward Hostname / IP:** `grafana`
  * **Forward Port:** `3000`
  * Activar: **Cache Assets**, **Block Common Exploits**, **Websockets Support**.
* **Pestaña SSL:**
  * **SSL Certificate:** Seleccionar `*.homelab.local`.
  * Activar: **Force SSL**, **HTTP/2 Support**, **HSTS Enabled**.

#### B. Prometheus
* **Pestaña Details:**
  * **Domain Names:** `prometheus.homelab.local`
  * **Scheme:** `http`
  * **Forward Hostname / IP:** `prometheus`
  * **Forward Port:** `9090`
  * Activar: **Block Common Exploits**.
* **Pestaña SSL:**
  * **SSL Certificate:** Seleccionar `*.homelab.local`.
  * Activar: **Force SSL**, **HTTP/2 Support**.

#### C. Uptime Kuma
* **Pestaña Details:**
  * **Domain Names:** `kuma.homelab.local`
  * **Scheme:** `http`
  * **Forward Hostname / IP:** `uptime-kuma`
  * **Forward Port:** `3001`
  * Activar: **Block Common Exploits**, **Websockets Support** *(Indispensable para la reactividad en tiempo real de Uptime Kuma)*.
* **Pestaña SSL:**
  * **SSL Certificate:** Seleccionar `*.homelab.local`.
  * Activar: **Force SSL**, **HTTP/2 Support**.

---

### 3. Resolución DNS Local en Clientes
En las máquinas cliente desde las que se accede al Homelab, mapear los subdominios hacia la IP del servidor (`TUIPLOCAL`) en el archivo `hosts` o mediante el servidor DNS local (ej. Pi-hole / AdGuard Home):

```text
TUIPLOCAL  grafana.homelab.local prometheus.homelab.local kuma.homelab.local
```

---

## 📊 Dashboards y Métricas Clave

| Servicio                | Puerto Interno      | Endpoint / Uso                                 |
| ----------------------- | ------------------- | ---------------------------------------------- |
| **Nginx Proxy Manager** | `81` / `80` / `443` | Gateway de entrada y gestión SSL               |
| **Grafana**             | `3000`              | Visualización (`dashboards/host-metrics.json`) |
| **Prometheus**          | `9090`              | Motor de recolección de métricas TSDB          |
| **Uptime Kuma**         | `3001`              | Monitor de SLA, disponibilidad y certificados  |
| **Node Exporter**       | `9100`              | Recolector de métricas de host (Kernel/OS)     |
| **cAdvisor**            | `8080`              | Recolector de rendimiento de contenedores      |

---
