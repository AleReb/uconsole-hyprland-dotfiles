# Handoff

Estado al crear este paquete:

- Sistema: Debian 13 trixie, aarch64, Raspberry Pi CM5/uConsole.
- Hyprland instalado desde `trixie-backports`.
- Sesion recomendada: `Hyprland (uwsm-managed)`.
- Fallback conservado: `rpd-labwc`.

## Paquetes relevantes

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
wev
mpv
libmpv2
ffmpeg
cpulimit
```

## Archivos principales

```text
~/.config/hypr/hyprland.conf
~/.config/waybar/config
~/.config/waybar/style.css
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
/etc/keyd/default.conf
```

## Decisiones tecnicas

- Wallpaper: imagenes estaticas usan `swaybg`; GIF/MP4/WEBM usan `mpvpaper`. Los GIF se cachean como MP4 a 12 FPS con `ffmpeg`. `mpvpaper` se ejecuta con `taskset` en un nucleo y `cpulimit` a 35% para evitar CPU alta. No usar `hyprpaper`, porque `hyprctl hyprpaper wallpaper` quedo colgado y genero carga de CPU alta.
- Escala uConsole actual: monitor DSI con scale `1.07`, cursor 28, Waybar/Foot/Wofi ligeramente agrandados.
- Temas: `~/.local/bin/uconsole-theme` cambia colores en Hyprland, Waybar, Wofi, Foot, Dunst y OSD.
- Red: se conserva `nm-applet --indicator` para tener icono WiFi en el tray de Waybar y cambiar redes desde ahi. El modulo `network` de Waybar queda como estado rapido.
- CPU/GPU en Waybar:
  - `T` usa thermal zone 0.
  - `C` calcula carga desde `/proc/stat`.
  - `G` calcula uso desde `/sys/devices/platform/axi/1002000000.v3d/gpu_stats`.
- Tecla Super:
  - La tecla `open` se remapea a `leftmeta` con `keyd`.
- Tecla wallpaper:
  - La tecla `unknown` dispara macros:
    - sola: `Super+Shift+W`
    - con Shift: `Super+Shift+.`
    - con Ctrl: `Super+Shift+,`
- Fastfetch: `.bashrc` usa `${XDG_RUNTIME_DIR}/uconsole-fastfetch-shown` para mostrarlo solo una vez por sesion grafica. Se ejecuta sin logo grande para que no se rompa al dividir la pantalla.

## Pendiente recomendado

- Elegir repositorio/fuente de wallpapers.
- Opcional: integrar `azote` como gestor grafico de wallpapers.
- Opcional: probar `matugen` o `wallust` para colores generados desde wallpaper.
- Opcional: reemplazar `uconsole-theme` por un sistema de plantillas mas robusto si se agregan muchos temas.

## Reinstalacion

Instalacion completa:

```sh
cd ~/uconsole-hyprland-dotfiles
./install.sh
```

Solo copiar configuraciones:

```sh
./scripts/install.sh
```

Reconstruir `mpvpaper` localmente:

```sh
./scripts/build-mpvpaper.sh
```
