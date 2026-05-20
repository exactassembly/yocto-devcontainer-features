
# Segger J-Link (jlink)

Installs the Segger J-Link Linux package (`JLinkExe`, `JLinkGDBServer`, `JLinkRTTClient`, …) and its X11/xcb/xkbcommon runtime dependencies. Used by `west flash -r jlink`, Cortex-Debug, and any IDE that drives a Segger J-Link / J-Trace probe. Downloads the `.deb` from segger.com at image build time using the standard CLI license-accept POST.

## Example Usage

```jsonc
"features": {
    // "latest" — tracks the current package on segger.com. Convenient,
    // but image rebuilds drift as Segger publishes new releases.
    "ghcr.io/exactassembly/yocto-devcontainer-features/jlink:1": {}
}
```

Pin a specific version for reproducible builds:

```jsonc
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/jlink:1": {
        "version": "V844a"
    }
}
```

The list of archived versions is on <https://www.segger.com/downloads/jlink/>.

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | J-Link version. `latest` downloads the current package; a Segger version string (e.g. `V844a`) is interpolated into the archived URL `JLink_Linux_<version>_<arch>.deb`. | string | latest |

## Pairs with

- [`zephyr-sdk`](../zephyr-sdk/README.md) — `west flash -r jlink` and `west debug -r jlink` are the canonical Zephyr workflows that drive `JLinkGDBServer`.
- [`openocd`](../openocd/README.md) — alternative probe driver for non-Segger adapters; safe to install both in the same image.

## Notes & gotchas

- **License click-through.** `accept_license_agreement=accepted&non_emb_ctr=confirmed` is Segger's documented CLI download path. Stable for years but not formally supported — if Segger changes the form, mirror the `.deb` yourself and pass its URL/version via the option.
- **Why `apt-get install ./jlink.deb` and not `dpkg -i`.** The Segger `.deb` declares X11/xcb/xkbcommon runtime deps that aren't preinstalled on slim base images (e.g. `python:3.x-trixie`). `dpkg -i` does not resolve dependencies and leaves the package in `iU` state; `apt-get install` with a local file path pulls the missing libs from the distro repos in the same transaction.
- **USB access at runtime.** This feature installs the host tools only. To actually talk to a probe you still need the probe device exposed to the container (e.g. `--device=/dev/bus/usb` or `--privileged`) and, on the host, the Segger udev rules — `/opt/SEGGER/JLink/99-jlink.rules` ships with the package; symlink it into `/etc/udev/rules.d/` on the host (not inside the container) and reload udev.
- **Arch coverage.** `aarch64` and `x86_64` only. Add a case to `install.sh` if you need another arch.
- **Image size.** The Linux JLink package is ~120 MB installed (most of that is the GDB server + per-MCU init scripts under `/opt/SEGGER/JLink/`).

---

_Note: this README is hand-maintained; the repo's release workflow has `generate-docs: false` so this file is not regenerated from `devcontainer-feature.json`._
