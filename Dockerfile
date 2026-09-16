# syntax=docker/dockerfile:1
#
# Todo en un contenedor: nginx (frontend, único puerto expuesto), backend
# Node y MongoDB local, orquestados con supervisord.
#
# Build context: raíz del repo (contiene "Backend/" y "Frontend/").

FROM node:22-bookworm-slim AS frontend-build
WORKDIR /frontend

COPY ["Frontend/package.json", "Frontend/package-lock.json", "./"]
# Lockfile generado en Windows, npm/cli#4828 con el binario de Rollup en Linux
RUN rm -f package-lock.json && npm install

COPY Frontend/ ./

ARG VITE_FIREBASE_VAPID_KEY=""
ENV VITE_API_URL=/api
ENV VITE_FIREBASE_VAPID_KEY=$VITE_FIREBASE_VAPID_KEY

RUN npm run build

FROM node:22-bookworm-slim AS backend-deps
WORKDIR /backend

# El binario precompilado de sharp exige CPU x86-64-v2 (SSE4.2) y crashea con
# "Unsupported CPU" en el servidor (hardware antiguo, sin ese set de
# instrucciones) — se compila contra el libvips del sistema (paquete Debian,
# sin ese requisito) en lugar de usar el binario que trae sharp.
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 make g++ pkg-config libvips-dev \
    && rm -rf /var/lib/apt/lists/*

COPY ["Backend/package.json", "Backend/package-lock.json", "./"]
# --omit=optional excluye el binario precompilado de sharp (optionalDependency
# del propio paquete): sin él, su install script compila contra el libvips
# del sistema en vez de usar el prebuilt que exige CPU v2.
ENV SHARP_FORCE_GLOBAL_LIBVIPS=1
RUN npm ci --omit=dev --omit=optional

FROM node:22-bookworm-slim AS runtime

# MongoDB 4.4: la 5.0+ requiere CPU con AVX y crashea con SIGILL en servidores
# sin ese set de instrucciones (VPS/hardware antiguo). 4.4 no tiene ese requisito.
# Sin paquete "bookworm" oficial para 4.4, se usa el repo "buster" (compatible).
# mongodb-org-server 4.4 enlaza contra libssl1.1, que bookworm ya no trae
# (solo libssl3) — se instala desde el repo de seguridad de bullseye.
# MongoDB 4.4: la 5.0+ requiere CPU con AVX y crashea con SIGILL en servidores
# sin ese set de instrucciones (VPS/hardware antiguo). 4.4 no tiene ese requisito.
# Sin paquete "bookworm" oficial para 4.4, se usa el repo "buster" (compatible).
# mongodb-org-server 4.4 enlaza contra libssl1.1, que bookworm ya no trae
# (solo libssl3). Los repos "-security" de Debian ya EOL (bullseye/buster) no
# tienen espejo fiable en archive.debian.org, así que se baja el .deb directo
# del archivo permanente de Ubuntu (old-releases.ubuntu.com) y se instala con dpkg.
# libvips-dev también aquí: sharp quedó enlazado dinámicamente contra él en el
# stage anterior, la lib debe estar presente en runtime para poder cargarla.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl gnupg ca-certificates nginx supervisor libvips-dev \
    && DEB_BASE="http://old-releases.ubuntu.com/ubuntu/pool/main/o/openssl" \
    && DEB_FILE=$(curl -fsSL "$DEB_BASE/" | grep -o 'libssl1\.1_[^"]*_amd64\.deb' | sort -V | tail -1) \
    && curl -fsSL -o /tmp/libssl1.1.deb "$DEB_BASE/$DEB_FILE" \
    && dpkg -i /tmp/libssl1.1.deb \
    && rm -f /tmp/libssl1.1.deb \
    && curl -fsSL https://pgp.mongodb.com/server-4.4.asc \
       | gpg --dearmor -o /usr/share/keyrings/mongodb-server-4.4.gpg \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" \
       > /etc/apt/sources.list.d/mongodb-org-4.4.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mongodb-org-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db

# almacenamiento local de archivos subidos (fotos, adjuntos, APK).
# Debe montarse un volumen persistente en /data/uploads.
ENV UPLOAD_DIR=/data/uploads
RUN mkdir -p /data/uploads && chown -R node:node /data/uploads

COPY --from=backend-deps /backend/node_modules /backend/node_modules
COPY ["Backend/package.json", "/backend/package.json"]
COPY ["Backend/src", "/backend/src"]
RUN chown -R node:node /backend

RUN rm -f /etc/nginx/sites-enabled/default
COPY docker/nginx-edumon.conf /etc/nginx/sites-enabled/edumon.conf
COPY --from=frontend-build /frontend/dist /usr/share/nginx/html

COPY docker/supervisord.conf /etc/supervisor/conf.d/edumon.conf

ENV NODE_ENV=production
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1/health/backend || exit 1

CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/edumon.conf"]
