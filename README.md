# uConsole Hyprland Dotfiles

Portable Debian 13 / Raspberry Pi CM5 Hyprland setup for the ClockworkPi uConsole.

## Included

- Hyprland configuration tuned for the rotated uConsole display.
- Compact Waybar with workspaces, date/time, styled calendar tooltip, temperature, CPU, GPU, volume, battery, and tray.
- NetworkManager and Blueman tray icons for WiFi and Bluetooth status/changes.
- Wofi launcher, Foot terminal, Dunst notifications, CAVA audio visualizer, and local theme selector.
- `keyd` remaps:
  - `open = leftmeta`, used as `Super`.
  - `unknown` as a dedicated wallpaper key.
- Static wallpapers through `swaybg`.
- Animated GIF wallpapers through bundled ARM64 `mpvpaper`, with a capped decoder.
- Persistent GIF optimization helpers for faster boot wallpaper loading.
- Hyprland launch wrappers that keep DSI active and support HDMI hotplug without restarting the session.
- Early-boot and AC/battery CPU frequency policy for USB-backed startup stability.
- AXP battery status with voltage, power flow, and time estimate in Waybar.
- PipeWire volume keys with optional software boost up to 200%.
- Compact `fastfetch` once per graphical login session.

## Quick Install

On a clean uConsole running Debian 13:

```sh
git clone https://github.com/AleReb/uconsole-hyprland-dotfiles.git
cd ~/uconsole-hyprland-dotfiles
./install.sh
```

The installer does not enable a display manager or change the system's default
boot target. On TTY1 it shows a three-second countdown and starts the validated
graphical session automatically. Press any key during the countdown to stay in
the terminal. Manual startup remains available with:

```sh
start-hyprland
```

During early boot the CPU is capped at 1.8 GHz to reduce demand while USB-backed
filesystems are checked and mounted. After Hyprland has been stable for ten
seconds, the dynamic policy permits 2.4 GHz while discharging and the configured
3 GHz ceiling while external power is present.

The full installer enables Debian `trixie-backports` when needed, installs the
Aquamarine build dependencies, checks out the exact Aquamarine 0.11.0 revision,
applies the uConsole patch, and installs the result under
`~/.local/opt/aquamarine-0.11-uconsole/`. It does not replace the Debian
library. Running the installer again is safe: the existing patched source must
descend from that revision, the complete patch is recognized, and the library
is rebuilt incrementally.

The normal graphical launch uses two local wrappers:

```text
~/.local/bin/start-hyprland
~/.local/bin/Hyprland
```

`~/.local/bin/start-hyprland` delegates to `/usr/bin/start-hyprland` with `--path ~/.local/bin/Hyprland`. `~/.local/bin/Hyprland` resolves both KMS cards and writes `~/.cache/hypr/uconsole-monitors.conf`. When the isolated Aquamarine fix is available, it opens DSI and HDMI at startup even if the HDMI connector is currently unplugged. That makes later connect/disconnect events work without restarting Hyprland. Both cards share the single V3D render node. If the fix is unavailable, the wrapper keeps the previous single-output recovery paths instead of leaving both screens black. Keep this wrapper startup-only: do not add `DRI_PRIME` or `WLR_RENDER_DRM_DEVICE`; those paths caused high CPU on this uConsole profile.

HDMI connect/disconnect is checked by `uconsole-display-autoswitch`. On HDMI
disconnect it waits for the single-DSI profile, then reapplies the current
wallpaper. In the
patched `dual` mode it never closes Hyprland. After a topology change it
refreshes Waybar so its layer surfaces follow Kanshi's layout; on reconnection
it first restores a lightweight poster on HDMI and loads the animated GIF in
the background. Session restart remains only as a recovery fallback when the
patched multi-card backend is unavailable. `Super + Shift + H` reports or
applies that fallback manually.

Output mode, scale, rotation, and logical position are applied by `kanshi`
from `~/.config/kanshi/config`. The wrapper's monitor rules remain as a safe
startup fallback; once the session is ready, Kanshi applies the saved profile
and reapplies it when the connected output set changes. After editing the
profile while Kanshi is running, reload it with `pkill -HUP -x kanshi`.

For a read-only display report from either Hyprland or Xorg, run:

```sh
uconsole-display-debug LABEL
```

Reports are saved under `~/display-debug/`. The command records DRM/KMS,
Hyprland or XRandR state, display-related kernel messages, and wallpaper load;
it does not change outputs or configuration.

## DSI + HDMI Fix

The complete explanation, diagnosis, rebuild procedure, and recovery steps are
in [`docs/DSI_HDMI_DUAL.md`](docs/DSI_HDMI_DUAL.md). The exact Aquamarine patch
and its build script are also included in this repository.

The packaged Hyprland 0.55.2 uses Aquamarine 0.11.0. On the CM5 uConsole,
DSI and HDMI are separate KMS cards but there is only one V3D `renderD` node.
The local experimental launcher loads an isolated Aquamarine 0.11.0 build with
upstream commit `f44fecf` backported. The first physical CM5 test showed that
the generic fallback still left both KMS devices without an attached renderer.
The isolated build therefore also accepts `AQ_RENDER_NODE`, and the uConsole
launcher explicitly assigns its sole `/dev/dri/renderD128` node to both KMS
devices. It also keeps a userspace reference count for a shared `EGLDisplay`
when Mesa/V3D lacks `EGL_KHR_display_reference`; otherwise unplugging HDMI
terminates the display still used by DSI. These overrides exist only in the
isolated library.

The Debian library and `/usr/bin/Hyprland` are not replaced. The validated fix
is integrated into the normal `~/.local/bin/Hyprland` launcher whenever the
split-KMS topology is available. Check the isolated test path from any session
with:

```sh
uconsole-hyprland-mgpu check
```

For a recoverable physical test, connect HDMI, leave Hyprland for a TTY, and
run:

```sh
uconsole-hyprland-mgpu test
```

The test starts through the packaged `start-hyprland` watchdog, configures DSI
at `transform 3`, scale `1.0`, and HDMI to its right. It closes itself after 90
seconds, returning to the TTY even if both screens are black. The successful
physical test on 2026-07-21 showed both displays simultaneously. A later
connect/disconnect/connect cycle kept Hyprland and DSI alive, restored HDMI,
and reapplied the animated `swww` wallpaper only to that output. The test
command remains available as a recoverable diagnostic.

If packages are already installed and you only want to copy dotfiles:

```sh
./scripts/install.sh
```

That shorter command intentionally does not compile Aquamarine. To rebuild
only the isolated display fix, run:

```sh
./scripts/build-aquamarine-uconsole.sh
```

## Main Shortcuts

- `Super + H`: local keybinding help.
- `Super + Enter`: terminal.
- `Super + T`: terminal alias.
- `Super + D`: application launcher.
- `Super + E`: file manager.
- `Super + B`: browser.
- `Super + C`: editor.
- `Super + Shift + H`: report/apply the display fallback; patched hotplug does not restart Hyprland.
- `Super + Shift + W`: wallpaper picker.
- `Super + Shift + .`: next wallpaper.
- `Super + Shift + ,`: previous wallpaper.
- `Super + Shift + T`: theme picker.
- `Super + Shift + B`: restart Waybar.
- `Super + Alt + arrows`: resize active window.
- `Print`: region screenshot to clipboard.
- Wallpaper key: wallpaper picker.
- `Shift + wallpaper key`: next wallpaper.
- `Ctrl + wallpaper key`: previous wallpaper.

Most duplicate aliases were removed from the base config. `Super + T` remains as a terminal alias for the uConsole layout.

## Date And Calendar

Waybar shows date and time in the center:

```text
14 Jun  18:30
```

Hover the clock to see the monthly calendar tooltip. Click the clock to open a larger `yad` calendar window.

Tooltip styling and the larger `yad` calendar font are kept in:

```text
config/waybar/style.css
config/gtk-3.0/gtk.css
```

## Wallpapers

Store wallpapers in either directory:

```text
~/.local/share/wallpapers
~/Pictures/Wallpapers
```

Supported animated formats:

```text
.gif
```

The wallpaper script is:

```text
~/.local/bin/uconsole-wallpaper
```

`Super+Shift+W` opens a visual selector: each entry shows a 170×96 thumbnail
next to its filename. Thumbnails are cached under `~/.cache/uconsole/` and are
regenerated only when the wallpaper file changes. To create them in advance:

```sh
uconsole-wallpaper thumbnails
```

Prepare and validate every GIF in advance (poster, thumbnail, and playback
cache) with a report of failures:

```sh
uconsole-wallpaper-prepare
```

The report is saved at `~/.cache/uconsole/wallpaper-prepare-report.tsv`; source
GIFs are never modified.

For imported `usman-*` video wallpapers, create low-load 1280x720/12 FPS
versions in place and remove the known higher-FPS/resolution variants:

```sh
uconsole-wallpaper-optimize-videos --delete-redundant
```

GIF files are converted once to a high-quality cached MP4 (12 FPS, up to 1600 px
wide, CRF 18) and
played by `mpvpaper` pinned to CPU 3, nice 15, and capped at 35% of one core.
Static images use `swaybg`; MP4 and WebM are also supported directly.

The first conversion of a large GIF can be slow. The script automatically
creates a persistent first-frame poster when needed, keeps it visible with
`swaybg` while the MP4 is generated and the player starts, then removes it only
after the animated wallpaper is ready. This also applies after unlocking, so
there is no black background during restoration.

When locking, `uconsole-lock` extracts the current GIF's first frame to
`~/.cache/uconsole/lock-wallpaper.png`, stops the animated player while the
lock is visible, and restores the wallpaper on unlock. Press `Super+\`` to test the
same lock path used by the 10-minute idle timer.

Pre-optimize all GIF wallpapers:

```sh
./scripts/optimize-wallpaper-gifs.sh
```

This creates sidecar files next to each original GIF:

```text
name.swww.png
name.swww.gif
```

The picker still shows only the original GIF. The sidecar files are hidden from the picker and used automatically when they are newer than the original.

Useful environment overrides:

```sh
UCONSOLE_WALLPAPER_FPS=10 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_LIMIT=25 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_WIDTH=1920 UCONSOLE_WALLPAPER_CRF=16 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
```

## Bundled Binaries

The repo includes ARM64 binaries for convenience:

```text
bin/swww
bin/swww-daemon
bin/mpvpaper
bin/mpvpaper-holder
```

Rebuild `swww` locally:

```sh
sudo apt install -y rustup liblz4-dev libwayland-dev libxkbcommon-dev pkg-config build-essential
./scripts/build-swww.sh
```

Third-party notes are in `docs/THIRD_PARTY.md`.

## Themes

Available local themes:

```sh
uconsole-theme list
uconsole-theme default
uconsole-theme rose
uconsole-theme green
uconsole-theme graphite
```

From Hyprland:

```text
Super + Shift + T
```

The theme script updates Hyprland, Waybar, GTK tooltip/calendar styling, Wofi, Foot, Dunst, and the brightness/volume OSD files. Already-open terminals may need to be reopened to pick up all colors.

## Audio

Volume keys use PipeWire through `wpctl`. Volume up allows software boost up to 200%:

```text
wpctl set-volume -l 2.0 @DEFAULT_AUDIO_SINK@ 5%+
```

Audio above 100% can distort, especially on the built-in uConsole speakers. The extra range is mainly useful for quiet sources.

## Bluetooth

Bluetooth is handled by Blueman. Hyprland starts `blueman-applet`, and Waybar only shows the tray icon next to the WiFi tray icon. Use the Blueman icon to pair, trust, connect, disconnect, or remove devices.

## Notes

This is not a full HyDE install. It is a small Debian/uConsole-focused Hyprland setup inspired by HyDE styling, without Arch-only HyDE scripts.

Review large third-party dotfile installers before running them, because they can overwrite:

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/gtk-3.0`
- `~/.config/dunst`
- `~/.local/bin/uconsole-*`
- `/etc/keyd/default.conf`

## Disclaimer

This project is provided as-is, without warranty of any kind. It modifies
system configuration, installs software, and includes experimental display and
power-management behavior intended for the ClockworkPi uConsole. Review the
scripts and back up your current configuration before installation. You are
responsible for any data loss, hardware damage, system instability, or other
consequences resulting from its use. Test recovery procedures before relying on
this setup for important work.

## License

This project is licensed under the MIT License. See [`LICENSE`](LICENSE) for
the full license text. Third-party components and bundled binaries remain under
their respective licenses; see [`docs/THIRD_PARTY.md`](docs/THIRD_PARTY.md).
