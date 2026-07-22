# Third-party components

## Aquamarine

The full installer downloads Aquamarine from:

```text
https://github.com/hyprwm/aquamarine.git
v0.11.0 / cd8321eba285e3cce50c50f19d5174a0b2567297
```

`patches/aquamarine-0.11-uconsole-render-node.patch` is applied to that exact
revision and the resulting shared library is installed only under
`~/.local/opt/aquamarine-0.11-uconsole/`. Aquamarine is BSD-3-Clause licensed.
The license text is retained in `licenses/AQUAMARINE-BSD-3-CLAUSE.txt`. The
Debian library is not replaced.

## swww

This repository includes ARM64 binaries for convenience:

- `bin/swww`
- `bin/swww-daemon`

They were built on Debian 13 aarch64 from:

```text
https://github.com/LGFae/swww.git
version 0.11.2-master2
```

`swww` is GPLv3. Rebuild locally with:

```sh
./scripts/build-swww.sh
```
