
# Zephyr SDK (zephyr-sdk)

Downloads and installs one or more Zephyr SDK releases (toolchains for Zephyr RTOS) and, by default, the Zephyr build-host apt prerequisites (cmake, ninja-build, gperf, device-tree-compiler, ccache). Optionally pip-installs west. Pairs well with the kas + yocto-host features when a single container builds both a Yocto host image and Zephyr firmware (e.g., dual-CPU SDKs that ship a Cortex-M firmware alongside a Linux host image).

## Example Usage

Single SDK, defaults (Zephyr 4.x):

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2": {}
}
```

Pin a specific SDK and toolchain:

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2": {
        "version": "1.0.1",
        "toolchains": "arm-zephyr-eabi"
    }
}
```

Multiple SDKs side-by-side (e.g., the container builds both a Zephyr 4.x app pinned to SDK 1.0.x and a legacy Zephyr 3.7 LTS app pinned to SDK 0.17.x):

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2": {
        "version": "1.0.1",
        "extra_versions": "0.17.4",
        "toolchains": "arm-zephyr-eabi"
    }
}
```

With multiple SDKs installed, `unset ZEPHYR_SDK_INSTALL_DIR` in a per-build shell to let Zephyr's CMake `find_zephyr_sdk()` auto-select the highest version satisfying the project's `zephyr/SDK_VERSION` minimum. Otherwise the primary `version` (pointed to by `/opt/zephyr-sdk`) wins.

Skip host deps if a co-installed feature already provides them:

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:2": {
        "host_deps": false
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Primary Zephyr SDK version to install. `ZEPHYR_SDK_INSTALL_DIR` (via the `/opt/zephyr-sdk` symlink) points at this one. As of May 2026 the latest releases are `1.0.1` (matches Zephyr 4.x, the current stable line) and `0.17.4` (latest 0.17.x, required by Zephyr 3.7 LTS and earlier). | string | 1.0.1 |
| extra_versions | Optional comma-separated list of additional SDK versions to install alongside `version`, e.g. `"0.17.4,0.16.8"`. Each lands at `/opt/zephyr-sdk-X.Y.Z/`. Zephyr CMake's `find_zephyr_sdk()` scans that path and picks the highest version satisfying each project's `zephyr/SDK_VERSION` minimum. Leave empty for the single-SDK case. | string |  |
| install_dir | Parent directory the SDKs are unpacked into. A stable `${install_dir}/zephyr-sdk` symlink is created pointing at the primary `version`. | string | /opt |
| toolchains | Which toolchains to keep installed (applied to every SDK installed). `all` downloads the full bundle (~2 GB per version); `minimal` downloads the small bundle; a specific triple (`arm-zephyr-eabi`, `aarch64-zephyr-elf`, `riscv64-zephyr-elf`, `x86_64-zephyr-elf`) installs only that toolchain. | string | minimal |
| host_deps | Install the Zephyr build-host apt prerequisites (`cmake`, `ninja-build`, `gperf`, `device-tree-compiler`, `ccache`, `build-essential`). These are NOT part of the SDK bundle itself but are required for `west build`. Installed at image-build time so they cache in the feature's Docker layer (no per-rebuild re-download). Disable only if another feature already provides this set. | boolean | true |
| install_west | Pip-install west alongside the SDK. Most Zephyr workflows need it. Disable if your project ships its own pinned west via a Python venv inside the workspace. | boolean | true |

## How multi-SDK auto-selection works

Zephyr's CMake helper `find_zephyr_sdk()` (defined in `zephyr/cmake/modules/FindZephyr-sdk.cmake`) searches, in order:

1. `ZEPHYR_SDK_INSTALL_DIR` env var (if set, that SDK is used unconditionally).
2. CMake user package registry (`~/.cmake/packages/Zephyr-sdk/`).
3. CMake system package registry.
4. A hard-coded search list including `/opt/zephyr-sdk-*`, `~/zephyr-sdk-*`, `/usr/local/zephyr-sdk-*`, etc.

Each project's `zephyr/SDK_VERSION` file declares the minimum SDK version required. When `ZEPHYR_SDK_INSTALL_DIR` is unset, CMake walks the candidate dirs, filters out any SDK older than `SDK_VERSION`, and uses the highest remaining one. That's how a single container with `1.0.1` + `0.17.4` installed can serve a Zephyr 4.x project (gets 1.0.1) and a Zephyr 3.7 project (gets 0.17.4) without per-project config — just unset the env var.

This feature creates `/opt/zephyr-sdk` as a symlink to the primary `version` and sets `ZEPHYR_SDK_INSTALL_DIR` to that stable path. To opt into per-project auto-selection, override or unset the env var in your build shell or `west build` wrapper.

## Breaking changes in v2

* Default `version` changed from `0.17.4` → `1.0.1` to match the Zephyr 4.x stable line. Users pinned to the previous default should set `"version": "0.17.4"` explicitly, or pin the feature to `:1`.
* `ZEPHYR_SDK_INSTALL_DIR` (containerEnv) now points at `/opt/zephyr-sdk` (a symlink) rather than a versioned path. Tools that hard-coded `/opt/zephyr-sdk-0.17.4` must use the env var or the symlink.

---

_Note: This file is hand-maintained. The repository's release workflow disables devcontainers/action's docs auto-generator (which would overwrite this with a thinner table-only README)._
