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

## Misconceptions

- Image is not the running app.
- Installing something in a container does not change the image.
- Stopped is not deleted.
- Containers do not each store a full copy of the image; layers are shared.
- Snapshotting a container into an image (`commit`) is not how you should build images — rebuild from a recipe instead.
