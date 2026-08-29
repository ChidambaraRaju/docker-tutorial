# Images and Containers

## Relationship

| | Image | Container |
|---|---|---|
| What | Immutable template (filesystem + start metadata) | Instance of an image |
| Runs? | Never | Running or stopped |
| Mutable? | No — you build a new image | Yes — private writable layer |
| How many | One template | Zero to many |
| What you ship | This | You run these; you don’t ship them |

```text
IMAGE (read-only)
   ├── container A
   ├── container B
   └── container C
```

One image, many containers. Edits in a container never go back into the image.

Analogy that is enough: class vs object, or recipe vs one cooking. Creating a container does not consume the image.

## Image

Read-only artifact on disk or in a registry. Data, not a process.

Contains: filesystem snapshot, default command / env / ports / workdir, stacked **layers**.

Layers are diffs stacked on each other (base OS user-space → runtime → app). Lower layers are shared across images/containers. Changing the app usually only changes the top layer. Layers are read-only.

Named as `name:tag` (e.g. `python:3.12`). Tag is a human label; the real identity is an ID/hash.

## Container

Created from an image:

1. Reference the image’s read-only layers
2. Add a **writable layer** on top (copy-on-write)
3. Apply isolation (namespaces, cgroups)
4. Optionally start the process

Writes live in that writable layer. Delete the container → writes gone. Image unchanged.

**Stopped ≠ deleted.** Process ended; container and its files still exist until you remove it. You can start the same container again (same writes) or create a **new** one from the image (clean writable layer).

Writable layer is **ephemeral**. Data you care about must live elsewhere (volumes — later).

## Lifecycle

```text
image → create → CREATED → start → RUNNING → stop/exit → STOPPED
                                              start ↗
STOPPED → remove → GONE  (image remains)
```

| | Meaning |
|---|---|
| Create | Object + writable layer exist; image is referenced, not fully copied |
| Start | Process runs |
| Stop / exit | Process ends; files still there |
| Start again | Same instance, same writes |
| Remove | Instance and writes gone; image stays |

## Where images come from

**Build** locally, or **pull** from a registry (Docker Hub or private). Host keeps a local image cache. You push/pull **images**, not containers.

## Mental model

Package = image. Instance = container. Writes die with the instance unless stored elsewhere.

## Writing a Dockerfile

A **Dockerfile** is that recipe: a text file of instructions. `docker build` reads it and produces an **image**. Each instruction usually becomes a **layer**.

For a Python app, four steps are enough to start:

```text
1. FROM   →  take a Python base image
2. COPY   →  put my code in the image
3. RUN    →  install libraries
4. CMD    →  say how to run the app
```

`WORKDIR` is not one of those four. Set it anyway so copy/install/run happen in a known folder (often `/app`), not `/`.

### 1. Pull a Python base image — `FROM`

```dockerfile
FROM python:3.13
```

This is the first layer: OS user-space + a Python runtime. You do not write `docker pull` in the file. `FROM` **names** the image. On build, Docker uses a local copy if you already have that tag, otherwise it **pulls** it from a registry (Docker Hub by default).

Pin a tag (`3.13`), not `latest`. The tag is the Python version you want inside the image. `-slim` variants are smaller (less OS user-space). Still no guest kernel — same as any other image.

### 2. Copy my code — `COPY`

```dockerfile
WORKDIR /app
COPY . .
```

`COPY <from-host> <in-image>` copies from the **build context** (usually the directory you pass to `docker build`) into the image filesystem.

`.` → `.` with `WORKDIR /app` means: everything in that context folder → `/app` in the image. That includes `app.py`, `requirements.txt`, and the rest.

What you copy becomes part of the **image**, not a live bind to your laptop. Later edits on the host need a **new build**.

Do not copy junk you do not need (`.git`, venv, `__pycache__`). A `.dockerignore` file lists those, same idea as `.gitignore`.

### 3. Install libraries — `RUN`

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
```

`RUN` executes **at build time**. The result is baked into the next image layer. `pip` here is the pip **inside** the image, not the one on your machine.

`--no-cache-dir` keeps pip’s download cache out of the image so the layer stays smaller.

This is why you ship an image instead of “source + hope they have the packages”: the libraries are already in the filesystem snapshot.

### 4. Run my app — `CMD`

```dockerfile
CMD ["python", "app.py"]
```

`CMD` does **not** run during `docker build`. It is metadata: the default process when someone **starts a container** from this image (`docker run`).

Exec form (`["python", "app.py"]`) is a real argv list. Prefer it over `CMD python app.py` (shell form).

One `CMD` per image. If you write several, only the last one counts. `docker run … some-command` can override it for that container.

### Put together

```dockerfile
FROM python:3.13
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
CMD ["python", "app.py"]
```

Build, then run:

```text
docker build -t myapp .
docker run --rm myapp
```

`-t myapp` names the image. `.` is the build context (and where Docker looks for `Dockerfile` by default). `--rm` deletes the container when the process exits.

### Layer order (why copy-then-install is naive)

Every instruction is a layer. If a layer’s inputs did not change, Docker **reuses** it.

`COPY . .` then `RUN pip …` means **any** code edit invalidates the install layer. You wait for pip again even if `requirements.txt` did not change.

Better split of steps 2 and 3:

```dockerfile
FROM python:3.13
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Deps change rarely → install layer stays cached. App code changes often → only the last `COPY` and `CMD` rebuild.

### Mental model

```text
FROM     start from someone else’s image
COPY     add my files (build time)
RUN      change the filesystem (build time)
CMD      default process (run time)
```

The Dockerfile is the recipe. The image is the cooked package. The container is one serving.

## Misconceptions

- Image is not the running app.
- Installing something in a container does not change the image.
- Stopped is not deleted.
- Containers do not each store a full copy of the image; layers are shared.
- Snapshotting a container into an image (`commit`) is not how you should build images — change the Dockerfile and rebuild.
- `FROM` is not “install Python on my laptop.” It is the base **of the image**.
- `COPY` is not a volume. The files are frozen into the image at build time.
- `RUN pip install` is not “install on the host.” It only changes the image being built.
- `CMD` is not a build step. Nothing starts until `docker run` (or equivalent).
