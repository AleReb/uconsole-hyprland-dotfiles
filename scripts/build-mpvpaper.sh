#!/bin/sh
set -eu

SRC="${SRC:-$HOME/src/mpvpaper}"
PREFIX="${PREFIX:-$HOME/.local}"

sudo apt install -y -t trixie-backports \
    meson ninja-build gcc pkg-config git scdoc \
    libmpv-dev libwayland-dev wayland-protocols

mkdir -p "$(dirname "$SRC")"

if [ -d "$SRC/.git" ]; then
    git -C "$SRC" pull --ff-only
else
    git clone https://github.com/GhostNaN/mpvpaper.git "$SRC"
fi

cd "$SRC"
if [ ! -d build ]; then
    meson setup build --prefix="$PREFIX"
fi
ninja -C build
ninja -C build install

printf 'Installed mpvpaper to %s/bin\n' "$PREFIX"
