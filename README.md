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
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2":     { "version": "0.17.4", "toolchains": "arm-zephyr-eabi" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/openocd:1":        {}
}
```

For a **Zephyr-only project** (firmware only, no Yocto image build):

```jsonc
"features": {
    "ghcr.io/devcontainers/features/common-utils:2":                      {},
    "ghcr.io/devcontainers/features/python:1":                            { "version": "3.11" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2":     { "version": "0.17.4", "toolchains": "arm-zephyr-eabi" },
    "ghcr.io/exactassembly/yocto-devcontainer-features/openocd:1":        {},
    "ghcr.io/exactassembly/yocto-devcontainer-features/jlink:1":          { "version": "V794e" }
}
```

A slim Python base image (e.g. `mcr.microsoft.com/devcontainers/python:1-3.11-trixie`) is enough for this stack — none of the Yocto-host apt set is needed. The image rebuilds in ~5 min versus ~30 min for the full Yocto + Zephyr combo, which is the main reason to keep firmware-only projects on their own devcontainer.

**Why the `jlink.version` pin.** The default (`latest`) tracks the current Segger release, which is fine for ad-hoc bring-up but two specific cases warrant pinning:

- **NCS / NRF Connect SDK forks.** Nordic publishes a "tested with" JLink version in each NCS release notes (the Toolchain Manager's bundled JLink). Newer Segger releases routinely break `west flash --runner nrfjprog` and the SES debugger integration on NCS branches. Pin to the version the matching NCS release calls out.
- **west's `jlink` runner output parser.** Recent JLink releases have changed `JLinkExe` banner and progress strings in ways that confuse Zephyr's [`runners.jlink`](https://github.com/zephyrproject-rtos/zephyr/blob/main/scripts/west_commands/runners/jlink.py) parser — `west flash -r jlink` reports spurious failures even when the image lands correctly on the target. Until upstream Zephyr catches up, pinning to a known-good Segger (e.g. `V794e`, `V796s`, or whatever your CI passed against) is the documented workaround.

Browse the archived versions at <https://www.segger.com/downloads/jlink/> — any string of the form `V<NNN><letter>` that appears in a filename there is valid for the `version` option.

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
