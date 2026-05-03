
# Yocto sstate-cache and downloads volumes (yocto-sstate)

Declares Docker named volumes for the Yocto sstate-cache and source downloads cache, mounted at the canonical paths used by the `kas`, `yocto-host`, and `yocto-cooker` features in this repo.

| Volume | Mount point inside container |
|--------|------------------------------|
| `yocto-sstate-cache` | `/var/lib/sstate-cache` |
| `yocto-dl-cache`     | `/var/lib/dl-cache` |

The feature has **no install script** — the entire effect is the `mounts:` block in `devcontainer-feature.json`. Pure plumbing.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-host:1":   { "release": "walnascar" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-sstate:1": {},
    "ghcr.io/exactassembly/yocto-devcontainer-features/kas:1":          {}
}
```

## Why named volumes vs. bind mounts

- A cold Yocto build is hours; an incremental with a populated sstate-cache is minutes. Persisting these caches across container rebuilds is essential.
- Named Docker volumes are managed entirely by the engine and live on the native Linux filesystem regardless of host OS — important on macOS/Windows where bind-mounted host paths use 9P/virtiofs and would dominate Yocto's I/O profile.

## Sharing caches across multiple repos

Both volume names are global within the Docker engine. If you want every project on the host to share one sstate-cache, this feature gives you that for free. If you want per-project isolation, override the volume names in your project's `docker-compose.yml`:

```yaml
volumes:
  yocto-sstate-cache:
    name: my-project-sstate
  yocto-dl-cache:
    name: my-project-dl
```

(You can't override `mounts` from a feature directly — but `docker-compose` `name:` declarations bind the in-container volume reference to a different host volume.)

## OS Support

OS-agnostic. Works wherever Docker volumes work.
