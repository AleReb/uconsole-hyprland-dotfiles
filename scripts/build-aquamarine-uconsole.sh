#!/bin/sh
# Build the isolated Aquamarine 0.11 library used by the uConsole dual-display launcher.

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=${UCONSOLE_AQUAMARINE_SOURCE:-"$HOME/.local/src/aquamarine-uconsole"}
build_dir=${UCONSOLE_AQUAMARINE_BUILD:-"$source_dir/build-uconsole"}
install_prefix=${UCONSOLE_AQUAMARINE_PREFIX:-"$HOME/.local/opt/aquamarine-0.11-uconsole"}
patch_file="$repo_root/patches/aquamarine-0.11-uconsole-render-node.patch"
upstream_url=https://github.com/hyprwm/aquamarine.git
base_commit=cd8321eba285e3cce50c50f19d5174a0b2567297

for command_name in git cmake ninja pkg-config; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Falta el comando requerido: %s\n' "$command_name" >&2
        exit 1
    }
done

[ -r "$patch_file" ] || {
    printf 'Falta el parche: %s\n' "$patch_file" >&2
    exit 1
}

if [ ! -d "$source_dir/.git" ]; then
    mkdir -p "${source_dir%/*}"
    git clone "$upstream_url" "$source_dir"
    git -C "$source_dir" checkout --detach "$base_commit"
else
    git -C "$source_dir" cat-file -e "$base_commit^{commit}" 2>/dev/null || {
        printf 'La fuente existente no contiene el commit base Aquamarine 0.11.0.\n' >&2
        exit 1
    }
fi

if git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    current_commit=$(git -C "$source_dir" rev-parse HEAD)
    git -C "$source_dir" merge-base --is-ancestor "$base_commit" "$current_commit" || {
        printf 'La fuente parcheada no desciende de Aquamarine 0.11.0: %s\n' "$current_commit" >&2
        exit 1
    }
    if [ "$current_commit" != "$base_commit" ]; then
        printf 'La fuente parcheada conserva una revision descendiente de 0.11.0: %s\n' "$current_commit"
    fi
    printf 'El parche uConsole ya esta aplicado.\n'
else
    if ! git -C "$source_dir" diff --quiet || ! git -C "$source_dir" diff --cached --quiet; then
        printf 'La fuente tiene otros cambios locales; no se aplicara el parche automaticamente.\n' >&2
        exit 1
    fi
    git -C "$source_dir" checkout --detach "$base_commit"
    git -C "$source_dir" apply --check "$patch_file"
    git -C "$source_dir" apply "$patch_file"
fi

build_jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')
cmake --no-warn-unused-cli \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_INSTALL_PREFIX:PATH="$install_prefix" \
    -S "$source_dir" -B "$build_dir" -G Ninja
cmake --build "$build_dir" --config Release --target all -j "$build_jobs"
cmake --install "$build_dir"

library="$install_prefix/lib/libaquamarine.so.10"
[ -r "$library" ] || {
    printf 'La compilacion termino, pero no se encontro %s\n' "$library" >&2
    exit 1
}

printf 'Aquamarine uConsole instalada en %s\n' "$library"
printf 'Comprueba el entorno con: uconsole-hyprland-mgpu check\n'
