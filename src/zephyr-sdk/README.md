
# Zephyr SDK (zephyr-sdk)

Downloads and installs a pinned Zephyr SDK release from [`zephyrproject-rtos/sdk-ng`](https://github.com/zephyrproject-rtos/sdk-ng), runs the SDK's `setup.sh` to register CMake packages and host tools, and optionally pip-installs `west`.

Useful when a single container builds **both a Yocto host image and Zephyr firmware** — for example, dual-CPU SDKs that ship a Cortex-M / Cortex-A firmware alongside a Linux host image.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/zephyr-sdk:1": {
        "version": "0.17.4",
        "toolchains": "arm-zephyr-eabi",
        "install_west": true
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Zephyr SDK version. As of May 2026, `0.17.4` is the latest 0.17.x and `1.0.1` is the latest 1.x. | string | 0.17.4 |
| install_dir | Parent directory the SDK is unpacked into. The SDK lands at `${install_dir}/zephyr-sdk-${version}`. | string | /opt |
| toolchains | Which toolchains to install: `all`, `minimal`, or a specific triple (`arm-zephyr-eabi`, `aarch64-zephyr-elf`, `riscv64-zephyr-elf`, `x86_64-zephyr-elf`). `minimal` is fastest; specific triple keeps the image small. | string | minimal |
| install_west | Pip-install `west` for the container user. | boolean | true |

## Environment

Sets `ZEPHYR_SDK_INSTALL_DIR` pointing at the install location. Also writes `/etc/profile.d/zephyr-sdk.sh` so login shells see the variable regardless of how the container is entered.

## OS Support

Linux x86_64 and aarch64 hosts. Other architectures fail with a clear error.
