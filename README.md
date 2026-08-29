# Docker Tutorial

A personal learning repository for Docker — notes, mental models, and hands-on code examples in one place.

## What's here

| Path | Description |
| --- | --- |
| [`notes/`](notes/) | Written explanations of Docker concepts |
| [`projects/`](projects/) | Runnable examples, one folder per exercise |
| [`.cursor/`](.cursor/) | [Cursor Cloud Agent](https://cursor.com/docs/cloud-agent/setup) environment config |

## Notes

| File | Topic |
| --- | --- |
| [01-what-is-docker.md](notes/01-what-is-docker.md) | What Docker is and why it exists |
| [02-docker-vs-virtual-machines.md](notes/02-docker-vs-virtual-machines.md) | Containers vs virtual machines |
| [03-images-and-containers.md](notes/03-images-and-containers.md) | Images, containers, lifecycle, and writing a Dockerfile |

## Projects

### 01 — First app

A minimal Python script packaged in a container.

```bash
cd projects/01_first_app
docker build -t docker-tutorial-first-app .
docker run --rm docker-tutorial-first-app
```

Expected output:

```text
This will run on docker
```

The [`Dockerfile`](projects/01_first_app/Dockerfile) uses `python:3.8-slim`, copies the app into `/app`, and runs `python app.py`.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/install/) (or Docker Desktop)

Verify Docker is available:

```bash
docker --version
docker info
```

## Cloud Agent development

This repo includes a Cursor Cloud Agent environment (`.cursor/environment.json`) with Docker-in-Docker support so agents can build and run containers inside the VM.

On each agent boot, the environment runs `.cursor/start.sh` to start the Docker daemon, then `.cursor/install.sh` (during setup) warms the `python:3.8-slim` base image and smoke-tests the first project.

## License

[MIT](LICENSE)
