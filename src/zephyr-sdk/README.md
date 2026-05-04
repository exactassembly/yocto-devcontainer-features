
# Zephyr SDK (zephyr-sdk)

Downloads and installs a pinned Zephyr SDK release (toolchains for Zephyr RTOS). Optionally installs west via pipx. Pairs well with the kas + yocto-host features when a single container builds both a Yocto host image and Zephyr firmware (e.g., dual-CPU SDKs that ship a Cortex-M firmware alongside a Linux host image).

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Zephyr SDK version to download from github.com/zephyrproject-rtos/sdk-ng. Pin to match your firmware's tested SDK. As of May 2026, 0.17.4 is the latest 0.17.x and 1.0.1 is the latest 1.x. | string | 0.17.4 |
| install_dir | Parent directory the SDK is unpacked into. The SDK lands at ${install_dir}/zephyr-sdk-${version}. ZEPHYR_SDK_INSTALL_DIR is exported pointing at that path. | string | /opt |
| toolchains | Which toolchains to keep installed. 'all' downloads the full SDK (~2 GB on disk); 'minimal' downloads the small bundle and lets the user add toolchains later; a specific triple installs only that toolchain. For Cortex-M / Cortex-A53 work pick 'arm-zephyr-eabi' or 'aarch64-zephyr-elf'. | string | minimal |
| install_west | Pip-install west alongside the SDK. Most Zephyr workflows need it. Disable if your project ships its own pinned west via a Python venv inside the workspace. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/zephyr-sdk/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
