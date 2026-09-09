# Edumon

Plataforma de gestión escolar. Este repo une el frontend y el backend como submódulos y agrega el Dockerfile/compose para levantar todo en un solo contenedor.

## Estructura

- `Backend/` — API REST (Node/Express + MongoDB). [Repo](https://github.com/BryanDYepes/Backend-Edumon)
- `Frontend/` — Frontend (Vite + React). [Repo](https://github.com/vXro1/Edumon-Repositorio-nuevo)
- `Dockerfile` / `docker-compose.yml` / `docker/` — imagen única: nginx (frontend) + backend + MongoDB local. Los archivos subidos (fotos, adjuntos, APK) se guardan en el volumen `uploads-data`.

## Clonar

```bash
git clone --recurse-submodules https://github.com/bryanypes/Edumon.git
```

Si ya lo clonaste sin `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Levantar todo con Docker

```bash
cp "Backend/.env.example" "Backend/.env"
# completar JWT_SECRET, SMTP_* (correo) y FIREBASE_* (push) en ese .env

docker compose up --build
```

Abrir `http://localhost:8095`. El backend y MongoDB no se exponen fuera del contenedor.

Edumon corre como servicio Docker independiente, separado del stack de NOVA_FT/PQRS_SYS
(no es una subruta de `nova.uniautonoma.edu.co`). En el servidor se publica en su propio
puerto (`8095` por defecto, configurable con la variable de entorno `EDUMON_PORT`) y se
expone por su propio dominio (`edumon.uniautonoma.edu.co`) vía un vhost del nginx del
sistema — ver `docker/edumon.nginx-site.conf.example`.

## Actualizar los submódulos

```bash
git submodule update --remote
git add Backend Frontend
git commit -m "actualiza submódulos"
```
