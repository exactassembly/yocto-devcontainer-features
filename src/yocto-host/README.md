
# Yocto build host prerequisites (yocto-host)

Installs the apt packages required by the Yocto build host for a given Yocto release. Replaces the inline apt block typically copied into a project's Dockerfile.

Inspired by [`willmmiles/devcontainer-feature-yocto`](https://github.com/willmmiles/devcontainer-feature-yocto), refreshed for current Yocto releases (walnascar, styhead, scarthgap) and a modernized package list (drops `python3-distutils`, adds `python3-setuptools`, `file`, `liblz4-tool`).

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-host:1": {
        "release": "walnascar"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| release | Target Yocto release. Selects the package list and any release-specific quirks (e.g., python2 for pre-3.1 releases). Numeric versions like `5.2` or `4.0` are also accepted. | string | walnascar |
| install_multilib | On amd64 hosts, also install `gcc-multilib` / `g++-multilib` (needed by some legacy Yocto recipes that build i686 helper binaries). Harmless to leave on; turn off to shrink the image. | boolean | true |

## Known Yocto release names

`walnascar` (5.2) · `styhead` (5.1) · `scarthgap` (5.0 LTS) · `nanbield` (4.3) · `mickledore` (4.2) · `langdale` (4.1) · `kirkstone` (4.0 LTS) · `honister` (3.4) · `hardknott` (3.3) · `gatesgarth` (3.2) · `dunfell` (3.1 LTS) · `zeus` (3.0).

The feature targets the **current Yocto host requirements**; the release name is used mainly to apply legacy quirks (python2 for pre-3.1 builds) and to advertise intent to consumers.

## OS Support

Debian / Ubuntu only. The feature errors out on other distributions. `bash` is required to execute `install.sh`.
