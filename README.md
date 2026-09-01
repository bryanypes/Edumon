# Edumon

Plataforma de gestión escolar. Este repo une el frontend y el backend como submódulos y agrega el Dockerfile/compose para levantar todo en un solo contenedor.

## Estructura

- `Backend Edumon/` — API REST (Node/Express + MongoDB). [Repo](https://github.com/BryanDYepes/Backend-Edumon)
- `Edumon-Repositorio-nuevo/` — Frontend (Vite + React). [Repo](https://github.com/vXro1/Edumon-Repositorio-nuevo)
- `Dockerfile` / `docker-compose.yml` / `docker/` — imagen única: nginx (frontend) + backend + MongoDB local.

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
cp "Backend Edumon/.env.example" "Backend Edumon/.env"
# completar SMTP_*, JWT_SECRET, Cloudinary, Firebase, Twilio en ese .env

docker compose up --build
```

Abrir `http://localhost:8080`. El backend y MongoDB no se exponen fuera del contenedor.

## Actualizar los submódulos

```bash
git submodule update --remote
git add "Backend Edumon" "Edumon-Repositorio-nuevo"
git commit -m "actualiza submódulos"
```
