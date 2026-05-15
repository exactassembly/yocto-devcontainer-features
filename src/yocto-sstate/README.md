
# Yocto sstate-cache and downloads volumes (yocto-sstate)

Declares Docker named volumes for the Yocto sstate-cache and source downloads cache, mounted at the canonical paths used by the kas / yocto-host / yocto-cooker features (/var/lib/sstate-cache and /var/lib/dl-cache). No install script — pure devcontainer-feature.json mounts. Borrowed in spirit from willmmiles/devcontainer-feature-yocto's yocto-sstate feature, with paths aligned to the bitbake convention used by the other features in this repo.

## Example Usage

```json
"features": {
    "ghcr.io/exactassembly/yocto-devcontainer-features/yocto-sstate:1": {}
}
```





---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/exactassembly/yocto-devcontainer-features/blob/main/src/yocto-sstate/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
