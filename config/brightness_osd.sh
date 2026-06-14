#!/bin/bash

. "$HOME/.config/uconsole/theme.env" 2>/dev/null || true

CURRENT=$(brightnessctl g)
MAX=$(brightnessctl m)

PERCENT=$((100*$CURRENT/$MAX))
BG="#${UCONSOLE_BG:-1f2328}ee"
FG="#${UCONSOLE_FG:-f8fafc}"
HL="#${UCONSOLE_ACCENT1:-93cee9}"

dunstify \
  -h string:x-dunst-stack-tag:osd \
  -h string:bgcolor:"$BG" \
  -h string:fgcolor:"$FG" \
  -h string:hlcolor:"$HL" \
  -h int:value:"$PERCENT" \
  -t 1200 \
  "Brt" "$PERCENT%"
