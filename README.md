# Docker Tutorial

This repository is my learning journey with Docker.

I use it to document notes, mental models, and the code I write while practicing. The goal is a single place I can come back to later.

## Notes

| File | Topic |
|---|---|
| [01-what-is-docker.md](notes/01-what-is-docker.md) | What Docker is and why it exists |
| [02-docker-vs-virtual-machines.md](notes/02-docker-vs-virtual-machines.md) | Containers vs virtual machines |
| [03-images-and-containers.md](notes/03-images-and-containers.md) | Images, containers, and lifecycle |
| [04-port-mapping.md](notes/04-port-mapping.md) | Host ports vs container ports (`-p`) |
| [05-networks.md](notes/05-networks.md) | Docker networks, DNS, and isolation |
| [06-docker-compose.md](notes/06-docker-compose.md) | Compose files, services, `image` vs `build` |
| [07-storage.md](notes/07-storage.md) | Bind mounts and named volumes |

## Projects

Practice code under [`projects/`](projects/), in the same order as the notes.

| Folder | What it practices |
|---|---|
| [01_first_app](projects/01_first_app/) | First Python app in a Dockerfile |
| [02_flask_app](projects/02_flask_app/) | Flask image, `0.0.0.0`, port mapping |
| [03_docker_app_network](projects/03_docker_app_network/) | Flask + MySQL, two Dockerfiles, container DNS |
| [04_docker_compose](projects/04_docker_compose/) | Same stack in Compose; MySQL from `image:`, Flask from `build:` |

## Acknowledgements

Thanks to [Ansh Lamba](https://www.youtube.com/@AnshLambaJSR) for the 4.5-hour Docker tutorial this material follows:

[Docker Tutorial for Beginners (DATA DOMAIN EDITION)](https://www.youtube.com/watch?v=nAHx_uSBfTg)
