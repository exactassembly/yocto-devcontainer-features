
# Yocto build automation (yocto-cooker) (yocto-cooker)

Installs the yocto-cooker meta-tool for assembling Yocto builds from a JSON menu file. NOTE: the upstream yocto-cooker project (cpb-/yocto-cooker) has not shipped a release since 1.4.0 (2023-10-31) and shows minimal recent activity; new projects should consider the 'kas' feature in this repo (Siemens, actively maintained) or the upstream 'bitbake-setup' tool once it stabilizes. This feature is kept maintained for back-compat with existing projects.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-cooker:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | yocto-cooker version pin. Installed from PyPI when set to a version string. Use 'latest' to track upstream HEAD on PyPI (not recommended for CI). | string | 1.4.0 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/yocto-cooker/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
