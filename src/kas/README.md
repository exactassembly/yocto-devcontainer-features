
# kas Yocto build orchestrator (kas)

Installs the kas (Siemens) build automation tool for Yocto/bitbake projects. Pip-installs a pinned kas release and ships a shell wrapper that drives common build steps (init, build, shell, cleansstate) using project-scoped sstate-cache and downloads directories.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/kas:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | kas version pinned for pip install. Use '5.2' (current as of Feb 2026) for reproducible builds; use 'latest' to track upstream (not recommended for CI). | string | 5.2 |
| menu_file | Default kas configuration YAML the wrapper script targets when no explicit file is provided. Resolved relative to KAS_MENU_DIR (the project workspace by default). | string | kas-menu.yml |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/kas/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
