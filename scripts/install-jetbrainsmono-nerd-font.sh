#!/bin/sh
set -eu

version="3.4.0"
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/JetBrainsMono.tar.xz"
font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerd"
archive="$(mktemp)"
extract_dir="$(mktemp -d)"
trap 'rm -f "$archive"; rm -rf "$extract_dir"' EXIT HUP INT TERM

curl -fL "$url" -o "$archive"
tar -xJf "$archive" -C "$extract_dir"
mkdir -p "$font_dir"
find "$extract_dir" -maxdepth 1 -type f \
    \( -name 'JetBrainsMonoNerdFont-Regular.ttf' \
    -o -name 'JetBrainsMonoNerdFont-Bold.ttf' \
    -o -name 'JetBrainsMonoNerdFont-Italic.ttf' \
    -o -name 'JetBrainsMonoNerdFont-BoldItalic.ttf' \
    -o -name 'JetBrainsMonoNerdFontMono-Regular.ttf' \
    -o -name 'JetBrainsMonoNerdFontMono-Bold.ttf' \
    -o -name 'JetBrainsMonoNerdFontMono-Italic.ttf' \
    -o -name 'JetBrainsMonoNerdFontMono-BoldItalic.ttf' \) \
    -exec install -m 0644 {} "$font_dir/" \;
fc-cache -f "$font_dir"
printf 'Installed JetBrainsMono Nerd Font %s in %s\n' "$version" "$font_dir"
