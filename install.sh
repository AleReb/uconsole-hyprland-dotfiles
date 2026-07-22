#!/bin/sh
set -eu

ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

printf 'uConsole Hyprland installer\n'
printf '%s\n' 'This will install Debian packages, build the isolated Aquamarine fix, copy dotfiles, and enable keyd.'
printf 'You may be asked for sudo.\n\n'

"$ROOT/scripts/packages-debian.sh"
"$ROOT/scripts/build-aquamarine-uconsole.sh"
"$ROOT/scripts/install.sh"

printf '\nDone. Log out and choose the Hyprland session from LightDM.\n'
