# Networks

## The problem

Each container has its **own network namespace**: its own interfaces, IP, and `localhost`. Two containers on the same machine are not on “the same LAN” unless Docker puts them on the **same network**.

Port mapping (`-p`) is a hole to the **host**. Containers talking to each other should not go through the host. They use a Docker network and the **container port**.

```text
browser  →  host:8080  →  -p  →  app:5000     # host access

app      →  db:5432                           # container-to-container
                 ↑
           same Docker network, no -p needed
```

## What a Docker network is

A virtual switch Docker attaches containers to. Same network → they can reach each other’s **container IPs** (and, on user-defined networks, **names**). Different networks → isolated, unless you attach a container to both.

```text
network "backend"
  ├── app   (10.0.0.2)
  └── db    (10.0.0.3)

network "frontend"
  └── web   (cannot reach db)
```

`docker network ls` lists them. Built-in ones you will see immediately: **bridge**, **host**, **none**.

## Drivers (the ones that matter first)

| Driver | What it is |
|---|---|
| **bridge** | Default on one host. Private virtual network + NAT to the outside. |
| **host** | Container shares the host’s network stack. No isolation. No `-p` — the process binds host ports directly. |
| **none** | No network (loopback only). |
| **overlay** | Multi-host (Swarm). Skip until you need several machines. |

Linux also has macvlan/ipvlan (container looks like a machine on the physical LAN). Not the learning path.

## Default bridge vs a network you create

`docker run` with no `--network` lands on the **default bridge** (`bridge`).

| | Default `bridge` | User-defined bridge |
|---|---|---|
| Talk by IP | Yes | Yes |
| Talk by **container name** | No | Yes (embedded DNS) |
| Isolated from other projects | Shared with every default-bridge container | Separate network |
| What to use | Quick one-off | Anything with two+ containers |

```bash
docker network create mynet
docker run -d --name db  --network mynet postgres:16
docker run -d --name app --network mynet -p 8080:5000 myapp
```

Inside `app`, `postgres://db:5432` works because DNS on `mynet` resolves **`db`**. On the default bridge you would need `--link` (legacy) or raw IPs (they change). Create a network.

Compose does this for you: one project → one user-defined network. Service names are the hostnames.

```yaml
services:
  app:
    build: .
    ports:
      - "8080:5000"
  db:
    image: postgres:16
    # no ports: — reachable as "db:5432" from app, not from the laptop
```

Two Compose files / two projects get **two** networks. `app` in project A cannot reach `db` in project B unless you put them on a shared external network.

## Name vs IP vs `-p`

- **Hostname** = container name (or Compose service name) on a user-defined network.
- **Port** = the port the process **listens on inside** the container (`5432`, `5000`). Not the host mapped port.
- **`-p`** = only for processes on the **host** (browser, `psql` on your laptop).

Wrong: `app` connecting to `localhost:5432` because you published Postgres to the host. That is the container’s loopback, empty. Use `db:5432`.

Wrong: `app` connecting to `localhost:5432` on the **host** from inside the container. The host’s published port is not `localhost` inside the container (on Linux; Docker Desktop sometimes fakes host access with `host.docker.internal`). Prefer the service name.

## Isolation

Attach only what needs to talk:

```text
frontend-net:  web, api
backend-net:   api, db
```

`web` never sees `db`. `api` sits on both.

```bash
docker network connect backend-net api   # add a running container to another network
docker network inspect mynet             # who is on it, which IPs
```

Outbound internet still works on a normal bridge (NAT). Incoming from the internet still needs publish, or you are only talking inside Docker.

## Mental model

```text
network  =  who can see whom
name     =  DNS on user-defined networks
container port  =  where the process listens
-p       =  extra door on the host
```

Put related containers on one user-defined bridge. Talk by name and container port. Publish only what a human or host tool must hit.

## Misconceptions

- Same machine ≠ same network. Default is isolation, not a shared `localhost`.
- The default bridge does **not** resolve container names. User-defined bridges do.
- Connecting to a **published host port** from another container is the long way around. Use the network.
- `host` network is not “faster Docker.” It removes network isolation.
- `EXPOSE` does not join a network or publish a port.
- Compose “no `ports`” is not “no networking.” Other services on that Compose network can still connect.
