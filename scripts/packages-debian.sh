#!/bin/sh
set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

[ -r /etc/os-release ] || {
    printf 'No se pudo identificar la version de Debian.\n' >&2
    exit 1
}

. /etc/os-release
[ "${VERSION_CODENAME:-}" = trixie ] || {
    printf 'Este instalador requiere Debian 13 (trixie); se detecto: %s\n' "${VERSION_CODENAME:-desconocido}" >&2
    exit 1
}

if ! grep -RqsE 'Suites:[[:space:]]+trixie-backports|^[[:space:]]*deb[[:space:]].*[[:space:]]trixie-backports([[:space:]]|$)' \
    /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    printf 'Enabling Debian trixie-backports.\n'
    sudo install -m 0644 "$repo_root/apt/trixie-backports.sources" \
        /etc/apt/sources.list.d/uconsole-trixie-backports.sources
fi

sudo apt update
sudo apt install -y \
    git waybar wofi foot swaybg keyd cava fastfetch ffmpeg \
    yad liblz4-1 libxxhash0 bluez blueman \
    wl-clipboard playerctl pavucontrol network-manager-gnome wev

sudo apt install -y -t trixie-backports \
    hyprland uwsm xdg-desktop-portal-hyprland \
    hypridle hyprlock hyprpolkitagent hyprpaper hyprland-guiutils \
    pipewire pipewire-pulse wireplumber

# Build dependencies for the isolated Aquamarine 0.11 uConsole fix.
sudo apt install -y \
    build-essential cmake ninja-build pkg-config \
    libegl-dev libgl-dev libgles-dev libwayland-dev wayland-protocols \
    libseat-dev libinput-dev libhyprutils-dev libpixman-1-dev \
    libdrm-dev libgbm-dev libudev-dev libdisplay-info-dev \
    hyprwayland-scanner hwdata
