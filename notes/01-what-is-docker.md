# What is Docker

## The problem

Code can be the same on two machines and still behave differently. Runtimes, libraries, OS packages, and config are part of the program. “Works on my machine” means the **environment** did not travel with the source.

Shipping source is not shipping a runnable app.

## Packaging

Package = app + runtime + libraries + OS user-space (files, binaries, configs).

Not in the package: the **host kernel**. Containers share the kernel of the machine they run on.

A zip of the repo is not a package. It does not pin Python/Node, native libs, OS packages, or the start command.

**Image** = the packaged template. **Container** = a running (or stopped) copy of that template.

Shipping-container analogy: standard unit you move the same way. It is about standardization, not about how isolation is implemented.

## What Docker is

A platform to **build, ship, and run** apps in containers.

| Piece | Role |
|---|---|
| Engine | Builds images, runs containers |
| Image | Immutable template |
| Container | Instance of an image |
| Registry | Store / download images (Docker Hub is the public default) |
| Docker Desktop | App that installs the engine; on Windows/Mac it also runs a Linux VM |

Not a VM. Not a language. Not a cloud. Not Kubernetes. Not automatic security.

## Why Docker

- Same image on laptop, CI, and server → same environment
- Isolation without a guest OS per app → higher density than VMs
- Starts a process, not a kernel → fast boot, smaller disk/RAM
- Standard artifact that CI and clouds already know how to run

Limits: does not fix bad code, does not replace `pip`/`npm`, Linux containers still need a Linux kernel, isolation ≠ security.

## Mental model

```text
app + user-space  →  IMAGE  →  many CONTAINERS
kernel stays on the host
```

Package once, run many times. Same image, same behavior — if the host can run that kind of container.

## Misconceptions

- Docker is not a VM.
- The image is not a full OS (no kernel inside).
- “Runs anywhere” still needs a matching kernel family and CPU architecture.
- Docker does not replace language package managers; it packages their result.
