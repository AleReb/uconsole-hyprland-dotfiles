#!/bin/sh
set -eu

src_dir="${SWWW_SRC_DIR:-$HOME/src/swww}"
repo_url="${SWWW_REPO_URL:-https://github.com/LGFae/swww.git}"

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing command: %s\n' "$1" >&2
        exit 1
    }
}

need_cmd git
need_cmd rustup
need_cmd install

rustup toolchain install stable
rustup default stable

if [ -d "$src_dir/.git" ]; then
    git -C "$src_dir" pull --ff-only
else
    mkdir -p "$(dirname "$src_dir")"
    git clone "$repo_url" "$src_dir"
fi

cargo build --release --manifest-path "$src_dir/Cargo.toml"

mkdir -p "$HOME/.local/bin"
install -m 0755 "$src_dir/target/release/swww" "$HOME/.local/bin/swww"
install -m 0755 "$src_dir/target/release/swww-daemon" "$HOME/.local/bin/swww-daemon"

"$HOME/.local/bin/swww" --version
"$HOME/.local/bin/swww-daemon" --version
