
# OpenOCD with FT232H support (openocd)

Installs OpenOCD with FTDI/MPSSE support for FT232H-class JTAG/SWD adapters. Defaults to apt's packaged OpenOCD; can be flipped to from-source for projects that need 0.12.0+ features.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/openocd:1": {
        "from_source": false,
        "install_udev_rules": true
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| from_source | Build OpenOCD from source at the pinned tag instead of apt-installing. Adds ~5–10 min to image build. Use when you need 0.12.0+ features. | boolean | false |
| version | Git tag (without leading `v`) to build when `from_source=true`. | string | 0.12.0 |
| install_udev_rules | Install `/etc/udev/rules.d/99-ftdi-ft232h.rules` (FT232H VID:PID `0403:6014`, plugdev/uaccess). | boolean | true |

## USB passthrough caveats

The udev rule alone doesn't give the container access to a host-attached FT232H. The container has to be run with at least one of:

- `--device /dev/bus/usb/...` exposing the specific device
- `-v /dev/bus/usb:/dev/bus/usb` exposing the whole USB bus (with `--device-cgroup-rule=c 189:* rmw`)
- `--privileged`

Inside `devcontainer.json` this lives in the `runArgs:` array. On Docker-on-Mac, USB passthrough into containers is not supported — connect the FT232H to a remote Linux/Windows host and forward the OpenOCD TCP port instead.

## OS Support

Debian / Ubuntu only.
