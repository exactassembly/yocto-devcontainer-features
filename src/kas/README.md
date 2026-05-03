
# kas Yocto build orchestrator (kas)

Installs the kas (Siemens) build automation tool for Yocto/bitbake projects. Pip-installs a pinned kas release and ships a shell wrapper that drives common build steps (init, build, shell, cleansstate) using project-scoped sstate-cache and downloads directories.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/kas:1": {
        "version": "5.2",
        "menu_file": "yocto/kas-menu.yml"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | kas version pinned for pip install. Use `5.2` (current as of Feb 2026) for reproducible builds; use `latest` to track upstream (not recommended for CI). | string | 5.2 |
| menu_file | Default kas configuration YAML the wrapper script targets when no explicit file is provided. Resolved relative to `KAS_MENU_DIR` (the project workspace by default). | string | kas-menu.yml |

## Environment

The feature sets the following `containerEnv` defaults — override in your `devcontainer.json` to scope them per project:

| Variable | Default | Used by |
|----------|---------|---------|
| `KAS_MENU_FILE` | `kas-menu.yml` | wrapper |
| `KAS_BUILD_DIR` | `/var/lib/kas-build` | wrapper, `kas` |
| `SSTATE_DIR` | `/var/lib/sstate-cache` | bitbake |
| `DL_DIR` | `/var/lib/dl-cache` | bitbake |

Pair this feature with [`yocto-host`](../yocto-host) for the apt-package prerequisites and [`yocto-sstate`](../yocto-sstate) for cache volume mounts.

## Wrapper script

A small shell wrapper is installed at `/opt/kas/scripts/kas-build.sh` and is added to `PATH` for the container user. Subcommands:

| Subcommand | Effect |
|------------|--------|
| `kas-build.sh build` | `kas build ${KAS_MENU_DIR}/${KAS_MENU_FILE}` |
| `kas-build.sh shell` | `kas shell ${KAS_MENU_DIR}/${KAS_MENU_FILE}` (drops into a bitbake env) |
| `kas-build.sh checkout` | `kas checkout ...` — clones layers per the menu, no build |
| `kas-build.sh for-all -- <cmd>` | runs `<cmd>` in every layer |
| `kas-build.sh cleansstate <recipe>...` | invokes `bitbake -c cleansstate` for the named recipes |

## OS Support

This feature should work on recent Debian/Ubuntu-based images with `apt` available. `python3` (≥ 3.9, kas's own requirement) must be on `PATH` — the dependency is enforced by `installsAfter: ["ghcr.io/devcontainers/features/python"]`.

`bash` is required to execute `install.sh` and `kas-build.sh`.
