# Storage: bind mounts and named volumes

## The problem

A container’s writable layer **dies with the container**. `docker rm` / `docker compose down` → MySQL data in `/var/lib/mysql` is gone. So is anything you wrote under `/app` that was not in the image.

The image is the template. The writable layer is scratch paper. Data you care about must live **outside** that layer: a **mount**.

```text
IMAGE (read-only layers)
  └── writable layer     ←  gone when the container is removed
        └── mount        ←  lives on the host (you or Docker)
```

Same idea as notes on images: “Writes die with the instance unless stored elsewhere.” This is the elsewhere.

## Two mounts that matter

Both map a **host-side store** onto a **path inside the container**. The process just sees a directory.

| | Bind mount | Named volume |
|---|---|---|
| Source | A path **you** pick on the host (`./mysql/init.sql`, `./flask`) | A volume **Docker** names and stores (`mysql_data`) |
| Who manages the files | You (normal folders/files) | Docker (location under Docker’s data dir) |
| Typical use | Config, source code, init scripts | Database files, anything that should outlive the container |
| Host-path in the YAML? | Yes (`./…` or an absolute path) | No — just a name |

```text
bind:   D:\project\mysql\init.sql  →  /docker-entrypoint-initdb.d/init.sql
named:  volume "mysql_data"        →  /var/lib/mysql
```

`-v` / `--mount` / Compose `volumes:` are the same idea. Short `-v` form is what you will see most:

```text
-v source:target
```

If `source` looks like a path (`.` `/` `C:`), it is a **bind**. If it is a single name (`mysql_data`), it is a **named volume**.

## Bind mount

You point at a file or directory that already lives in the project (or anywhere on the host). The container reads/writes **those** bytes. Edit on the host → the process sees it (and the other way around).

`projects/04_docker_compose` already does this for MySQL’s first-run SQL:

```yaml
volumes:
  - ./MySQL/init.sql:/docker-entrypoint-initdb.d/init.sql
```

That is not “MySQL’s database.” It is one file, bind-mounted to the official image’s init folder. First start with an **empty** data dir → mysqld runs scripts in `/docker-entrypoint-initdb.d/`.

Dev pattern: bind the app source so you do not rebuild on every edit:

```yaml
volumes:
  - ./flask:/app
```

The image still has a `COPY` of the code. The bind **covers** `/app` with the host folder. The process sees the laptop’s files.

Costs: host path must exist (or Docker creates a directory, which surprises people who meant a file). On Docker Desktop, binds go through the Linux VM — fine for learning; not how you persist production DBs. UID/GID inside the container may not match the host.

## Named volume

Docker creates a volume object. You only choose the **name** and the **path in the container**. You do not choose the host folder.

```yaml
services:
  mysql_container:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql   # named — persist the actual database

volumes:
  mysql_data:                       # declare the name at the top level
```

```bash
docker run -d -v mysql_data:/var/lib/mysql mysql:8.0
```

If `mysql_data` does not exist, Docker **creates** it. `docker volume ls` / `docker volume inspect mysql_data` show it. On Docker Desktop the real files sit inside the VM, not as a folder next to your repo.

`docker compose down` **keeps** named volumes. `docker compose down -v` deletes them. That is the difference between “stop the stack” and “wipe the database.”

Empty named volume + first start: Docker can copy the image’s contents at that path into the volume (MySQL’s default datadir). After that, the volume wins. Changing `init.sql` later does **not** re-run init if `mysql_data` already has a database.

## Side by side in one service

```yaml
services:
  mysql_container:
    image: mysql:8.0
    volumes:
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql  # bind: recipe
      - mysql_data:/var/lib/mysql                              # named: data

volumes:
  mysql_data:
```

Bind = files you edit in git. Named = files the process generates and you want after `down`.

## Anonymous volumes

`-v /var/lib/mysql` with **no** source. Docker still creates a volume, but with a random ID. Easy to leak (`docker volume ls` fills up). Prefer a **name**.

## Mental model

```text
writable layer     scratch — do not keep anything you need
bind mount         my folder/file on the host, live
named volume       Docker-owned bag of files, survives compose down
```

Ask: “Do I want to open this in the editor as a project file?” → bind. “Is this the database (or uploads) that must survive recreate?” → named volume.

## Misconceptions

- `COPY` in a Dockerfile is not a volume. It is frozen into the image at **build** time.
- Bind-mounting `init.sql` does not persist MySQL data. Persist `/var/lib/mysql` (named volume).
- Named volume ≠ bind to a cute folder name. `mysql_data:/var/lib/mysql` is **not** `./mysql_data` unless you write `./mysql_data`.
- `compose down` does not delete named volumes; `down -v` does.
- Two containers can mount the **same** named volume. That does not make concurrent writers safe (MySQL still wants one server).
- A volume does not back itself up. It only outlives the container.
