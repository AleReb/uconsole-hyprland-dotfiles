#!/bin/sh
set -eu

fps="${UCONSOLE_WALLPAPER_GIF_FPS:-12}"
max_width="${UCONSOLE_WALLPAPER_GIF_WIDTH:-800}"
colors="${UCONSOLE_WALLPAPER_GIF_COLORS:-64}"
wall_dirs="${UCONSOLE_WALLPAPER_DIRS:-$HOME/.local/share/wallpapers $HOME/Pictures/Wallpapers}"

command -v ffmpeg >/dev/null 2>&1 || {
    printf 'Missing command: ffmpeg\n' >&2
    exit 1
}

optimize_gif() {
    src="$1"
    if [ ! -f "$src" ] && [ -f "/$src" ]; then
        src="/$src"
    fi
    [ -f "$src" ] || {
        printf 'MISS %s\n' "$src" >&2
        return 0
    }
    case "$src" in
        *.swww.gif|*.SWWW.gif) return 0 ;;
    esac

    dir="$(dirname "$src")"
    base="$(basename "$src" .gif)"
    case "$base" in
        *.GIF) base="$(basename "$src" .GIF)" ;;
    esac
    dst="$dir/$base.swww.gif"
    poster="$dir/$base.swww.png"
    tmp="$dst.tmp.$$.gif"
    poster_tmp="$poster.tmp.$$.png"

    if [ -f "$dst" ] && [ "$dst" -nt "$src" ] && [ -f "$poster" ] && [ "$poster" -nt "$src" ]; then
        printf 'OK %s\n' "$dst"
        return 0
    fi

    printf 'OPT %s -> %s\n' "$src" "$dst"
    if ! ffmpeg -y -i "$src" -frames:v 1 -update 1 -vf "scale='min(${max_width},iw)':-2:flags=lanczos" "$poster_tmp" >/dev/null 2>&1; then
        rm -f "$poster_tmp" "$tmp"
        printf 'FAIL poster %s\n' "$src" >&2
        return 0
    fi
    mv "$poster_tmp" "$poster"

    filter="fps=${fps},scale='min(${max_width},iw)':-2:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=${colors}[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5"
    if ! ffmpeg -y -i "$src" -filter_complex "$filter" -loop 0 "$tmp" >/dev/null 2>&1; then
        rm -f "$tmp"
        printf 'FAIL gif %s\n' "$src" >&2
        return 0
    fi
    src_size="$(wc -c < "$src")"
    tmp_size="$(wc -c < "$tmp")"
    if [ "$tmp_size" -lt "$src_size" ]; then
        mv "$tmp" "$dst"
    else
        rm -f "$tmp" "$dst"
        printf 'SKIP %s optimized GIF is not smaller\n' "$src"
    fi
}

for dir in $wall_dirs; do
    [ -d "$dir" ] || continue
    find "$dir" -maxdepth 1 -type f \( -iname '*.gif' ! -iname '*.swww.gif' \) -print | while IFS= read -r gif; do
        optimize_gif "$gif"
    done
done
