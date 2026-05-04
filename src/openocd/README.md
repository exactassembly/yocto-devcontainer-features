
# OpenOCD with FT232H support (openocd)

Installs OpenOCD with FTDI/MPSSE support for FT232H-class JTAG/SWD adapters. Defaults to apt's packaged OpenOCD (fast, suffices for FT232H bring-up); can be flipped to from-source for projects that need 0.12.0+ features. Optionally installs the FT232H udev rule so non-root users can claim the adapter.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/openocd:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| from_source | If true, build OpenOCD from source at the pinned version (slow — adds ~5–10 min to image build). If false, install via apt (faster, typically a recent enough version for FT232H work). | boolean | false |
| version | Source-build pin (only used when from_source=true). The git tag/branch to check out from openocd-org/openocd. | string | 0.12.0 |
| install_udev_rules | Install /etc/udev/rules.d/99-ftdi-ft232h.rules so the FT232H VID:PID 0403:6014 is claimable by users in the plugdev group with uaccess. Harmless inside a container; useful when the container is run with --privileged or with /dev/bus/usb mounted. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/openocd/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
