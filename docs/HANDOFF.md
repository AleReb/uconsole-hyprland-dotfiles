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

Build packages installed for the isolated Aquamarine display fix:

```text
build-essential
cmake
ninja-build
pkg-config
libegl-dev
libgl-dev
libgles-dev
libwayland-dev
wayland-protocols
libseat-dev
libinput-dev
libhyprutils-dev
libpixman-1-dev
libdrm-dev
libgbm-dev
libudev-dev
libdisplay-info-dev
hyprwayland-scanner
hwdata
```

## Main Files

```text
~/.config/hypr/hyprland.conf
~/.config/kanshi/config
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
~/.local/bin/uconsole-battery-status
~/.local/bin/uconsole-theme
~/.local/bin/uconsole-display-autoswitch
~/.local/bin/uconsole-display-debug
~/.local/bin/uconsole-display-switch
~/.local/bin/uconsole-hyprland-mgpu
~/.local/bin/start-hyprland
~/.local/bin/Hyprland
~/.local/bin/Hyprland-mgpu
~/.local/bin/swww
~/.local/bin/swww-daemon
~/.local/opt/aquamarine-0.11-uconsole/lib/libaquamarine.so.10
/usr/local/sbin/uconsole-cpu-boot-cap
/usr/local/sbin/uconsole-cpu-power
/etc/systemd/system/uconsole-cpu-boot-cap.service
/etc/systemd/system/uconsole-cpu-power.service
/etc/keyd/default.conf
```

## Technical Decisions

- Active state observed on 2026-06-14: the live desktop may have a generated theme and selected wallpaper. Those values are user state created by `uconsole-theme` and `uconsole-wallpaper`; the repo keeps portable defaults.
- Graphical login: the installer leaves the default boot target and display-manager state unchanged. On this uConsole, TTY1 autologins as `uconsole`; `~/.profile` runs `uconsole-tty-autostart`, which counts down for three seconds and starts `start-hyprland`. Any key cancels that attempt and leaves the normal terminal available, where `start-hyprland` can still be run manually.
- CPU startup policy: `uconsole-cpu-boot-cap.service` limits the CPU to 1.8 GHz before local filesystem checks. `uconsole-cpu-power.service` keeps that limit through Hyprland startup, then permits 2.4 GHz on battery or the configured 3 GHz ceiling on external power.
- Battery status: Waybar runs `uconsole-battery-status` every ten seconds. It reads the AXP power-supply sysfs data and reports state, capacity, voltage, battery power flow, and an estimated remaining/charging time.
- Launch wrappers: `~/.local/bin/start-hyprland` should remain a thin wrapper around `/usr/bin/start-hyprland --path "$HOME/.local/bin/Hyprland"`. `~/.local/bin/Hyprland` resolves both KMS cards, writes `~/.cache/hypr/uconsole-monitors.conf`, loads the isolated library through the ARM64 dynamic loader, and then execs `/usr/bin/Hyprland`.
- HDMI/DRM: the validated profile opens DSI and HDMI through their separate KMS cards and the sole V3D render node even when HDMI is unplugged at startup. This is required for true hotplug later in the same session. It loads the isolated patched Aquamarine library documented in `docs/DSI_HDMI_DUAL.md`; if the patch is missing it falls back to the old single-output paths. Do not add `DRI_PRIME` or `WLR_RENDER_DRM_DEVICE`.
- HDMI/DSI switching: in patched `dual` mode, `uconsole-display-autoswitch`
  watches connector transitions, refreshes Waybar after Kanshi changes the
  layout, and restores a reconnected HDMI wallpaper without blocking on the
  animated GIF. It must not call `hyprctl dispatch exit`.
  `uconsole-display-switch` retains session-restart behavior solely for the
  unpatched recovery path. `Super + Shift + H` remains a manual fallback.
- Monitor layout: `kanshi` starts with Hyprland and applies `~/.config/kanshi/config` after the wrapper's safe fallback rules. The validated dual profile places HDMI at `0x0` and rotated DSI at `1440x0`. Reload an edited Kanshi profile with `pkill -HUP -x kanshi`; do not move layout policy into the Aquamarine patch or the hotplug watcher.
- Wallpapers: static images use `swaybg`; GIFs are converted once to cached MP4 at 12 FPS, up to 1600 px wide and CRF 18, then played by `mpvpaper`, pinned to CPU 3 with `nice 15` and `cpulimit` at 35% of one core. MP4 and WebM are also supported directly.
- The repo includes ARM64 `mpvpaper` and `mpvpaper-holder` binaries under `bin/`; `scripts/build-mpvpaper.sh` rebuilds them when required.
- GIF loading: `uconsole-wallpaper` generates a persistent first-frame `*.swww.png` poster when absent, keeps it visible while converting/starting `mpvpaper`, then removes it after playback begins. `uconsole-wallpaper output NAME` restarts the player after a newly hotplugged output so the animation spans the active layout. The picker hides generated sidecars.
- Avoid `hyprpaper` for this device state. Testing showed `hyprctl hyprpaper wallpaper` could hang and create high CPU load.
- uConsole display scale: DSI output uses native scale `1.0`; rotation remains at 270 degrees (`transform,3`). Cursor size 28 and the slightly larger Waybar/Foot/Wofi sizing remain independent of monitor scaling.
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

- Reboot once, confirm TTY1 autologin, let the three-second countdown start Hyprland, then repeat and press a key to confirm cancellation leaves the terminal usable.
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

The full installer automatically builds and installs the isolated Aquamarine
fix before copying the launch wrappers. It enables `trixie-backports` from
`apt/trixie-backports.sources` only when no backports source is already
configured. `scripts/install.sh` remains the dotfiles-only path and does not
compile it.

Copy only dotfiles, launch wrappers, and bundled local binaries:

```sh
./scripts/install.sh
```

Rebuild `swww`:

```sh
./scripts/build-swww.sh
```

Rebuild the isolated Aquamarine dual-display fix:

```sh
./scripts/build-aquamarine-uconsole.sh
```

See `docs/DSI_HDMI_DUAL.md` before changing the display wrappers or patch.
