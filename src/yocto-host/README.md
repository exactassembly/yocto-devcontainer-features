
# Yocto build host prerequisites (yocto-host)

Installs the apt packages required by the Yocto build host for a given Yocto release. Replaces the inline apt block typically copied into a project's Dockerfile. Inspired by willmmiles/devcontainer-feature-yocto with current release coverage.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-host:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| release | Target Yocto release. Selects the package list and any release-specific quirks (e.g., python2 for pre-3.1 releases). Numeric versions like '5.2' or '4.0' are also accepted. | string | walnascar |
| install_multilib | On amd64 hosts, also install gcc-multilib / g++-multilib (needed by some legacy Yocto recipes that build i686 helper binaries). Harmless to leave on; turn off to shrink the image. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/yocto-host/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
