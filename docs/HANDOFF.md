# Handoff

State when this package was prepared:

- System: Debian 13 trixie, aarch64, Raspberry Pi CM5/uConsole.
- Hyprland is installed from `trixie-backports`.
- Recommended graphical session: `Hyprland`, with the local `~/.local/bin/start-hyprland` wrapper when launching manually or through user PATH.
- Conserved fallback session: `rpd-labwc`.

## Relevant Packages

```text
hyprland
uwsm
waybar
wofi
foot
swaybg
keyd
cava
fastfetch
xdg-desktop-portal-hyprland
hypridle
hyprlock
hyprpolkitagent
wl-clipboard
playerctl
pavucontrol
network-manager-gnome
yad
bluez
wev
ffmpeg
liblz4-1
libxxhash0
pipewire
pipewire-pulse
wireplumber
```

Build-only packages for rebuilding `swww`:

```text
rustup
liblz4-dev
libwayland-dev
libxkbcommon-dev
pkg-config
build-essential
```

## Main Files

```text
~/.config/hypr/hyprland.conf
~/.config/waybar/config
~/.config/waybar/style.css
~/.config/gtk-3.0/gtk.css
~/.config/dunst/dunstrc
~/.config/uconsole/theme.env
~/.config/brightness_osd.sh
~/.config/volume_osd.sh
~/.local/bin/uconsole-wallpaper
~/.local/bin/uconsole-hypr-help
~/.local/bin/uconsole-waybar-restart
~/.local/bin/uconsole-cpu-load
~/.local/bin/uconsole-gpu-load
~/.local/bin/uconsole-theme
~/.local/bin/start-hyprland
~/.local/bin/Hyprland
~/.local/bin/swww
~/.local/bin/swww-daemon
/etc/keyd/default.conf
```

## Technical Decisions

- Active state observed on 2026-06-14: the live desktop may have a generated theme and selected wallpaper. Those values are user state created by `uconsole-theme` and `uconsole-wallpaper`; the repo keeps portable defaults.
- Graphical login: systemd should use `graphical.target`, LightDM should be enabled, and `/etc/lightdm/lightdm.conf` can use `autologin-user=uconsole`, `user-session=hyprland`, and `autologin-session=hyprland` for direct boot.
- Launch wrappers: `~/.local/bin/start-hyprland` should remain a thin wrapper around `/usr/bin/start-hyprland --path "$HOME/.local/bin/Hyprland"`. `~/.local/bin/Hyprland` is allowed to do startup-only DRM selection, write `~/.cache/hypr/uconsole-monitors.conf`, and then exec `/usr/bin/Hyprland`.
- HDMI/DRM: the stable lightweight profile selects either HDMI or DSI at Hyprland startup with `AQ_DRM_DEVICES`. Do not add HDMI hotplug polling, restart loops, live second-monitor toggles, `DRI_PRIME`, or `WLR_RENDER_DRM_DEVICE`; those paths caused high CPU or no HDMI image on this device.
- HDMI/DSI switching: `uconsole-display-autoswitch` listens for DRM udev events and calls `uconsole-display-switch` when HDMI connect state differs from the current wrapper mode. `Super + Shift + H` remains a manual fallback. This is not live dual-monitor mode; switching restarts Hyprland and closes unsaved Wayland client state.
- Wallpapers: static images use `swaybg`; GIF uses `swww`. Video wallpapers are intentionally unsupported on this device profile.
- `swww` was built locally from `~/src/swww` with stable Rust and installed as `~/.local/bin/swww` plus `~/.local/bin/swww-daemon`. The repo also includes those ARM64 binaries under `bin/`.
- GIF optimization: `scripts/optimize-wallpaper-gifs.sh` creates persistent `*.swww.png` posters and `*.swww.gif` optimized copies when they are smaller than the original. `uconsole-wallpaper` keeps state pointing at the original GIF, loads the poster first to avoid a black boot screen, and then loads the optimized GIF in the background. The picker hides generated sidecars.
- Avoid `hyprpaper` for this device state. Testing showed `hyprctl hyprpaper wallpaper` could hang and create high CPU load.
- uConsole display scale: DSI output uses scale `1.07`, cursor size 28, and slightly larger Waybar/Foot/Wofi sizing.
- Theme management: `uconsole-theme` updates Hyprland, Waybar, GTK tooltip/calendar styling, Wofi, Foot, Dunst, and OSD colors.
- Audio: volume keys use PipeWire through `wpctl`; volume-up allows software boost to 200% with `wpctl set-volume -l 2.0`. Audio above 100% can distort.
- Network: `nm-applet --indicator` is kept for clickable WiFi status and changes. Waybar does not show a separate network module.
- Bluetooth: `blueman-applet` is started by Hyprland and exposed through the Waybar tray next to `nm-applet`. Waybar does not show a separate Bluetooth text module.
- Waybar clock: center module shows date/time, hover shows the built-in calendar tooltip, and click opens a larger `yad` calendar. Tooltip rounding and `GtkCalendar` font size are controlled by `config/waybar/style.css` and `config/gtk-3.0/gtk.css`.
- CPU/GPU in Waybar:
  - `T` uses thermal zone 0.
  - `C` calculates CPU load from `/proc/stat`.
  - `G` calculates V3D load from `/sys/devices/platform/axi/1002000000.v3d/gpu_stats`.
- Super key: `keyd` remaps the `open` key to `leftmeta`.
- Wallpaper key: `keyd` maps the `unknown` key to wallpaper macros:
  - alone: `Super+Shift+W`
  - with Shift: `Super+Shift+.`
  - with Ctrl: `Super+Shift+,`
- Local keyboard note: the live system was tested with two extra `keyd` mappings that are not part of the portable base profile:
  - `leftmeta = playpause`
  - `pagedown = leftmeta`
  Keep them as a local preference unless this exact keyboard behavior is desired on a fresh install.
- Shortcut policy: keep only useful aliases in the base Hyprland config. `Super + T` remains as a terminal alias for the uConsole layout; other actions should stay on a single standard shortcut unless a hardware key needs a dedicated macro.
- Fastfetch: `.bashrc` uses `${XDG_RUNTIME_DIR}/uconsole-fastfetch-shown` to show compact system info only once per graphical login session.

## Recommended Follow-Up

- Reboot once and confirm LightDM autologin reaches Hyprland without manual intervention.
- Keep at least one static PNG wallpaper as a fallback for boot or low-battery situations.
- Commit the bundled binary update together with `docs/THIRD_PARTY.md` so the repo clearly documents what was built.
- If disk space matters, remove local build trees such as `~/src/swww` only after confirming the bundled `bin/swww` and `bin/swww-daemon` work from a fresh install.
- Consider adding screenshots to the repo after the final visual theme is selected.

## Reinstall

Full install:

```sh
cd ~/uconsole-hyprland-dotfiles
./install.sh
```

Copy only dotfiles, launch wrappers, and bundled local binaries:

```sh
./scripts/install.sh
```

Rebuild `swww`:

```sh
./scripts/build-swww.sh
```
