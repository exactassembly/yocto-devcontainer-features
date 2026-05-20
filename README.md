# yocto-devcontainer-features

Installable [devcontainer features](https://containers.dev/implementors/features/) for building Yocto Project Linux images and Zephyr RTOS firmware. Mix-and-match in your project's `devcontainer.json` to assemble a build environment without copy-pasting Dockerfile boilerplate.

Published to GHCR at `ghcr.io/exactassembly/yocto-devcontainer-features/<feature>:<version>`.

## Available features

| Feature | Purpose | Pairs with |
|---------|---------|------------|
| [`yocto-host`](src/yocto-host/) | Apt packages for the Yocto build host. Release-aware (walnascar, scarthgap, etc.). Replaces inline `apt install` blocks in project Dockerfiles. | every other feature in this repo |
| [`yocto-sstate`](src/yocto-sstate/) | Named Docker volumes for sstate-cache and source downloads, mounted at `/var/lib/sstate-cache` and `/var/lib/dl-cache`. Pure `mounts:` declaration; no install script. | `kas`, `yocto-cooker` |
| [`kas`](src/kas/) | Pip-installs [kas](https://github.com/siemens/kas) (Siemens) at a pinned version, ships a `kas-build.sh` wrapper for VSCode tasks/CI. **Recommended orchestrator for new projects.** | `yocto-host` + `yocto-sstate` |
| [`yocto-cooker`](src/yocto-cooker/) | Pip-installs [yocto-cooker](https://github.com/cpb-/yocto-cooker) and ships a `broiler.sh` wrapper. **Maintained for back-compat.** Upstream cooker has not shipped since 2023; new projects should use `kas`. | `yocto-host` + `yocto-sstate` |
| [`zephyr-sdk`](src/zephyr-sdk/) | Downloads + installs a pinned [Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng) release, optionally pip-installs `west`. Use when one container builds both a Yocto image and Zephyr firmware. | `yocto-host` (or standalone) |
| [`openocd`](src/openocd/) | Installs OpenOCD with FTDI/MPSSE support. Apt-installs by default, source-builds if a pinned 0.12.0+ is needed. Optional FT232H udev rule. | `zephyr-sdk` for bench smoke tests |
| [`jlink`](src/jlink/) | Installs the Segger J-Link Linux package (`JLinkExe`, `JLinkGDBServer`, …) plus its X11/xcb runtime deps via `apt-get install ./jlink.deb`. | `zephyr-sdk` for `west flash -r jlink` |

## Typical project setup

For a project that builds **both a Yocto image and Zephyr firmware** in one container (e.g., a multi-CPU SDK):

```jsonc
"features": {
    "ghcr.io/devcontainers/features/python:1":                            { "version": "3.11" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-host:1":     { "release": "walnascar" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-sstate:1":   {},
    "ghcr.io/exactassembly/yocto-devcontainer-features/kas:1":            { "version": "5.2", "menu_file": "yocto/kas-menu.yml" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:1":     { "version": "0.17.4", "toolchains": "arm-zephyr-eabi" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/openocd:1":        {}
}
```

For a Yocto-only project:

```jsonc
"features": {
    "ghcr.io/devcontainers/features/python:1":                            { "version": "3.11" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-host:1":     { "release": "walnascar" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-sstate:1":   {},
    "ghcr.io/exactassembly/yocto-devcontainer-features/kas:1":            { "version": "5.2" }
}
```

## Versioning

Each feature is versioned independently. Bump the `version` field in the feature's `devcontainer-feature.json` for any user-visible change; the `release.yaml` workflow publishes that exact version tag plus a major-version-only tag (`:1`) on workflow dispatch from `main`.

## License

AGPL-3.0 (see [LICENSE](LICENSE)).
