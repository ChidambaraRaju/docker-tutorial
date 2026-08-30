# Docker Compose

## The problem

Two containers means two long `docker run` lines: image or build, names, network, env, ports, restart, wait-for-db. Easy to forget `--network` and then Flask cannot resolve `mysql_container`.

Compose is that whole stack in **one YAML**. You describe services; Docker creates a network and starts them together.

```text
docker run ... mysql
docker run ... --network ... flask     →   docker compose up
```

Practice file in this repo: `Docker-compose.yml` (Flask + MySQL). Same idea as `projects/03_docker_app_network`, without a MySQL Dockerfile.

## What Compose is

A tool that reads a Compose file (`compose.yaml` / `docker-compose.yml`) and:

1. Builds or pulls images
2. Creates a **project network** (user-defined bridge)
3. Creates and starts **containers** (one or more per service)
4. Attaches them to that network

It is not a new kind of container. Same Engine, same images. The file is the recipe for **how they run together**.

`docker compose` (V2, plugin) is the current command. `docker-compose` (hyphen) is the old Python CLI. Same idea; use the space form.

The top-level `version: '3.1'` line is **ignored** by Compose V2. Harmless leftover.

## Services

Under `services:`, each key is a **service name**. That name is the **DNS hostname** on the project network.

Flask in `app.py` uses `host='mysql_container'` because the YAML key is `mysql_container`. Not because of magic in Python.

| Key | Meaning |
|---|---|
| `image:` | Pull this image (Docker Hub unless you say otherwise). **No Dockerfile.** |
| `build:` | Build from a local context (folder with a Dockerfile). |
| `ports:` | Publish to the host (`HOST:CONTAINER`). Same as `-p`. |
| `environment:` | Env vars in the container (what `ENV` / `-e` did). |
| `depends_on:` | Start order. With `condition: service_healthy`, wait until the healthcheck passes. |
| `restart:` | Restart policy (`always` ≈ `--restart always`). |
| `container_name:` | Pin the container name. Optional — default is `{project}_{service}_1`. |
| `volumes:` | Map host paths or named volumes into the container (storage — next). |

You mix `image:` and `build:` in one file. That is the point of `04_docker_compose`.

## `image:` vs `build:`

```text
MySQL:  image: mysql:8.0     →  pull Hub, run as-is
Flask:  build: Flask/.       →  docker build that folder, then run
```

Project 03 needed `mysql/Dockerfile` (`FROM mysql:8.0`, `ENV`, `COPY init.sql`). Compose can do that **in YAML**: `image`, `environment`, and a bind of `init.sql` into `/docker-entrypoint-initdb.d/`. Official images are meant to be configured at run time. Your app still needs a Dockerfile because you wrote the app.

`build:` is a **context path**. Compose runs `docker build` there. `image:` never looks for a Dockerfile.

## Default network

Compose creates `{project}_default` and attaches every service. You do not `docker network create`.

```text
flask_container  →  mysql_container:3306
                    (service name + container port, not 3307)
```

`3307:3306` is only for a client **on the host**. Flask must use **3306** (what mysqld listens on inside the MySQL container).

Two Compose projects → two networks. Services in one file do not see services in another unless you declare a shared network.

## Start order

`depends_on: mysql_container` only waits for the **container** to exist, not for MySQL to accept connections — unless you add a healthcheck and `condition: service_healthy`.

That is why the YAML pings with `mysqladmin` and Flask has `condition: service_healthy`. Otherwise Flask can boot, connect, and crash while MySQL is still initializing.

## Commands

Run from the directory that contains the Compose file:

```bash
docker compose up            # create network, build/pull, start, logs in the foreground
docker compose up -d --build # detached; rebuild images that use build:
docker compose ps
docker compose logs -f flask_container
docker compose down          # stop and remove containers + the project network
```

`down` does not delete images. Named volumes stay unless you pass `-v` (destructive; next notes).

## Mental model

```text
Compose file  =  stack recipe
service       =  role (app, db) + how to get its image
service name  =  hostname on the project network
image:        =  pull
build:        =  local Dockerfile
docker compose up  =  network + all containers
```

One file. One network. Talk by service name and container port.

## Misconceptions

- Compose is not Kubernetes and not a replacement for the Engine. It **orchestrates** `docker build` / `docker run` for a single project.
- `image:` does not run a Dockerfile in that service’s folder. No Dockerfile is the lesson for MySQL here.
- `depends_on` without a health condition is not “database is ready.”
- Publishing `3307` does not change the port Flask should use (`3306` on `mysql_container`).
- `localhost` in Flask is still the Flask container, not MySQL and not the host.
- `container_name` is not what other services look up. They look up the **service key**. Pinning the name just makes `docker ps` prettier (and forbids scaling that service).
