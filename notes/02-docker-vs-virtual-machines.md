# Docker vs Virtual Machines

## The actual difference

- **VM** virtualizes **hardware**. Boots its own kernel and guest OS.
- **Container** virtualizes the **process view**. Isolated process on the **host kernel**. No second kernel.

```text
VM:        App → Guest OS → Guest kernel → Hypervisor → Hardware
Container: App → user-space files → Host kernel → Hardware
```

That is why containers start faster, use less disk/RAM, and pack denser — and why isolation is weaker than a VM.

## Virtual machine

Hypervisor fakes a machine. Each VM has virtual CPU/disk/NIC and a **guest OS with its own kernel**.

- Slow-ish boot (kernel + OS, then app)
- Large disk (full OS)
- Strong isolation (separate kernel)
- Can run a different OS than the host (Windows guest on Linux, etc.)

## Container

A process with kernel isolation, started from an image.

**Namespaces** — what it can see (own PIDs, filesystem, network, hostname).

**cgroups** — how much it can use (CPU, RAM, pids).

**Filesystem** — image files + a writable layer. Looks like a Linux distro. Still no guest kernel.

Isolated: process tree, files, network, hostname, resource limits.  
Not isolated: kernel, physical hardware. Privileged mode / host mounts punch holes.

OS-level isolation: stronger than two normal processes, weaker than two VMs.

## Comparison

| | VM | Container |
|---|---|---|
| Virtualizes | Hardware | Process view |
| Kernel | Own guest kernel | Shared host kernel |
| Startup | Boots an OS | Starts a process |
| Disk / RAM | Full OS tax | App + user-space |
| Density | Fewer per host | Many per host |
| Isolation | Stronger | Weaker than VMs |
| OS flexibility | Any guest the hypervisor runs | Must match kernel family (Linux containers need Linux) |

## They coexist

Not either/or. Normal production: cloud **VM** → container runtime → several **containers**.

On Windows/Mac, Linux containers need a Linux kernel. Docker Desktop runs a **Linux VM**, then runs containers inside it. You are using both.

```text
Windows/macOS → Linux VM → Docker Engine → Linux containers
```

## When to use which

**VM:** different OS/kernel, stronger tenancy isolation, lift a whole machine, policy that requires a separate OS.

**Container:** same app environment on laptop/CI/server, many services on one host, fast create/destroy.

## Mental model

Need a second **computer** (second kernel)? → VM.  
Need a second **environment for a process**? → Container.

```text
ordinary processes  <  containers  <  VMs  <  separate machines
```

## Misconceptions

- Container ≠ lightweight VM. No guest kernel, no virtual hardware.
- “No OS” is wrong: no *guest kernel*; user-space can still look like Alpine/Debian.
- Containers are not automatically more secure than VMs (shared kernel).
- Using Docker on Windows/Mac usually still uses a VM.
