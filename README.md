# uConsole Hyprland Dotfiles

Configuracion portable para ClockworkPi uConsole con Debian 13/CM5 y Hyprland.

## Que incluye

- Hyprland adaptado a pantalla uConsole rotada.
- Waybar compacta con temperatura, CPU, GPU, volumen, red y bateria.
- Icono de NetworkManager en el tray de Waybar para cambiar WiFi.
- Wofi launcher.
- Foot terminal.
- Dunst tematizado para OSD de volumen/brillo.
- Wallpapers estaticos con `swaybg` y animados con `mpvpaper`.
- CAVA como visualizador de audio.
- Selector local de temas con `uconsole-theme`.
- Remapeo `keyd`:
  - `open = leftmeta` para usar esa tecla como Super.
  - `unknown` como tecla dedicada de wallpapers.
- `fastfetch` compacto una vez por sesion grafica, pensado para aguantar pantalla dividida.

## Atajos principales

- `Super + H`: ayuda local.
- `Super + Enter` o `Super + T`: terminal.
- `Super + A` o `Super + D`: launcher.
- `Super + Shift + W`: selector de wallpapers.
- `Super + Shift + T`: selector de temas.
- Tecla wallpaper: selector de wallpapers.
- `Shift + tecla wallpaper`: wallpaper siguiente.
- `Ctrl + tecla wallpaper`: wallpaper anterior.
- `Super + Alt + flechas`: ajustar tamano de ventana.
- `Super + Shift + B`: reiniciar Waybar.
- Icono WiFi en Waybar: cambiar o editar redes.

## Instalacion rapida

En una uConsole limpia con Debian 13:

```sh
git clone <repo-url>
cd ~/uconsole-hyprland-dotfiles
./install.sh
```

Despues cierra sesion y elige `Hyprland (uwsm-managed)` en LightDM si esta disponible.

Si ya instalaste paquetes y solo quieres copiar configuraciones:

```sh
./scripts/install.sh
```

Si necesitas reconstruir `mpvpaper` en vez de usar el binario incluido:

```sh
./scripts/build-mpvpaper.sh
```

## Wallpapers

Guarda imagenes en:

```text
~/.local/share/wallpapers
~/Pictures/Wallpapers
```

El script usado es:

```text
~/.local/bin/uconsole-wallpaper
```

Formatos animados soportados:

```text
.gif .mp4 .webm
```

Los animados se aplican con `mpvpaper` como capa de fondo real; no deben aparecer como una ventana normal. Los `.gif` se convierten automaticamente a una copia cacheada en MP4 a 12 FPS para evitar CPU alta.

Puedes ajustar los FPS antes de aplicar un animado:

```sh
UCONSOLE_WALLPAPER_FPS=10 uconsole-wallpaper set ~/Pictures/Wallpapers/archivo.gif
```

Por defecto los animados se limitan a un nucleo y 35% de CPU de ese nucleo:

```sh
UCONSOLE_WALLPAPER_LIMIT=25 uconsole-wallpaper set ~/Pictures/Wallpapers/archivo.gif
```

## Temas

Temas locales disponibles:

```sh
uconsole-theme list
uconsole-theme default
uconsole-theme rose
uconsole-theme green
uconsole-theme graphite
```

Desde Hyprland:

```text
Super + Shift + T
```

Esto cambia colores de Hyprland, Waybar, Wofi, Foot, Dunst y los OSD de brillo/volumen. Las terminales ya abiertas no cambian todos sus colores hasta abrir una nueva.

## Audio

Las teclas de volumen usan `wpctl` sobre PipeWire. El atajo de subir volumen permite boost por software hasta 200%:

```text
wpctl set-volume -l 2.0 @DEFAULT_AUDIO_SINK@ 5%+
```

Sobre 100% el audio puede distorsionar, especialmente en los parlantes pequenos de la uConsole. El rango alto queda disponible para fuentes con volumen original muy bajo.

## Notas

No es HyDE completo. Es un port pequeno inspirado en HyDE y adaptado a Debian/uConsole. Evita ejecutar instaladores grandes de dotfiles sin revisar, porque pueden pisar:

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/dunst`
- `~/.local/bin/uconsole-*`
- `/etc/keyd/default.conf`
