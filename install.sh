#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

printf 'uConsole Hyprland installer\n'
printf 'This will install Debian packages, copy dotfiles, and enable keyd.\n'
printf 'You may be asked for sudo.\n\n'

"$ROOT/scripts/packages-debian.sh"
"$ROOT/scripts/install.sh"

printf '\nDone. Log out and choose Hyprland (uwsm-managed) from LightDM.\n'
