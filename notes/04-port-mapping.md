# Port Mapping

## The problem

A container has its **own network**. The process inside listens on a **container port**. That port is not automatically the same as a port on your laptop.

Flask in `projects/02_flask_app` binds to `0.0.0.0:5000` **inside** the container. `http://localhost:5000` on the host still fails until you **publish** that port.

```text
HOST (your browser)                    CONTAINER
localhost:5000  ──×──  (no mapping)    process listening on :5000
```

Port mapping is the hole you punch: “when something hits this **host** port, send it to that **container** port.”

## What mapping is

```text
HOST                              CONTAINER
:8080  ────────────────────────►  :5000
        publish / map / -p
```

Left number = **host**. Right number = **container**.

They do not have to match. `8080:5000` means: browser uses 8080; the app still thinks it is on 5000.

```bash
docker run --rm -p 8080:5000 myapp
```

Then `http://localhost:8080` reaches the process on 5000 in the container.

## Syntax (`-p` / `--publish`)

```text
[host_ip:]host_port:container_port[/protocol]
```

| Form | Meaning |
|---|---|
| `-p 8080:5000` | Host 8080 → container 5000 (TCP, all host interfaces) |
| `-p 5000:5000` | Same number on both sides |
| `-p 127.0.0.1:8080:5000` | Only reachable from the host, not the LAN |
| `-p 8080:5000/udp` | UDP instead of TCP |
| `-p 5000` | Container 5000 → **random** free host port |

`-P` (capital) publishes **all** `EXPOSE`d ports to random host ports. Prefer explicit `-p` while learning.

Check what landed:

```bash
docker ps
# PORTS column: 0.0.0.0:8080->5000/tcp
```

## `EXPOSE` is not mapping

`EXPOSE 5000` in a Dockerfile is **documentation** (and a hint for `-P`). It does **not** open the port on the host.

| | `EXPOSE` | `-p` / Compose `ports` |
|---|---|---|
| When | Image metadata (build) | Run time |
| Host access? | No | Yes |
| Required to map? | No | Yes, if you want host/browser access |

You can `-p 8080:5000` with no `EXPOSE` at all. The process still must **listen** on 5000 inside the container.

## Why the app must listen on `0.0.0.0`

Inside the container, `127.0.0.1` is **the container’s** loopback, not the host’s.

If Flask binds only to `127.0.0.1:5000`, mapping `8080:5000` still fails: packets arrive on the container’s eth0, and nothing is listening there.

```python
app.run(host="0.0.0.0", port=5000)
```

`0.0.0.0` = all interfaces **in the container**. That is what published traffic hits.

## Other containers do not need this

On a Docker network, services talk by **name and container port**:

```text
app → http://db:5432     # no host mapping
```

`-p` is for **the host** (browser, Postman, a tool on your laptop). Skip it in production for databases you do not want on the public internet. Bind `127.0.0.1` if you only need local tools.

Compose uses the same `HOST:CONTAINER` pair:

```yaml
ports:
  - "8080:5000"
  - "127.0.0.1:5432:5432"
```

## Mental model

```text
browser → host IP:host_port → Docker publish → container_port → app
```

Two numbers. Host is where **you** connect. Container is where **the process** listens.

## Misconceptions

- `EXPOSE` does not publish a port.
- Mapping `8080:5000` does not change the app’s listen port; the app still uses 5000.
- `localhost` in the container is not `localhost` on the host.
- Publishing on all interfaces (`0.0.0.0:5432`) can expose a database to the network. Prefer `127.0.0.1` for local-only access.
- Two containers cannot both bind the **same host port**. Container ports can be the same; host ports cannot collide.
