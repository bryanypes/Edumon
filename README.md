# Edumon

Plataforma de gestión escolar que conecta instituciones, docentes y familias. Este repositorio une la API y la web como submódulos y contiene el despliegue en Docker.

| Dato | Valor |
| --- | --- |
| Programa | EDUMON — despliegue conjunto del programa web (registro A) |
| Versión | 1.0.0 |
| Commit | $Format:%H$ |
| Fecha del commit | $Format:%cs$ |
| Autores | Bryan David Yepes Ordóñez y Karen Verónica Mancilla Solarte |

En una copia obtenida con `git archive` el commit y la fecha aparecen completos; en el repositorio se ven como marcadores.

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

En el servidor actual, el proxy HTTPS es el Caddy de SIAC; se usa el override de
producción descrito más abajo.

## Actualizar los submódulos

```bash
git submodule update --remote
git add Backend Frontend
git commit -m "chore: actualizar submódulos"
```

## Despliegue automático

Un push a `main` despliega los commits de Backend y Frontend fijados en Edumon;
los cambios directos en esos repositorios no activan el despliegue hasta actualizar
sus referencias aquí. El workflow usa un runner Linux autohospedado con la
etiqueta `edumon-production`, Docker y Docker Compose. Instalarlo como servicio
siguiendo la configuración de runners del repositorio en GitHub. El runner debe
tener acceso a Docker y lectura de `/opt/edumon/Edumon/Backend/.env`; no subir
ese archivo ni copiar sus credenciales al repositorio. Registrar el runner desde
Settings → Actions → Runners con esa etiqueta y mantenerlo en línea como servicio.

El despliegue usa el proyecto Compose `edumon`, los volúmenes existentes
`edumon_mongo-data` y `edumon_uploads_migrados` y la red externa
`siac-prod_default`. Comprueba que existan antes de configurar el runner. Caddy
se administra por separado; el workflow no modifica su configuración ni SIAC.
El puerto de comprobación es `8095`. Cambios en la ruta del `.env`, los nombres
de recursos o el puerto requieren actualizar el workflow o el override.
Antes del primer despliegue, comparar los commits de los submódulos y cualquier
cambio local del servidor con los del repositorio: el workflow construye desde
el commit de `main`, no desde el directorio de trabajo existente del servidor.

El acceso a Docker del runner equivale a privilegios elevados sobre el servidor
compartido: limitar quién puede modificar workflows o hacer push a `main` y no
ejecutar código de pull requests no confiables en ese runner. Las comprobaciones
del workflow verifican arranque y conexión a MongoDB, pero no sustituyen backups,
pruebas funcionales ni un plan de recuperación. El esquema actual contiene un
índice TTL que puede eliminar usuarios al vencer sesiones y recrearse al arrancar;
el despliegue automático no corrige ni evita ese riesgo.
