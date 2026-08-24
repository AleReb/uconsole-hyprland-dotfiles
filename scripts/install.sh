#!/bin/sh
set -eu

ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
BACKUP="$HOME/.config/cfg_backups/uconsole-dotfiles-$(date +%Y%m%d-%H%M%S)"

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing command: %s\n' "$1" >&2
        exit 1
    }
}

need_cmd install
need_cmd cp
need_cmd mkdir

mkdir -p "$BACKUP"

if [ -e "$HOME/.profile" ]; then
    cp -a "$HOME/.profile" "$BACKUP/profile"
fi

for dir in hypr waybar wofi foot dunst uconsole gtk-3.0 kanshi; do
    if [ -e "$HOME/.config/$dir" ]; then
        cp -a "$HOME/.config/$dir" "$BACKUP/"
    fi
done

for file in brightness_osd.sh volume_osd.sh; do
    if [ -e "$HOME/.config/$file" ]; then
        cp -a "$HOME/.config/$file" "$BACKUP/"
    fi
done

if [ -e "$HOME/.local/bin" ]; then
    mkdir -p "$BACKUP/local-bin"
    find "$HOME/.local/bin" -maxdepth 1 -type f -name 'uconsole-*' -exec cp -a {} "$BACKUP/local-bin/" \;
    for file in Hyprland start-hyprland startx-hyprland Hyprland.drm-wrapper.bak; do
        if [ -e "$HOME/.local/bin/$file" ]; then
            cp -a "$HOME/.local/bin/$file" "$BACKUP/local-bin/"
        fi
    done
fi

if [ -e /etc/keyd/default.conf ]; then
    printf 'Backing up /etc/keyd/default.conf requires sudo.\n'
    sudo cp -a /etc/keyd/default.conf "/etc/keyd/default.conf.backup.$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers"

cp -a "$ROOT/config/hypr" "$HOME/.config/"
cp -a "$ROOT/config/waybar" "$HOME/.config/"
cp -a "$ROOT/config/wofi" "$HOME/.config/"
cp -a "$ROOT/config/foot" "$HOME/.config/"
cp -a "$ROOT/config/dunst" "$HOME/.config/"
cp -a "$ROOT/config/uconsole" "$HOME/.config/"
cp -a "$ROOT/config/gtk-3.0" "$HOME/.config/"
cp -a "$ROOT/config/kanshi" "$HOME/.config/"
cp -a "$ROOT/config/applications"/. "$HOME/.local/share/applications/"
cp -a "$ROOT/config/brightness_osd.sh" "$HOME/.config/"
cp -a "$ROOT/config/volume_osd.sh" "$HOME/.config/"
chmod +x "$HOME/.config/brightness_osd.sh" "$HOME/.config/volume_osd.sh"
cp -a "$ROOT/bin"/uconsole-* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin"/uconsole-*
for file in Hyprland Hyprland-mgpu start-hyprland; do
    if [ -f "$ROOT/bin/$file" ]; then
        cp -a "$ROOT/bin/$file" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/$file"
    fi
done
for file in mpvpaper mpvpaper-holder swww swww-daemon; do
    if [ -f "$ROOT/bin/$file" ]; then
        cp -a "$ROOT/bin/$file" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/$file"
    fi
done
rm -f "$HOME/.local/bin/uconsole-hypr-hotplug" \
    "$HOME/.local/bin/Hyprland.drm-wrapper.bak" \
    "$HOME/.local/bin/startx-hyprland"

if [ -d "$ROOT/system" ]; then
    printf 'Installing CPU power policy requires sudo.\n'
    sudo install -m 0755 "$ROOT/system/uconsole-cpu-boot-cap" /usr/local/sbin/uconsole-cpu-boot-cap
    sudo install -m 0755 "$ROOT/system/uconsole-cpu-power" /usr/local/sbin/uconsole-cpu-power
    sudo install -m 0644 "$ROOT/system/uconsole-cpu-boot-cap.service" /etc/systemd/system/uconsole-cpu-boot-cap.service
    sudo install -m 0644 "$ROOT/system/uconsole-cpu-power.service" /etc/systemd/system/uconsole-cpu-power.service
    sudo systemctl daemon-reload
    sudo systemctl enable uconsole-cpu-boot-cap.service uconsole-cpu-power.service
fi

if [ -f "$ROOT/keyd/default.conf" ]; then
    sudo install -m 0644 "$ROOT/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd
    sudo systemctl restart keyd
fi

if ! grep -q 'uconsole-fastfetch-shown' "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# Show compact system info once per graphical login session.
if command -v fastfetch >/dev/null 2>&1 && [ -t 1 ]; then
    uconsole_fastfetch_stamp="${XDG_RUNTIME_DIR:-/tmp}/uconsole-fastfetch-shown"
    if [ ! -e "$uconsole_fastfetch_stamp" ]; then
        : > "$uconsole_fastfetch_stamp"
        fastfetch --logo none --key-width 8 --bar-width 8 --structure Title:OS:Kernel:Uptime:Packages:Shell:WM:Terminal:CPU:GPU:Memory:Disk:Battery
    fi
    unset uconsole_fastfetch_stamp
fi
EOF
fi

if ! grep -q 'uconsole-tty-autostart' "$HOME/.profile" 2>/dev/null; then
    cat >> "$HOME/.profile" <<'EOF'

# On local TTY1, start Hyprland after a cancellable three-second countdown.
if [ -x "$HOME/.local/bin/uconsole-tty-autostart" ]; then
    "$HOME/.local/bin/uconsole-tty-autostart"
fi
EOF
fi

printf 'Installed. Backup: %s\n' "$BACKUP"
printf 'TTY1 starts Hyprland after three seconds; press any key to stay in the terminal.\n'
