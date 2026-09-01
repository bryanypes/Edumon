# syntax=docker/dockerfile:1
#
# Todo en un contenedor: nginx (frontend, único puerto expuesto), backend
# Node y MongoDB local, orquestados con supervisord.
#
# Build context: raíz "Proyecto Edumon" (contiene "Backend Edumon/" y
# "Edumon-Repositorio-nuevo/").

FROM node:22-bookworm-slim AS frontend-build
WORKDIR /frontend

COPY ["Edumon-Repositorio-nuevo/package.json", "Edumon-Repositorio-nuevo/package-lock.json", "./"]
# Lockfile generado en Windows, npm/cli#4828 con el binario de Rollup en Linux
RUN rm -f package-lock.json && npm install

COPY Edumon-Repositorio-nuevo/ ./

ARG VITE_FIREBASE_VAPID_KEY=""
ENV VITE_API_URL=/api
ENV VITE_FIREBASE_VAPID_KEY=$VITE_FIREBASE_VAPID_KEY

RUN npm run build

FROM node:22-bookworm-slim AS backend-deps
WORKDIR /backend

COPY ["Backend Edumon/package.json", "Backend Edumon/package-lock.json", "./"]
RUN npm ci --omit=dev

FROM node:22-bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl gnupg ca-certificates nginx supervisor \
    && curl -fsSL https://pgp.mongodb.com/server-7.0.asc \
       | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" \
       > /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends mongodb-org-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db

COPY --from=backend-deps /backend/node_modules /backend/node_modules
COPY ["Backend Edumon/package.json", "/backend/package.json"]
COPY ["Backend Edumon/src", "/backend/src"]
RUN chown -R node:node /backend

RUN rm -f /etc/nginx/sites-enabled/default
COPY docker/nginx-edumon.conf /etc/nginx/sites-enabled/edumon.conf
COPY --from=frontend-build /frontend/dist /usr/share/nginx/html

COPY docker/supervisord.conf /etc/supervisor/conf.d/edumon.conf

ENV NODE_ENV=production
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1/health || exit 1

CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/edumon.conf"]
