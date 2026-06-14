# uConsole Hyprland Dotfiles

Portable Debian 13 / Raspberry Pi CM5 Hyprland setup for the ClockworkPi uConsole.

## Included

- Hyprland configuration tuned for the rotated uConsole display.
- Compact Waybar with workspaces, date/time, styled calendar tooltip, temperature, CPU, GPU, volume, network, battery, and tray.
- NetworkManager tray icon for WiFi changes.
- Wofi launcher, Foot terminal, Dunst notifications, CAVA audio visualizer, and local theme selector.
- `keyd` remaps:
  - `open = leftmeta`, used as `Super`.
  - `unknown` as a dedicated wallpaper key.
- Static wallpapers through `swaybg`.
- Animated GIF wallpapers through the bundled ARM64 `swww` binaries, with `mpvpaper` fallback for GIF/video.
- Persistent GIF optimization helpers for faster boot wallpaper loading.
- PipeWire volume keys with optional software boost up to 200%.
- Compact `fastfetch` once per graphical login session.

## Quick Install

On a clean uConsole running Debian 13:

```sh
git clone <repo-url>
cd ~/uconsole-hyprland-dotfiles
./install.sh
```

Then log out and choose the `Hyprland` session in LightDM. For direct boot, configure LightDM autologin to the `hyprland` session; that session runs `/usr/bin/start-hyprland`.

If packages are already installed and you only want to copy dotfiles:

```sh
./scripts/install.sh
```

## Main Shortcuts

- `Super + H`: local keybinding help.
- `Super + Enter`: terminal.
- `Super + T`: terminal alias.
- `Super + D`: application launcher.
- `Super + E`: file manager.
- `Super + B`: browser.
- `Super + C`: editor.
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
.gif .mp4 .webm
```

The wallpaper script is:

```text
~/.local/bin/uconsole-wallpaper
```

GIF files use `swww` automatically when available. Static images use `swaybg`. MP4/WEBM files and GIF fallback use `mpvpaper`.

The first `swww` load of a large GIF can be slow. To avoid a black screen at boot, the script loads a persistent poster image first and then loads the optimized GIF in the background.

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
UCONSOLE_WALLPAPER_OPTIMIZED_GIFS=0 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_FPS=10 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_LIMIT=25 uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_BACKEND=swww uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
UCONSOLE_WALLPAPER_BACKEND=mpvpaper uconsole-wallpaper set ~/Pictures/Wallpapers/file.gif
```

## Bundled Binaries

The repo includes ARM64 binaries for convenience:

```text
bin/mpvpaper
bin/mpvpaper-holder
bin/swww
bin/swww-daemon
```

Rebuild `mpvpaper` locally:

```sh
./scripts/build-mpvpaper.sh
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

## Notes

This is not a full HyDE install. It is a small Debian/uConsole-focused Hyprland setup inspired by HyDE styling, without Arch-only HyDE scripts.

Review large third-party dotfile installers before running them, because they can overwrite:

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/gtk-3.0`
- `~/.config/dunst`
- `~/.local/bin/uconsole-*`
- `/etc/keyd/default.conf`
