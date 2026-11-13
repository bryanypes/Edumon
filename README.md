# Edumon

Plataforma de gestión escolar que conecta instituciones, docentes y familias. Este repositorio une la API y la web como submódulos y contiene el despliegue en Docker.

## Repositorios

| Carpeta | Contenido |
| --- | --- |
| `Backend/` | API REST (Node.js, Express, MongoDB). [Repositorio](https://github.com/BryanDYepes/Backend-Edumon) |
| `Frontend/` | Aplicación web (React, Vite). [Repositorio](https://github.com/vXro1/EDUMON-WEB-) |
| `Dockerfile`, `docker-compose.yml`, `docker/` | Imagen única con nginx (web), backend y MongoDB |

La app Android está en un repositorio aparte (`Edumonmovil_flutter`).

## Requisitos

- Git
- Docker con Docker Compose (despliegue) o Node.js 22 y MongoDB (desarrollo de cada submódulo)

## Instalación

```bash
git clone --recurse-submodules https://github.com/bryanypes/Edumon.git
cd Edumon
cp Backend/.env.example Backend/.env   # completar JWT_SECRET y, si aplica, SMTP_* y FIREBASE_*
docker compose up --build
```

La aplicación queda en `http://localhost:8095`; el backend y MongoDB no se exponen fuera del contenedor. Para desarrollar cada parte por separado, ver el README de `Backend/` y `Frontend/`.

Si se clonó sin `--recurse-submodules`: `git submodule update --init --recursive`.

## Variables de entorno

- `Backend/.env`: ver `Backend/.env.example`.
- `EDUMON_PORT`: puerto publicado por `docker compose` (por defecto `8095`).

## Despliegue

En el servidor, Edumon corre como servicio Docker propio en `EDUMON_PORT` y se publica en `edumon.uniautonoma.edu.co` mediante un vhost del nginx del sistema (`docker/edumon.nginx-site.conf.example`).

## Actualizar los submódulos

```bash
git submodule update --remote
git add Backend Frontend
git commit -m "chore: actualizar submódulos"
```
