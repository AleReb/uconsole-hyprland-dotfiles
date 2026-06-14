#!/bin/sh
set -eu

sudo apt update
sudo apt install -y \
    git waybar wofi foot swaybg keyd cava fastfetch ffmpeg mpv libmpv2 cpulimit \
    yad liblz4-1 libxxhash0 \
    wl-clipboard playerctl pavucontrol network-manager-gnome wev

sudo apt install -y -t trixie-backports \
    hyprland uwsm xdg-desktop-portal-hyprland \
    hypridle hyprlock hyprpolkitagent hyprpaper hyprland-guiutils \
    pipewire pipewire-pulse wireplumber
