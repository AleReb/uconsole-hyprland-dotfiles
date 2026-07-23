# DSI + HDMI simultáneos en la uConsole CM5

Validado físicamente el 21 de julio de 2026 con Debian 13 ARM64, Hyprland
0.55.2, Aquamarine 0.11.0 y Mesa/V3D.

## Resultado final

El lanzador normal `bin/Hyprland` inicia:

- ambas tarjetas KMS cuando la biblioteca corregida existe, aunque HDMI esté
  desconectado al iniciar;
- DSI + HDMI cuando el conector está presente, sin reiniciar Hyprland;
- solamente HDMI como recuperación si HDMI está conectado pero faltan los
  prerrequisitos del modo dual.

DSI siempre conserva escala `1.0` y `transform 3`. Las reglas generadas por el
wrapper dejan inicialmente HDMI en `1280x0` como recuperación segura. Después
del arranque, Kanshi aplica `~/.config/kanshi/config`; el perfil validado deja
HDMI en `0x0` y DSI en `1440x0`, de modo que HDMI queda a la izquierda.

No se reemplazan `/usr/bin/Hyprland` ni la biblioteca Aquamarine de Debian. La
variante corregida se instala aisladamente bajo
`~/.local/opt/aquamarine-0.11-uconsole/` y solamente se carga en el perfil
multitarjeta de esta uConsole.

## Topología que causó el fallo

En esta CM5 las funciones no pertenecen a la misma tarjeta DRM:

```text
/dev/dri/card0       KMS de DSI, normalmente DSI-2
/dev/dri/card1       dispositivo DRM V3D sin conectores KMS
/dev/dri/card2       KMS de HDMI, normalmente HDMI-A-1
/dev/dri/renderD128  único nodo de render V3D
```

Los números `cardN` no se fijan en los scripts: se resuelven desde los
conectores de `/sys/class/drm` en cada arranque.

## Causas comprobadas

El problema tuvo seis capas:

1. Aquamarine 0.11.0 intentaba asociar cada tarjeta KMS con un nodo de render
   mediante su padre en sysfs. La topología separada de la CM5 impedía asociar
   DSI y HDMI con el único `renderD128`.
2. Asignar el nodo solamente durante la sesión no bastaba: la selección de
   dispositivo EGL continuaba comparando contra el descriptor KMS. El parche
   hace que `AQ_RENDER_NODE` se use tanto al adjuntar el renderizador como al
   buscar el dispositivo EGL.
3. `LD_LIBRARY_PATH` no garantizó que `start-hyprland` cargara la biblioteca
   aislada. El wrapper ejecuta Hyprland mediante `/lib/ld-linux-aarch64.so.1`
   con un `--library-path` explícito.
4. Durante las primeras pruebas, el perfil tradicional reescribió
   `~/.cache/hypr/uconsole-monitors.conf` y añadió `DSI-2,disable`. El test usa
   su propia configuración bajo `$XDG_RUNTIME_DIR`, y el lanzador normal ahora
   genera directamente el perfil `dual`.
5. Al desconectar HDMI, Aquamarine destruía su renderer secundario y llamaba a
   `eglTerminate` sobre el mismo `EGLDisplay` usado por DSI. Mesa/V3D no anuncia
   `EGL_KHR_display_reference`, por lo que la DSI entraba en un bucle de
   `EGL_BAD_DISPLAY`/`EGL_NOT_INITIALIZED` y Hyprland terminaba. El parche lleva
   un contador de referencias solo cuando falta esa extensión y ejecuta
   `eglTerminate` únicamente al desaparecer el último usuario.
6. `swww` crea una salida reconectada con color negro. El autoswitch ahora
   invoca `uconsole-wallpaper output HDMI-A-1`, que carga primero el poster y
   luego el GIF optimizado solo en HDMI.

Además, el cursor por hardware provocaba reintentos continuos de buffers GBM
de 64x64 con formato inválido. Se usa `cursor:no_hardware_cursors = true`
solamente en el perfil dual.

## Archivos que forman la solución

```text
patches/aquamarine-0.11-uconsole-render-node.patch
scripts/build-aquamarine-uconsole.sh
bin/Hyprland
bin/Hyprland-mgpu
bin/uconsole-hyprland-mgpu
bin/uconsole-display-switch
bin/uconsole-display-autoswitch
bin/uconsole-display-debug
```

El parche se aplica sobre Aquamarine `v0.11.0`, commit exacto:

```text
cd8321eba285e3cce50c50f19d5174a0b2567297
```

Incluye el fallback oficial para sistemas con un solo `renderD`, el override
específico `AQ_RENDER_NODE` requerido por esta topología y el control manual de
vida del `EGLDisplay` compartido cuando el driver no lo proporciona.

## Reconstrucción desde cero

Instalar las dependencias de compilación en Debian 13:

```sh
sudo apt install build-essential cmake ninja-build pkg-config git \
  libegl-dev libgl-dev libgles-dev libwayland-dev wayland-protocols \
  libseat-dev libinput-dev libhyprutils-dev libpixman-1-dev \
  libdrm-dev libgbm-dev libudev-dev libdisplay-info-dev \
  hyprwayland-scanner hwdata
```

Desde el repositorio:

```sh
cd ~/uconsole-hyprland-dotfiles
./scripts/build-aquamarine-uconsole.sh
./scripts/install.sh
```

El instalador completo realiza ambos pasos y también instala las dependencias:

```sh
./install.sh
```

La compilación es incremental al repetirla. Una fuente nueva parte exactamente
de Aquamarine 0.11.0; una fuente ya parcheada debe descender de esa revisión y
contener el parche completo.

El script no instala nada en `/usr`. Si encuentra una fuente con cambios
locales desconocidos, se detiene en vez de borrarlos.

## Prueba recuperable

Conectar HDMI, cerrar la sesión gráfica, entrar en una TTY y ejecutar:

```sh
uconsole-hyprland-mgpu check
uconsole-hyprland-mgpu test
```

`test` termina automáticamente después de 90 segundos. Conserva en
`~/display-debug/` el log, el estado DRM, `hyprctl monitors all` y, cuando es
posible, capturas independientes de DSI y HDMI.

Un resultado correcto debe mostrar:

```text
DSI-2:     disabled: false, scale: 1.00, transform: 3
HDMI-A-1:  disabled: false, scale: 1.00, transform: 0
```

El log de Aquamarine debe contener:

```text
CDRMRenderer(drm): forcing EGL device match through /dev/dri/renderD128
Creating CDRMRenderer on gpu /dev/dri/renderD128
Modesetting DSI-2 with 720x1280@59.90Hz
Modesetting HDMI-A-1 with 1440x900@59.90Hz
```

El primer intento de crear GLES 3.2 puede devolver `EGL_BAD_MATCH`; en esta
máquina es esperable si a continuación reintenta GLES 3.0 y registra OpenGL ES
3.1 sobre V3D.

## Inicio normal y recuperación

Después de una prueba correcta, el inicio habitual no cambia:

```sh
~/.local/bin/start-hyprland
```

El estado elegido queda en:

```sh
cat "${XDG_RUNTIME_DIR}/uconsole-hyprland-wrapper.log"
```

Con la biblioteca y la topología disponibles debe indicar, con HDMI conectado
o desconectado:

```text
MONITOR_MODE=dual
PATCHED_AQUAMARINE=1
```

Si una actualización rompe la variante local, el lanzador vuelve
automáticamente a HDMI solamente. Para recuperar la pantalla interna, se puede
desconectar HDMI y volver a iniciar Hyprland. El comando experimental nunca
reemplaza la biblioteca del sistema.

## Hotplug validado

El 21 de julio de 2026 se ejecutó un ciclo completo con el autoswitch nuevo:

1. inicio con DSI y HDMI activos;
2. desconexión de HDMI: DSI e Hyprland permanecieron activos;
3. reconexión: HDMI volvió a `1440x900` sin reiniciar la sesión;
4. `swww` restauró `fallout2.swww.gif` únicamente en `HDMI-A-1`.

El log correcto de Aquamarine contiene la desconexión y destrucción del
renderer secundario, pero no vuelve a mostrar `EGL_BAD_DISPLAY` ni
`EGL_NOT_INITIALIZED`. El log del autoswitch debe mostrar una secuencia como:

```text
hotplug old=connected:HDMI-A-1 new=disconnected
hotplug old=disconnected new=connected:HDMI-A-1
wallpaper-restored output=HDMI-A-1
```

`uconsole-display-autoswitch` no debe cerrar Hyprland en este perfil. El
reinicio de la sesión queda reservado al fallback cuando falta la biblioteca
corregida. Kanshi configura modo, escala, rotación y posición; después de cada
cambio de topología, el autoswitch recarga Waybar con `SIGUSR2` para que sus
capas sigan la nueva geometría. El reinicio completo queda en
`Super+Shift+B`. Al reconectar HDMI carga primero el poster y espera diez
segundos antes de cargar el GIF pesado en segundo plano, evitando bloquear el
repintado de DSI.

### Revalidación con Kanshi y Waybar

El 23 de julio de 2026 se repitió físicamente el ciclo después de añadir
Kanshi. DSI permaneció visible y Waybar reapareció sin usar
`Super+Shift+B`. El registro confirmó:

```text
hotplug old=connected:HDMI-A-1 new=disconnected
waybar-reloaded
hotplug old=disconnected new=connected:HDMI-A-1
wallpaper-restored output=HDMI-A-1
waybar-reloaded
```

Si HDMI vuelve a desconectarse antes de los diez segundos de espera, el
cargador diferido del GIF detecta que la salida desapareció y termina sin
tratarlo como un fallo.

## Evidencia de la validación

El usuario confirmó físicamente ambas pantallas simultáneas y el ciclo de
hotplug completo. Las capturas temporales se eliminaron después de trasladar
el resultado, la causa y la reproducción a este documento. El lanzador normal
registró `MONITOR_MODE=dual`, ambos modesets, ausencia de los reintentos GBM de
cursor de 64x64 y ausencia del bucle EGL después de desconectar HDMI.
